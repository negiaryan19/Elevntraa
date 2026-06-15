import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/app_paths.dart';
import '../../../domain/models/doctor_profile.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';

/// Builds a clean, single-sheet A4 prescription PDF in the standard Indian
/// out-patient format. The layout is fixed-position (letterhead → patient →
/// summary → Rx medicines → advice/follow-up → signature → footer) and uses a
/// real flowing table so long medicine names wrap inside their cell instead of
/// being clipped mid-line.
class PrescriptionPdfService {
  // Brand palette (matches the in-app screens).
  static final _blue = PdfColor.fromInt(0xFF2563EB);
  static final _teal = PdfColor.fromInt(0xFF14B8A6);
  static final _ink = PdfColor.fromInt(0xFF111827);
  static final _muted = PdfColor.fromInt(0xFF6B7280);
  static final _line = PdfColor.fromInt(0xFFD1D5DB);
  static final _softBg = PdfColor.fromInt(0xFFF9FAFB);

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Future<Uint8List> build({
    required VisitRecord visit,
    required PatientProfile? patient,
    DoctorProfile doctor = DoctorProfile.defaultProfile,
  }) async {
    final theme = await _loadTheme();
    final insight = visit.insight ?? MedicalInsight.empty;

    final doc = pw.Document(
      title: 'Prescription — ${patient?.name ?? 'Patient'}',
      author: doctor.name,
      creator: 'MediScribe',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 26),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _letterhead(doctor),
            pw.SizedBox(height: 14),
            _patientBar(visit, patient),
            pw.SizedBox(height: 16),
            _summarySection(insight),
            pw.SizedBox(height: 14),
            _medicinesSection(insight.medications),
            pw.SizedBox(height: 14),
            _adviceAndFollowUp(visit, insight),
            pw.Spacer(),
            _signature(doctor),
            pw.SizedBox(height: 10),
            _footer(),
          ],
        ),
      ),
    );

    // Previous-report pages: the prescription stays a single sheet; each
    // attached report image becomes its own following page under a
    // "Previous Reports" heading.
    await _addAttachmentPages(doc, theme, visit, patient);

    return doc.save();
  }

  Future<void> _addAttachmentPages(
    pw.Document doc,
    pw.ThemeData theme,
    VisitRecord visit,
    PatientProfile? patient,
  ) async {
    final attachments = visit.attachments;
    if (attachments.isEmpty) return;

    for (var i = 0; i < attachments.length; i++) {
      final att = attachments[i];
      Uint8List? bytes;
      try {
        final file = File(AppPaths.resolveAttachment(att.path));
        if (file.existsSync()) bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }
      if (bytes == null) continue; // skip missing/unreadable files

      final image = pw.MemoryImage(bytes);
      final caption = att.caption.trim().isEmpty
          ? 'Report ${i + 1}'
          : att.caption.trim();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 26),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // The big section banner appears only on the first report page.
              if (i == 0) ...[
                pw.Text(
                  'PREVIOUS REPORTS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _blue,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.Text(
                  'Attached for ${patient?.name ?? 'patient'}',
                  style: pw.TextStyle(fontSize: 9, color: _muted),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(color: _line, thickness: 0.5),
                pw.SizedBox(height: 8),
              ],
              _subLabel('${i + 1}. $caption'),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// A safe download/share filename for this visit's prescription.
  String fileName(PatientProfile? patient, VisitRecord visit) {
    final who = (patient?.name ?? 'patient')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final d = visit.createdAt;
    final stamp =
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    return 'Prescription_${who.isEmpty ? 'patient' : who}_$stamp.pdf';
  }

  /// Opens the native print / PDF-preview dialog for this prescription.
  Future<void> printOrPreview({
    required VisitRecord visit,
    required PatientProfile? patient,
    DoctorProfile doctor = DoctorProfile.defaultProfile,
  }) async {
    final bytes = await build(visit: visit, patient: patient, doctor: doctor);
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: fileName(patient, visit),
    );
  }

  /// Opens the OS share sheet with the real PDF file attached, so the doctor
  /// can send it to the patient over WhatsApp, email, etc. — a proper document,
  /// not a plain-text message.
  Future<void> shareAsFile({
    required VisitRecord visit,
    required PatientProfile? patient,
    DoctorProfile doctor = DoctorProfile.defaultProfile,
  }) async {
    final bytes = await build(visit: visit, patient: patient, doctor: doctor);
    await Printing.sharePdf(bytes: bytes, filename: fileName(patient, visit));
  }

  // ── Theme / fonts ─────────────────────────────────────────────────────────

  /// Uses Noto Sans (broad Latin + symbol coverage) with a Devanagari fallback
  /// so code-mixed Hindi/English text renders without tofu boxes. Falls back to
  /// the bundled Helvetica if the fonts can't be fetched (e.g. offline) so the
  /// PDF still generates instead of throwing.
  Future<pw.ThemeData> _loadTheme() async {
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final italic = await PdfGoogleFonts.notoSansItalic();
      final deva = await PdfGoogleFonts.notoSansDevanagariRegular();
      final devaBold = await PdfGoogleFonts.notoSansDevanagariBold();
      return pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: italic,
        fontFallback: [deva, devaBold],
      );
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  pw.Widget _letterhead(DoctorProfile d) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(colors: [_blue, _teal]),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  d.clinicName,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  d.clinicAddress,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
                ),
                pw.Text(
                  'Tel: ${d.clinicPhone}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                d.name,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                d.qualifications,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Reg. No: ${d.regNo}',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _patientBar(VisitRecord visit, PatientProfile? p) {
    final dateStr = _formatDate(visit.createdAt);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _softBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: _kv('Patient', p?.name ?? '—', big: true),
          ),
          pw.Expanded(flex: 2, child: _kv('Age', _ageLabel(p))),
          pw.Expanded(flex: 2, child: _kv('Sex', _sexLabel(p?.sex))),
          pw.Expanded(flex: 4, child: _kv('Contact', _contactLabel(p))),
          pw.Expanded(flex: 3, child: _kv('Date', dateStr)),
        ],
      ),
    );
  }

  pw.Widget _summarySection(MedicalInsight insight) {
    final hasDiagnosis = insight.diagnosis.trim().isNotEmpty;
    final hasSymptoms = insight.symptoms.isNotEmpty;
    final hasTests = insight.tests.isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Summary'),
        pw.SizedBox(height: 6),
        if (hasSymptoms) _labelledLine('Symptoms', insight.symptoms.join(', ')),
        if (hasDiagnosis) _labelledLine('Diagnosis', insight.diagnosis),
        if (hasTests)
          _labelledLine('Investigations advised', insight.tests.join(', ')),
        if (!hasSymptoms && !hasDiagnosis && !hasTests)
          pw.Text(
            'No clinical summary recorded.',
            style: pw.TextStyle(fontSize: 10, color: _muted),
          ),
      ],
    );
  }

  pw.Widget _medicinesSection(List<Medication> meds) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Rx',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: _blue,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'Medicines Prescribed',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        if (meds.isEmpty)
          pw.Text(
            'No medicines prescribed.',
            style: pw.TextStyle(fontSize: 10, color: _muted),
          )
        else
          _medicinesTable(meds),
      ],
    );
  }

  pw.Widget _medicinesTable(List<Medication> meds) {
    final headerStyle = pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(fontSize: 9.5, color: _ink);

    pw.Widget cell(String text, pw.TextStyle style) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: pw.Text(text.isEmpty ? '—' : text, style: style),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(24),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(2.6),
        4: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _blue),
          children: [
            cell('#', headerStyle),
            cell('Medicine', headerStyle),
            cell('Dosage', headerStyle),
            cell('Frequency', headerStyle),
            cell('Duration', headerStyle),
          ],
        ),
        for (var i = 0; i < meds.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : _softBg,
            ),
            children: [
              cell('${i + 1}', cellStyle),
              cell(
                meds[i].name,
                cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
              ),
              cell(meds[i].dosage, cellStyle),
              cell(meds[i].frequency, cellStyle),
              cell(meds[i].duration, cellStyle),
            ],
          ),
      ],
    );
  }

  pw.Widget _adviceAndFollowUp(VisitRecord visit, MedicalInsight insight) {
    final notes = insight.doctorNotes.trim();
    final advice = insight.advice.where((s) => s.trim().isNotEmpty).toList();
    final instructions = insight.instructions
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final followUp = _followUpLabel(visit.createdAt, insight.followUpDays);

    // When the doctor gave no explicit advice/instructions, fall back to safe
    // generic guidance so the prescription is never empty in this section.
    final hasContent = advice.isNotEmpty || instructions.isNotEmpty;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFFBEB),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFFDE68A)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Advice & Instructions'),
          pw.SizedBox(height: 6),
          if (advice.isNotEmpty) ...[
            _subLabel('Advice'),
            ...advice.map(_bullet),
            pw.SizedBox(height: 4),
          ],
          if (instructions.isNotEmpty) ...[
            _subLabel('Instructions'),
            ...instructions.map(_bullet),
            pw.SizedBox(height: 4),
          ],
          if (!hasContent) ...[
            _bullet('Take medicines as prescribed, after meals.'),
            _bullet('Drink plenty of fluids and take adequate rest.'),
            pw.SizedBox(height: 4),
          ],
          if (notes.isNotEmpty) ...[
            pw.Text(notes, style: pw.TextStyle(fontSize: 9.5, color: _ink)),
            pw.SizedBox(height: 4),
          ],
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              pw.Text(
                'Follow-up: ',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _blue,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  followUp,
                  style: pw.TextStyle(fontSize: 10, color: _ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _subLabel(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9.5,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
  );

  pw.Widget _signature(DoctorProfile d) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(child: pw.SizedBox()),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              _signatureName(d.name),
              style: pw.TextStyle(
                fontSize: 18,
                fontStyle: pw.FontStyle.italic,
                fontWeight: pw.FontWeight.bold,
                color: _blue,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Container(width: 150, height: 0.8, color: _line),
            pw.SizedBox(height: 4),
            pw.Text(
              d.name,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.Text(
              d.qualifications,
              style: pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
            pw.Text(
              'Reg. No: ${d.regNo}',
              style: pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Digitally signed',
              style: pw.TextStyle(
                fontSize: 8,
                color: _teal,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.Divider(color: _line, thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Text(
          'This is a computer-generated prescription and does not require a '
          'physical signature.',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
        pw.Text(
          'Generated by MediScribe  •  Secure & Private',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
      ],
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  pw.Widget _sectionTitle(String text) => pw.Text(
    text.toUpperCase(),
    style: pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: _blue,
      letterSpacing: 0.6,
    ),
  );

  pw.Widget _kv(String label, String value, {bool big = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: _muted)),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: big ? 11 : 9.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );
  }

  pw.Widget _labelledLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontSize: 9.5, color: _ink),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _bullet(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Text('•  $text', style: pw.TextStyle(fontSize: 9, color: _ink)),
  );

  /// A cursive-style short signature, e.g. "Dr. Rajesh Sharma" → "Dr. R. Sharma".
  /// Defensive against single-word or empty names so it never throws.
  String _signatureName(String fullName) {
    final cleaned = fullName.replaceFirst(RegExp(r'^Dr\.?\s*'), '').trim();
    if (cleaned.isEmpty) return fullName;
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return 'Dr. ${parts.first}';
    final initial = parts.first.isNotEmpty ? parts.first[0] : '';
    return 'Dr. $initial. ${parts.last}';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';

  String _ageLabel(PatientProfile? p) => p?.age != null ? '${p!.age} yrs' : '—';

  String _sexLabel(Sex? sex) {
    switch (sex) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      case Sex.other:
        return 'Other';
      case null:
        return '—';
    }
  }

  String _contactLabel(PatientProfile? p) {
    final num = p?.whatsappNumber ?? p?.phone;
    return (num == null || num.isEmpty) ? '—' : '+91 $num';
  }

  String _followUpLabel(DateTime visitDate, int? days) {
    if (days == null || days <= 0) return 'As needed / SOS.';
    final date = visitDate.add(Duration(days: days));
    return 'After $days day${days == 1 ? '' : 's'} — on ${_formatDate(date)}.';
  }
}

final prescriptionPdfServiceProvider = Provider<PrescriptionPdfService>((ref) {
  return PrescriptionPdfService();
});
