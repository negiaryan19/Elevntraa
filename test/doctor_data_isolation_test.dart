import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rxvarta/core/auth/auth_providers.dart';
import 'package:rxvarta/core/utils/app_paths.dart';
import 'package:rxvarta/data/db/app_database.dart';
import 'package:rxvarta/data/repositories/patient_repository.dart';
import 'package:rxvarta/domain/models/patient.dart';
import 'package:rxvarta/features/consultation/presentation/consultation_controller.dart';
import 'package:rxvarta/features/prescription/data/prescription_pdf_service.dart';

/// Every doctor on a phone used to share one database, one report folder
/// and one recordings folder, and signing out cleared none of them: Doctor B
/// signing in on Doctor A's phone saw all of A's patients and prescriptions
/// (roadmap item 6).
void main() {
  late Directory docs;
  late ProviderContainer container;
  final signedIn = StateProvider<String?>((ref) => null);

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('rxvarta_isolation_');
    await AppPaths.init(documentsDir: docs.path);
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => ref.watch(signedIn)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    // Let the background database isolates close before deleting files.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await docs.delete(recursive: true);
  });

  void signIn(String? uid) => container.read(signedIn.notifier).state = uid;

  PatientRepository patients() => container.read(patientRepositoryProvider);

  PatientProfile patient(String id, String name) => PatientProfile(
    id: id,
    name: name,
    createdAt: DateTime(2026, 9, 17),
    updatedAt: DateTime(2026, 9, 17),
  );

  Future<List<String>> names() async =>
      (await patients().recent()).map((p) => p.name).toList();

  test('a doctor never sees another doctor\'s patients', () async {
    signIn('doctor-a');
    await patients().upsert(patient('pa', 'Asha (Dr A)'));

    signIn('doctor-b');
    expect(await names(), isEmpty);
    await patients().upsert(patient('pb', 'Bharat (Dr B)'));
    expect(await names(), ['Bharat (Dr B)']);

    signIn('doctor-a');
    expect(await names(), ['Asha (Dr A)']);

    expect(
      File(
        p.join(docs.path, 'users', 'doctor-a', 'rxvarta.sqlite'),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        p.join(docs.path, 'users', 'doctor-b', 'rxvarta.sqlite'),
      ).existsSync(),
      isTrue,
    );
    expect(File(p.join(docs.path, 'rxvarta.sqlite')).existsSync(), isFalse);
  });

  test('signed out, no doctor\'s records are readable or saved', () async {
    signIn('doctor-a');
    await patients().upsert(patient('pa', 'Asha (Dr A)'));

    signIn(null);
    expect(await names(), isEmpty);
    await patients().upsert(patient('px', 'Written while signed out'));

    signIn('doctor-a');
    expect(await names(), ['Asha (Dr A)']);
  });

  test(
    'an upgraded phone\'s shared records go to the first doctor who signs in, '
    'and only to them',
    () async {
      // What an older build left behind: one database for the whole phone,
      // plus shared report and recording folders.
      final shared = AppDatabase.forTesting(
        NativeDatabase(File(p.join(docs.path, 'rxvarta.sqlite'))),
      );
      await PatientRepository(shared).upsert(patient('old', 'Ramesh (before)'));
      await shared.close();
      File(p.join(docs.path, 'attachments', 'report.jpg'))
        ..createSync(recursive: true)
        ..writeAsStringSync('jpg');
      File(p.join(docs.path, 'recordings', 'visit_1.m4a'))
        ..createSync(recursive: true)
        ..writeAsStringSync('m4a');

      signIn('doctor-a');
      expect(await names(), ['Ramesh (before)']);
      expect(
        File(
          p.join(docs.path, 'users', 'doctor-a', 'attachments', 'report.jpg'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(docs.path, 'users', 'doctor-a', 'recordings', 'visit_1.m4a'),
        ).existsSync(),
        isTrue,
      );
      expect(File(p.join(docs.path, 'rxvarta.sqlite')).existsSync(), isFalse);
      expect(Directory(p.join(docs.path, 'attachments')).existsSync(), isFalse);

      signIn('doctor-b');
      expect(await names(), isEmpty);
    },
  );

  test(
    'prescription report pages come from the signed-in doctor\'s folder',
    () {
      signIn('doctor-a');
      expect(
        container.read(prescriptionPdfServiceProvider).attachmentsDir,
        p.join(docs.path, 'users', 'doctor-a', 'attachments'),
      );
      signIn('doctor-b');
      expect(
        container.read(prescriptionPdfServiceProvider).attachmentsDir,
        p.join(docs.path, 'users', 'doctor-b', 'attachments'),
      );
      signIn(null);
      expect(
        container.read(prescriptionPdfServiceProvider).attachmentsDir,
        isNull,
      );
    },
  );

  test('an in-progress transcript does not carry over to another doctor', () {
    signIn('doctor-a');
    container.read(cumulativeTranscriptProvider.notifier).state =
        'Dr A: fever for two days';
    signIn('doctor-b');
    expect(container.read(cumulativeTranscriptProvider), isEmpty);
  });

  group('attachment references', () {
    test('relative names resolve inside the doctor\'s report folder', () {
      expect(
        AppPaths.resolveAttachment(
          'a.jpg',
          attachmentsDir: '/docs/users/x/attachments',
        ),
        '/docs/users/x/attachments/a.jpg',
      );
    });

    test('old absolute paths into the shared folder still find the file', () {
      expect(
        AppPaths.resolveAttachment(
          '/old/container/attachments/a.jpg',
          attachmentsDir: '/docs/users/x/attachments',
        ),
        '/docs/users/x/attachments/a.jpg',
      );
    });

    test('an absolute path that still exists is used as is', () {
      final f = File(p.join(docs.path, 'elsewhere.jpg'))
        ..writeAsStringSync('x');
      expect(
        AppPaths.resolveAttachment(
          f.path,
          attachmentsDir: '/docs/users/x/attachments',
        ),
        f.path,
      );
    });
  });
}
