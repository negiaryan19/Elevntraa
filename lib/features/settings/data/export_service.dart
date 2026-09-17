import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/failure.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../domain/models/doctor_profile.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';
import '../../../l10n/app_localizations.dart';
import '../../prescription/data/prescription_pdf_service.dart';
import 'doctor_profile_repository.dart';
import 'zip_builder.dart';

/// Settings > Export Data (roadmap item 25).
///
/// Builds one zip the doctor can keep or hand to anyone who asks for their
/// records: machine-readable JSON, spreadsheet-friendly CSV, the attached
/// report images, and a PDF of every signed prescription.
class ExportService {
  ExportService(this._ref, {Future<Directory> Function()? tempDir})
    : _tempDirOverride = tempDir;

  final Ref _ref;
  final Future<Directory> Function()? _tempDirOverride;

  Future<Directory> _tempDir() =>
      _tempDirOverride?.call() ?? getTemporaryDirectory();

  /// Collects everything and returns the zip file on disk.
  /// Throws [StorageFailure] when there is nothing to export or the file
  /// cannot be written.
  Future<File> buildExportZip() async {
    final patients = await _ref
        .read(patientRepositoryProvider)
        .recent(limit: 100000);
    final visits = await _ref
        .read(visitRepositoryProvider)
        .recent(limit: 100000);

    if (patients.isEmpty && visits.isEmpty) {
      throw const StorageFailure('Nothing to export.');
    }

    final byId = {for (final patient in patients) patient.id: patient};
    final inputs = <ZipInput>[
      ZipInput.text(
        'patients.json',
        const JsonEncoder.withIndent(
          '  ',
        ).convert([for (final patient in patients) patient.toJson()]),
      ),
      ZipInput.text(
        'visits.json',
        const JsonEncoder.withIndent(
          '  ',
        ).convert([for (final visit in visits) visit.toJson()]),
      ),
      ZipInput.text('patients.csv', patientsCsv(patients)),
      ZipInput.text('visits.csv', visitsCsv(visits, byId)),
    ];

    // This doctor's report photos, if any are still on the device.
    final attachmentsDir = _ref.read(attachmentsDirProvider);
    final attachments = attachmentsDir == null
        ? null
        : Directory(attachmentsDir);
    if (attachments != null && attachments.existsSync()) {
      for (final entity in attachments.listSync()) {
        if (entity is! File) continue;
        inputs.add(
          ZipInput.file('attachments/${p.basename(entity.path)}', entity),
        );
      }
    }

    // A PDF per signed prescription, built exactly as the app prints them.
    final doctor = _ref.read(doctorProfileValueProvider);
    final signature = await _ref
        .read(doctorProfileProvider.notifier)
        .signatureBytes();
    final pdfService = _ref.read(prescriptionPdfServiceProvider);
    final failures = <String>[];

    for (final visit in visits.where((v) => v.signed)) {
      try {
        final bytes = await pdfService.build(
          visit: visit,
          patient: byId[visit.patientId],
          doctor: doctor,
          signaturePng: signature,
        );
        inputs.add(
          ZipInput.bytes(
            'prescriptions/${pdfService.fileName(byId[visit.patientId], visit)}',
            bytes,
          ),
        );
      } catch (e) {
        // One unbuildable prescription must not lose the doctor the rest of
        // the export; it is listed in the manifest instead.
        debugPrint('[export] PDF failed for visit ${visit.id}: $e');
        failures.add('${visit.id}: $e');
      }
    }

    inputs.add(
      ZipInput.text(
        'README.txt',
        _readme(
          patients: patients.length,
          visits: visits.length,
          signed: visits.where((v) => v.signed).length,
          doctor: doctor,
          failures: failures,
        ),
      ),
    );

    try {
      final dir = await _tempDir();
      final target = File(
        p.join(dir.path, 'rxvarta-export-${_timestamp(DateTime.now())}.zip'),
      );
      return await writeZip(target, inputs);
    } on FileSystemException catch (e) {
      throw StorageFailure('Could not write the export file.', cause: e);
    }
  }

  /// Builds the zip behind a progress dialog and hands it to the OS share
  /// sheet (WhatsApp, Drive, Files, mail — whatever the doctor has).
  Future<void> exportAndShare(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    // Closed by identity, not with pop(): pop() removes whatever route is on
    // top, which is the screen the doctor is on if the dialog is gone.
    final progress = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (_) => PopScope(
        // The export cannot be cancelled; back must not hide it.
        canPop: false,
        child: _ProgressDialog(message: t.exportPreparing),
      ),
    );
    navigator.push(progress);
    void closeProgress() {
      if (progress.isActive) navigator.removeRoute(progress);
    }

