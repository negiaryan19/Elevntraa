import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/db/database_provider.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/data/repositories/visit_repository.dart';
import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/domain/models/report_attachment.dart';
import 'package:rxvarta/domain/models/visit.dart';
import 'package:rxvarta/features/patient/presentation/patient_detail_screen.dart';
import 'package:rxvarta/l10n/app_localizations.dart';

/// Report photos attached to a visit were printed in its PDF but invisible in
/// the patient's history (roadmap item 17): checking last month's blood report
/// meant opening that visit's PDF and paging to the end.
void main() {
  late AppDatabase db;
  late Directory dir;
  final at = DateTime(2026, 9, 1, 10);

  // A valid 1x1 PNG.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9'
    'awAAAABJRU5ErkJggg==',
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('rx_reports_');
    await PatientRepository(db).upsert(
      PatientProfile(
        id: 'p1',
        name: 'Sunita Devi',
        createdAt: at,
        updatedAt: at,
      ),
    );
  });
  tearDown(() async {
    await db.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> seedVisit(List<ReportAttachment> attachments) =>
      VisitRepository(db).upsert(
        VisitRecord(
          id: 'v1',
          patientId: 'p1',
          createdAt: at,
          insight: const MedicalInsight(diagnosis: 'Anaemia'),
          attachments: attachments,
        ),
      );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          attachmentsDirProvider.overrideWithValue(dir.path),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PatientDetailScreen(patientId: 'p1'),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets('a visit shows its attached reports', (tester) async {
    File(p.join(dir.path, 'a.png')).writeAsBytesSync(png);
    File(p.join(dir.path, 'b.png')).writeAsBytesSync(png);
    await seedVisit(const [
      // Stored as relative names, resolved against the doctor's folder.
      ReportAttachment(path: 'a.png', caption: 'CBC, 2 Aug'),
      ReportAttachment(path: 'b.png'),
    ]);
    await pump(tester);

    expect(find.text('Previous reports'), findsOneWidget);
    expect(find.byKey(const Key('report_thumb_0')), findsOneWidget);
    expect(find.byKey(const Key('report_thumb_1')), findsOneWidget);
    expect(find.bySemanticsLabel('CBC, 2 Aug'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Report 2'),
      findsOneWidget,
      reason: 'an uncaptioned report is numbered as in the PDF',
    );
  });

  testWidgets('tapping a report opens it full screen with its caption', (
    tester,
  ) async {
    File(p.join(dir.path, 'a.png')).writeAsBytesSync(png);
    await seedVisit(const [
      ReportAttachment(path: 'a.png', caption: 'CBC, 2 Aug'),
    ]);
    await pump(tester);

    await tester.tap(find.byKey(const Key('report_thumb_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'CBC, 2 Aug'), findsOneWidget);
  });

  testWidgets('a report whose file is gone is left out', (tester) async {
    File(p.join(dir.path, 'kept.png')).writeAsBytesSync(png);
    await seedVisit(const [
      ReportAttachment(path: 'lost.png', caption: 'Lost scan'),
      ReportAttachment(path: 'kept.png', caption: 'Kept scan'),
    ]);
    await pump(tester);

    expect(find.bySemanticsLabel('Kept scan'), findsOneWidget);
    expect(find.bySemanticsLabel('Lost scan'), findsNothing);
    expect(find.byKey(const Key('report_thumb_1')), findsNothing);
  });

  testWidgets('a visit with no reports shows no reports section', (
    tester,
  ) async {
    await seedVisit(const []);
    await pump(tester);
    expect(find.text('Previous reports'), findsNothing);
  });

  testWidgets('an old absolute path still resolves by file name', (
    tester,
  ) async {
    // Builds before per-doctor storage saved absolute paths into a shared
    // folder that has since moved into the doctor's own folder.
    File(p.join(dir.path, 'old.png')).writeAsBytesSync(png);
    await seedVisit(const [
      ReportAttachment(
        path: '/data/user/0/app/files/attachments/old.png',
        caption: 'Old X-ray',
      ),
    ]);
    await pump(tester);
    expect(find.bySemanticsLabel('Old X-ray'), findsOneWidget);
  });
}
