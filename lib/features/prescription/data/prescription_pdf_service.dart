import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/locale/locale_provider.dart';
import '../../../core/utils/app_paths.dart';
import '../../../data/db/database_provider.dart';
import '../../../domain/models/doctor_profile.dart';
import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/patient.dart';
import '../../../domain/models/visit.dart';
import '../../../l10n/app_localizations.dart';
import 'pdf_shaper.dart';

/// Generates an NMC-standard Indian out-patient prescription PDF.
/// White background, teal (#00796B) accent only.
/// All doctor/clinic data comes from the [DoctorProfile] the caller passes;
/// there is no default identity — a blank field is simply not printed.
class PrescriptionPdfService {
  PrescriptionPdfService({this.attachmentsDir, AppLocalizations? labels})
    : _t = labels ?? lookupAppLocalizations(const Locale('en'));

  /// The doctor's scanned-report folder, used to add report pages. Null
  /// when nobody is signed in: only absolute legacy paths resolve then.
  final String? attachmentsDir;

  /// Every printed label (Diagnosis, Dosage, Advice…), in the language the
  /// doctor uses the app in (roadmap item 21). English when not given.
  final AppLocalizations _t;

  // 1mm ≈ 2.835 PDF points
  static const _mm = 2.835;

  /// Box the signature image is fitted into (points), above the rule.
  static const signatureBoxWidth = 170.0;
  static const signatureBoxHeight = 55.0;

  static final _teal = PdfColor.fromInt(0xFF00796B);
  static final _ink = PdfColor.fromInt(0xFF1A1A1A);
  static final _grey = PdfColor.fromInt(0xFF6B7280);
  static final _lightGrey = PdfColor.fromInt(0xFFBDBDBD);
  static final _rowAlt = PdfColor.fromInt(0xFFF5F5F5);

  /// Printable width of an A4 page inside the 15 mm side margins (points).
  static final _contentWidth = PdfPageFormat.a4.width - 30 * _mm;

  /// Width inside a section with the teal left rule and its padding.
  static final _sectionWidth = _contentWidth - 12;

  /// Medicine table column shares; they add up to 10.
  static const _columnFlex = [0.5, 2.5, 1.5, 2.0, 1.5, 2.0];