    File file;
    try {
      file = await buildExportZip();
    } catch (e) {
      closeProgress();
      final isEmpty = e is StorageFailure && e.message == 'Nothing to export.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEmpty
                ? t.exportEmpty
                : t.exportFailed(e is Failure ? e.message : '$e'),
          ),
        ),
      );
      return;
    }

    closeProgress();

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          subject: t.exportShareSubject,
          text: t.exportShareText,
        ),
      );
      if (result.status == ShareResultStatus.unavailable) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.exportSavedTo(file.path))),
        );
      }
    } catch (e) {
      // Sharing is unavailable (some desktop setups): the file is still on
      // disk, so tell the doctor where it is instead of losing the work.
      debugPrint('[export] share failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(t.exportSavedTo(file.path))),
      );
    }
  }

  String _readme({
    required int patients,
    required int visits,
    required int signed,
    required DoctorProfile doctor,
    required List<String> failures,
  }) {
    final buffer = StringBuffer()
      ..writeln('Rxvarta data export')
      ..writeln('Created: ${DateTime.now().toIso8601String()}')
      ..writeln('Doctor: ${doctor.name}')
      ..writeln('Registration number: ${doctor.regNo}')
      ..writeln('')
      ..writeln('patients.json / patients.csv  — $patients patients')
      ..writeln('visits.json / visits.csv      — $visits consultations')
      ..writeln('prescriptions/                — $signed signed prescriptions')
      ..writeln('attachments/                  — scanned report images');
    if (failures.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('These prescriptions could not be rendered as PDF:');
      for (final failure in failures) {
        buffer.writeln('  - $failure');
      }
    }
    return buffer.toString();
  }
}

/// CSV of the patient list.
String patientsCsv(List<PatientProfile> patients) {
  final rows = <List<String>>[
    ['id', 'name', 'age', 'sex', 'phone', 'whatsapp', 'createdAt'],
    for (final patient in patients)
      [
        patient.id,
        patient.name,
        patient.age?.toString() ?? '',
        patient.sex?.name ?? '',
        patient.phone ?? '',
        patient.whatsappNumber ?? '',
        patient.createdAt.toIso8601String(),
      ],
  ];
  return toCsv(rows);
}

/// CSV of the consultation list, one row per visit.
String visitsCsv(
  List<VisitRecord> visits,
  Map<String, PatientProfile> patientsById,
) {
  final rows = <List<String>>[
    ['id', 'patientName', 'date', 'diagnosis', 'medicines', 'signed'],
    for (final visit in visits)
      [
        visit.id,
        patientsById[visit.patientId]?.name ?? '',
        visit.createdAt.toIso8601String(),
        visit.insight?.diagnosis ?? '',
        _medicines(visit.insight),
        visit.signed ? 'yes' : 'no',
      ],
  ];
  return toCsv(rows);
}

String _medicines(MedicalInsight? insight) {
  if (insight == null) return '';
  return insight.medications
      .map(
        (m) => [
          m.name,
          m.dosage,
          m.frequency,
          m.duration,
          m.timing,
        ].where((s) => s.trim().isNotEmpty).join(' '),
      )
      .where((s) => s.isNotEmpty)
      .join('; ');
}

/// Byte order mark. Without it Excel reads the file as the system code page
/// and Hindi, Tamil or any other non-Latin name turns into garbage.
const _utf8Bom = '\uFEFF';

/// RFC 4180 CSV: quote a field when it holds a comma, quote, newline or
/// leading/trailing space, and double any embedded quote. Excel and Google
/// Sheets both read the result correctly.
String toCsv(List<List<String>> rows) {
  final buffer = StringBuffer(_utf8Bom);
  for (final row in rows) {
    buffer.writeln(row.map(csvField).join(','));
  }
  return buffer.toString();
}

/// Characters that make a spreadsheet evaluate a cell as a formula.
final _formulaStart = RegExp(r'^[=+\-@\t\r]');

String csvField(String value) {
  // Names, diagnoses and advice are dictated free text. A value such as
  // "=HYPERLINK(...)" or "+91..." must stay text when the doctor opens the
  // export in Excel, so it is prefixed with an apostrophe (OWASP guidance).
  final text = _formulaStart.hasMatch(value) ? "'$value" : value;
  final needsQuotes =
      text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r') ||
      text != text.trim();
  final escaped = text.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

String _timestamp(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}${two(d.second)}';
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

final exportServiceProvider = Provider<ExportService>(ExportService.new);