  /// Builds the prescription. [signaturePng] is the doctor's signature image
  /// (PNG or JPEG bytes); it is printed only when the visit is signed.
  Future<Uint8List> build({
    required VisitRecord visit,
    required PatientProfile? patient,
    required DoctorProfile doctor,
    Uint8List? signaturePng,
  }) async {
    final theme = await _loadTheme();
    final insight = visit.insight ?? MedicalInsight.empty;
    final instructions = insight.instructions
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final advice = insight.advice.where((s) => s.trim().isNotEmpty).toList();
    final tests = insight.tests.where((s) => s.trim().isNotEmpty).toList();
    final hasFollowUp =
        insight.followUpDays != null && insight.followUpDays! > 0;
    final attachments = await _loadAttachments(visit);

    // Two passes over the same layout (see PdfShaper): the first finds the
    // lines in Indian scripts, which are then shaped, the second uses them.
    // Shaped in the prescription's own language, so Marathi gets its
    // letterforms rather than Hindi's.
    final s = PdfShaper(locale: Locale(_t.localeName));
    List<pw.Widget> body() => [
      _doctorHeader(s, doctor),
      pw.SizedBox(height: 8),
      pw.Container(height: 1, color: _teal),
      pw.SizedBox(height: 12),
      _patientRow(s, visit, patient),
      pw.SizedBox(height: 16),
      if (insight.diagnosis.trim().isNotEmpty) ...[
        _diagnosisSection(s, insight.diagnosis),
        pw.SizedBox(height: 14),
      ],
      _medicinesSection(s, insight.medications),
      if (tests.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _listSection(s, _t.pdfInvestigations, tests, bullets: true),
      ],
      if (instructions.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _listSection(s, _t.pdfInstructions, instructions, bullets: true),
      ],
      if (advice.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        _listSection(s, _t.pdfAdvice, advice, bullets: false),
      ],
      if (hasFollowUp) ...[
        pw.SizedBox(height: 14),
        _followUpSection(s, visit.createdAt, insight.followUpDays!),
      ],
      pw.SizedBox(height: 28),
      _signatureBlock(s, visit, doctor, signaturePng),
      pw.SizedBox(height: 14),
    ];
    pw.Widget footer() => _footer(s);
    List<pw.Widget> reportPages() => [
      for (var i = 0; i < attachments.length; i++)
        _reportPage(s, patient, attachments[i], i),
    ];

    body();
    footer();
    reportPages();
    await s.shapePending();

    final doc = pw.Document(
      title: _t.pdfDocumentTitle(patient?.name ?? _t.pdfPatient),
      author: doctor.name,
      creator: 'Rxvarta',
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: pw.EdgeInsets.fromLTRB(
          15 * _mm, // left 15mm
          20 * _mm, // top 20mm
          15 * _mm, // right 15mm
          15 * _mm, // bottom 15mm
        ),
        footer: (ctx) => footer(),
        build: (ctx) => body(),
      ),
    );
    for (final page in reportPages()) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: pw.EdgeInsets.fromLTRB(
            15 * _mm,
            20 * _mm,
            15 * _mm,
            15 * _mm,
          ),
          build: (context) => page,
        ),
      );
    }
    return doc.save();
  }

  // ── Attached reports ──────────────────────────────────────────────────────

  /// The visit's report photos that can still be read from this phone.
  Future<List<({Uint8List bytes, String caption})>> _loadAttachments(
    VisitRecord visit,
  ) async {
    final result = <({Uint8List bytes, String caption})>[];
    for (final att in visit.attachments) {
      try {
        final dir = attachmentsDir;
        final path = dir == null
            ? att.path
            : AppPaths.resolveAttachment(att.path, attachmentsDir: dir);
        final file = File(path);
        if (!file.existsSync()) continue;
        result.add((bytes: await file.readAsBytes(), caption: att.caption));
      } catch (_) {
        // An unreadable photo is left out rather than failing the PDF.
      }
    }
    return result;
  }

  pw.Widget _reportPage(
    PdfShaper s,
    PatientProfile? patient,
    ({Uint8List bytes, String caption}) report,
    int i,
  ) {
    final caption = report.caption.trim().isEmpty
        ? _t.pdfReportCaption(i + 1)
        : report.caption.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (i == 0) ...[
          s.text(
            _t.pdfPreviousReports,
            pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _teal,
            ),
            maxWidth: _contentWidth,
          ),
          s.text(
            _t.pdfReportsAttachedFor(patient?.name ?? _t.pdfPatient),
            pw.TextStyle(fontSize: 9, color: _grey),
            maxWidth: _contentWidth,
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _lightGrey, thickness: 0.5),
          pw.SizedBox(height: 8),
        ],
        s.text(
          '${i + 1}. $caption',
          pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
          maxWidth: _contentWidth,
        ),
        pw.SizedBox(height: 6),
        pw.Expanded(
          child: pw.Center(
            child: pw.Image(
              pw.MemoryImage(report.bytes),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  /// A file name that is unique per visit and keeps the patient's name in
  /// their own script.
  ///
  /// Stripping everything but ASCII turned every Hindi, Tamil or Bengali name
  /// into "patient", and date-only stamps gave two same-day visits the same
  /// name, so an export zip kept one prescription and silently lost the rest.
  String fileName(PatientProfile? patient, VisitRecord visit) {
    // Keep letters and digits in any script; replace only characters that
    // are unsafe in a file name.
    final who = (patient?.name ?? '')
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final d = visit.createdAt;
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}';
    final idTail = visit.id.length <= 6
        ? visit.id
        : visit.id.substring(visit.id.length - 6);
    return 'Prescription_${who.isEmpty ? 'patient' : who}_${stamp}_$idTail.pdf';
  }

  Future<void> shareAsFile({
    required VisitRecord visit,
    required PatientProfile? patient,
    required DoctorProfile doctor,
    Uint8List? signaturePng,
  }) async {
    final bytes = await build(
      visit: visit,
      patient: patient,
      doctor: doctor,
      signaturePng: signaturePng,
    );
    await Printing.sharePdf(bytes: bytes, filename: fileName(patient, visit));
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  /// Built once and shared by every PDF.
  static pw.ThemeData? _theme;

  Future<pw.ThemeData> _loadTheme() async {
    final cached = _theme;
    if (cached != null) return cached;
    try {
      return _theme = await _buildTheme();
    } catch (e) {
      // Bundled fonts should always load; if packaging is broken, still
      // produce a prescription rather than none, and do not cache the
      // failure so the next PDF tries again.
      debugPrint('[pdf] bundled fonts failed to load: $e');
      return pw.ThemeData.base();
    }
  }

  /// Theme from the font bundled in the app, so a prescription prints the
  /// same with or without a network. It carries the Latin text; lines in
  /// Indian scripts are shaped by Flutter instead (see [PdfShaper]).
  Future<pw.ThemeData> _buildTheme() async {
    Future<pw.Font> load(String file) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));

    final base = await load('NotoSans-Regular.ttf');
    final bold = await load('NotoSans-Bold.ttf');
    return pw.ThemeData.withFont(
      base: base,
      bold: bold,
      // No italic faces are bundled. Using the upright faces keeps Unicode
      // text rendering; the pdf package would otherwise fall back to
      // Helvetica-Oblique, which has no Unicode glyphs at all.
      italic: base,
      boldItalic: bold,
    );
  }

  // ── Section 1: Doctor Header ──────────────────────────────────────────────

  /// The number printed on the letterhead: the clinic landline when the
  /// doctor gave one, otherwise their own mobile. Null only when the profile
  /// has neither, which the sign gate already prevents.
  static String? _contactNumber(DoctorProfile d) {
    final clinic = d.clinicPhone.trim();
    if (clinic.isNotEmpty) return clinic;
    final mobile = d.phone.trim();
    return mobile.isEmpty ? null : mobile;
  }

  /// Letterhead. Every line is guarded: a field the doctor has not filled in
  /// is left out rather than printed blank or invented.
  pw.Widget _doctorHeader(PdfShaper s, DoctorProfile d) {
    const gap = 16.0;
    final leftWidth = (_contentWidth - gap) * 3 / 5;
    final rightWidth = (_contentWidth - gap) * 2 / 5;
    final contact = _contactNumber(d);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (d.name.trim().isNotEmpty)
                s.text(
                  d.name.trim(),
                  pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                  maxWidth: leftWidth,
                ),
              if (d.qualifications.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                s.text(
                  d.qualifications,
                  pw.TextStyle(fontSize: 11, color: _grey),
                  maxWidth: leftWidth,
                ),
              ],
              if (d.regNo.trim().isNotEmpty) ...[
                pw.SizedBox(height: 2),
                s.text(
                  '${_t.pdfRegNo}: ${d.regNo}',
                  pw.TextStyle(fontSize: 10, color: _grey),
                  maxWidth: leftWidth,
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: gap),
        // Clinic details — right
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (d.clinicName.trim().isNotEmpty)
                s.text(
                  d.clinicName,
                  pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                  maxWidth: rightWidth,
                  align: pw.TextAlign.right,
                ),
              if (d.clinicAddress.trim().isNotEmpty) ...[
                pw.SizedBox(height: 2),
                s.text(
                  d.clinicAddress,
                  pw.TextStyle(fontSize: 10, color: _grey),
                  maxWidth: rightWidth,
                  align: pw.TextAlign.right,
                ),
              ],
              // The clinic landline is optional; the doctor's own mobile is
              // required. Fall back to it so a prescription always carries a
              // number the patient can call.
              if (contact != null) ...[
                pw.SizedBox(height: 2),
                s.text(
                  '${_t.pdfPhone}: $contact',
                  pw.TextStyle(fontSize: 10, color: _grey),
                  maxWidth: rightWidth,
                  align: pw.TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Section 2: Patient Details + Date ────────────────────────────────────

  pw.Widget _patientRow(PdfShaper s, VisitRecord visit, PatientProfile? p) {
    final tenth = _contentWidth / 10;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              flex: 6,
              child: _lv(s, _t.pdfPatient, p?.name ?? '—', 6 * tenth),
            ),
            pw.Expanded(
              flex: 4,
              child: _lv(s, _t.pdfDate, _ddmmyyyy(visit.createdAt), 4 * tenth),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 2,
              child: _lv(
                s,
                _t.pdfAge,
                p?.age != null ? _t.pdfAgeYears(p!.age!) : '—',
                2 * tenth,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: _lv(s, _t.pdfGender, _genderLabel(p?.sex), 2 * tenth),
            ),
            pw.Expanded(
              flex: 6,
              child: _lv(s, _t.pdfPhone, _phoneLabel(p), 6 * tenth),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section 3: Diagnosis with ℞ symbol ───────────────────────────────────

  pw.Widget _diagnosisSection(PdfShaper s, String diagnosis) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '℞', // ℞ PRESCRIPTION TAKE
          style: pw.TextStyle(
            fontSize: 24,
            color: _teal,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        s.runs([
          PdfRun(
            '${_t.pdfDiagnosis}: ',
            pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          PdfRun(diagnosis, pw.TextStyle(fontSize: 12, color: _ink)),
        ], maxWidth: _contentWidth),
      ],
    );
  }

  // ── Section 4: Medicines Table ────────────────────────────────────────────

  pw.Widget _medicinesSection(PdfShaper s, List<Medication> meds) {
    if (meds.isEmpty) {
      return s.text(
        _t.pdfNoMedicines,
        pw.TextStyle(fontSize: 10, color: _grey),
        maxWidth: _contentWidth,
      );
    }
    return _medicinesTable(s, meds);
  }

  pw.Widget _medicinesTable(PdfShaper s, List<Medication> meds) {
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(fontSize: 10, color: _ink);
    // Text width inside a column: its share of the page, less the 6 pt
    // padding on each side and the border.
    double textWidth(int column) =>
        _contentWidth * _columnFlex[column] / 10 - 13;

    pw.Widget hcell(int column, String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: s.text(text, headerStyle, maxWidth: textWidth(column)),
    );

    pw.Widget dcell(int column, String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: s.text(
        text.trim().isEmpty ? '' : text,
        bold ? cellStyle.copyWith(fontWeight: pw.FontWeight.bold) : cellStyle,
        maxWidth: textWidth(column),
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: _lightGrey, width: 0.5),
      columnWidths: {
        for (var i = 0; i < _columnFlex.length; i++)
          i: pw.FlexColumnWidth(_columnFlex[i]),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _teal),
          children: [
            hcell(0, '#'),
            hcell(1, _t.pdfColMedicine),
            hcell(2, _t.pdfColDosage),
            hcell(3, _t.pdfColFrequency),
            hcell(4, _t.pdfColDuration),
            hcell(5, _t.pdfColTiming),
          ],
        ),
        for (var i = 0; i < meds.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : _rowAlt,
            ),
            children: [
              dcell(0, '${i + 1}'),
              dcell(1, meds[i].name.toUpperCase(), bold: true),
              dcell(2, meds[i].dosage),
              dcell(3, meds[i].frequency),
              dcell(4, meds[i].duration),
              dcell(5, meds[i].timing),
            ],
          ),
      ],
    );
  }

  // ── Sections 5–7: Investigations, Instructions, Advice ───────────────────

  /// A titled list with the teal rule on its left. Investigations are the
  /// tests the doctor asked for (roadmap item 19); the doctor's private
  /// notes are never printed.
  pw.Widget _listSection(
    PdfShaper s,
    String title,
    List<String> items, {
    required bool bullets,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _teal, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(left: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          s.text(
            '$title:',
            pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
            maxWidth: _sectionWidth,
          ),
          pw.SizedBox(height: 4),
          for (final item in items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: s.text(
                bullets ? '•  $item' : item,
                pw.TextStyle(fontSize: 10, color: _ink),
                maxWidth: _sectionWidth,
              ),
            ),
        ],
      ),
    );
  }

  // ── Section 8: Follow-up ─────────────────────────────────────────────────

  pw.Widget _followUpSection(PdfShaper s, DateTime visitDate, int days) {
    final nextDate = visitDate.add(Duration(days: days));
    final label = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    );
    final value = pw.TextStyle(fontSize: 10, color: _ink);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        s.runs([
          PdfRun('${_t.pdfFollowUp}: ', label),
          PdfRun(_t.pdfFollowUpAfter(days), value),
        ], maxWidth: _contentWidth),
        pw.SizedBox(height: 2),
        s.runs([
          PdfRun('${_t.pdfNextVisit}: ', label),
          PdfRun(_ddmmyyyy(nextDate), value),
        ], maxWidth: _contentWidth),
      ],
    );
  }

  // ── Section 9: Signature ─────────────────────────────────────────────────

  /// Signed + image: the doctor's real signature above the rule. Signed
  /// without an image (older device, file missing): name and registration
  /// number only — never a typed stand-in. Unsigned: the localized
  /// "Awaiting signature" placeholder.
  pw.Widget _signatureBlock(
    PdfShaper s,
    VisitRecord visit,
    DoctorProfile d,
    Uint8List? signaturePng,
  ) {
    final image = visit.signed ? _decodeSignature(signaturePng) : null;
    final name = d.name.trim();
    final regNo = d.regNo.trim();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (image != null)
              pw.Container(
                width: signatureBoxWidth,
                height: signatureBoxHeight,
                alignment: pw.Alignment.bottomCenter,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              )
            else if (!visit.signed)
              s.text(
                _t.pdfAwaitingSignature,
                pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  color: _grey,
                ),
                maxWidth: signatureBoxWidth,
                align: pw.TextAlign.center,
              ),
            pw.SizedBox(height: 4),
            pw.Container(width: signatureBoxWidth, height: 0.5, color: _grey),
            pw.SizedBox(height: 4),
            if (name.isNotEmpty)
              s.text(
                name,
                pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
                maxWidth: signatureBoxWidth,
                align: pw.TextAlign.center,
              ),
            if (regNo.isNotEmpty)
              s.text(
                '${_t.pdfRegNo}: $regNo',
                pw.TextStyle(fontSize: 9, color: _grey),
                maxWidth: signatureBoxWidth,
                align: pw.TextAlign.center,
              ),
            pw.Text(
              _ddmmyyyy(visit.signedAt ?? visit.createdAt),
              style: pw.TextStyle(fontSize: 9, color: _grey),
            ),
          ],
        ),
      ],
    );
  }

  /// Accepts PNG or JPEG bytes; anything else (or nothing) yields null so a
  /// corrupt file degrades to "name + reg. no" instead of failing the PDF.
  pw.ImageProvider? _decodeSignature(Uint8List? bytes) {
    if (bytes == null || bytes.length < 4) return null;
    final isPng =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    if (!isPng && !isJpeg) return null;
    try {
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  pw.Widget _footer(PdfShaper s) {
    final style = pw.TextStyle(fontSize: 8, color: _grey);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: _teal),
        pw.SizedBox(height: 4),
        s.text(
          _t.pdfComputerGenerated,
          style,
          maxWidth: _contentWidth,
          align: pw.TextAlign.center,
        ),
        s.text(
          _t.pdfFooterTagline,
          style,
          maxWidth: _contentWidth,
          align: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Small label + bold value column used in the patient row.
  pw.Widget _lv(PdfShaper s, String label, String value, double width) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        s.text(label, pw.TextStyle(fontSize: 8, color: _grey), maxWidth: width),
        s.text(
          value,
          pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
          maxWidth: width,
        ),
      ],
    );
  }

  String _ddmmyyyy(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _genderLabel(Sex? sex) {
    switch (sex) {
      case Sex.male:
        return _t.male;
      case Sex.female:
        return _t.female;
      case Sex.other:
        return _t.other;
      case null:
        return '—';
    }
  }

  String _phoneLabel(PatientProfile? p) {
    final num = p?.whatsappNumber ?? p?.phone;
    return (num == null || num.isEmpty) ? '—' : '+91 $num';
  }
}

final prescriptionPdfServiceProvider = Provider<PrescriptionPdfService>((ref) {
  return PrescriptionPdfService(
    attachmentsDir: ref.watch(attachmentsDirProvider),
    labels: lookupAppLocalizations(ref.watch(appLocaleProvider)),
  );
});
