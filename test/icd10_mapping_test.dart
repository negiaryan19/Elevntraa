import 'package:flutter_test/flutter_test.dart';

import 'package:rxvarta/domain/models/medical_insight.dart';

// Note: ICD-10 regex + coercion now live in the backend pipeline
// (supabase/functions/_shared/pipeline.ts); the on-device InsightService was
// removed in the backend-cleanup. These tests cover the MedicalInsight model,
// which the app still owns.
void main() {
  // ── MedicalInsight model ──────────────────────────────────────────────────

  group('MedicalInsight ICD fields', () {
    test('fromJson round-trips icdCode and icdDescription', () {
      final json = {
        'icdCode': 'K21.0',
        'icdDescription': 'Gastro-oesophageal reflux disease with oesophagitis',
        'consultationSummary': '',
        'symptoms': <dynamic>[],
        'diagnosis': '',
        'differentials': <dynamic>[],
        'medications': <dynamic>[],
        'tests': <dynamic>[],
        'advice': <dynamic>[],
        'instructions': <dynamic>[],
        'followUpDays': null,
        'doctorNotes': '',
      };
      final insight = MedicalInsight.fromJson(json);
      expect(insight.icdCode, 'K21.0');
      expect(
        insight.icdDescription,
        'Gastro-oesophageal reflux disease with oesophagitis',
      );
    });

    test('fromJson handles null icdCode and icdDescription', () {
      final json = {
        'icdCode': null,
        'icdDescription': null,
        'consultationSummary': '',
        'symptoms': <dynamic>[],
        'diagnosis': '',
        'differentials': <dynamic>[],
        'medications': <dynamic>[],
        'tests': <dynamic>[],
        'advice': <dynamic>[],
        'instructions': <dynamic>[],
        'followUpDays': null,
        'doctorNotes': '',
      };
      final insight = MedicalInsight.fromJson(json);
      expect(insight.icdCode, isNull);
      expect(insight.icdDescription, isNull);
    });

    test('toJson includes icdCode and icdDescription', () {
      const insight = MedicalInsight(
        diagnosis: 'Type 2 diabetes',
        icdCode: 'E11.9',
        icdDescription: 'Type 2 diabetes mellitus without complications',
      );
      final json = insight.toJson();
      expect(json['icdCode'], 'E11.9');
      expect(
        json['icdDescription'],
        'Type 2 diabetes mellitus without complications',
      );
    });

    test('toJson serializes null ICD fields as null', () {
      const insight = MedicalInsight(diagnosis: 'Viral fever');
      final json = insight.toJson();
      expect(json.containsKey('icdCode'), isTrue);
      expect(json['icdCode'], isNull);
      expect(json['icdDescription'], isNull);
    });

    test('copyWith can update icdCode', () {
      const original = MedicalInsight(
        diagnosis: 'GERD',
        icdCode: 'K21.0',
        icdDescription: 'GERD with oesophagitis',
      );
      final updated = original.copyWith(icdCode: 'K21.9');
      expect(updated.icdCode, 'K21.9');
      // Other fields unchanged
      expect(updated.diagnosis, 'GERD');
      expect(updated.icdDescription, 'GERD with oesophagitis');
    });

    test('copyWith can clear icdCode', () {
      const original = MedicalInsight(
        diagnosis: 'GERD',
        icdCode: 'K21.0',
        icdDescription: 'GERD with oesophagitis',
      );
      final cleared = original.copyWith(icdCode: null, icdDescription: null);
      expect(cleared.icdCode, isNull);
      expect(cleared.icdDescription, isNull);
    });

    test('empty constant has null ICD fields', () {
      expect(MedicalInsight.empty.icdCode, isNull);
      expect(MedicalInsight.empty.icdDescription, isNull);
      expect(MedicalInsight.empty.icdConfidence, isNull);
    });

    test('equality respects icdCode', () {
      const a = MedicalInsight(icdCode: 'J06.9');
      const b = MedicalInsight(icdCode: 'J06.9');
      const c = MedicalInsight(icdCode: 'B34.9');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('fromJson round-trips icdConfidence', () {
      final json = {
        'icdCode': 'J06.9',
        'icdDescription': 'Acute URI',
        'icdConfidence': 'medium',
        'consultationSummary': '',
        'symptoms': <dynamic>[],
        'diagnosis': '',
        'differentials': <dynamic>[],
        'medications': <dynamic>[],
        'tests': <dynamic>[],
        'advice': <dynamic>[],
        'instructions': <dynamic>[],
        'followUpDays': null,
        'doctorNotes': '',
      };
      final insight = MedicalInsight.fromJson(json);
      expect(insight.icdConfidence, 'medium');
      expect(insight.toJson()['icdConfidence'], 'medium');
    });

    test('copyWith clears icdConfidence when doctor edits', () {
      const original = MedicalInsight(
        icdCode: 'J06.9',
        icdDescription: 'Acute URI',
        icdConfidence: 'high',
      );
      final edited = original.copyWith(icdCode: 'J06.0', icdConfidence: null);
      expect(edited.icdCode, 'J06.0');
      expect(edited.icdConfidence, isNull);
    });

    test('equality respects icdConfidence', () {
      const high = MedicalInsight(icdCode: 'J06.9', icdConfidence: 'high');
      const medium = MedicalInsight(icdCode: 'J06.9', icdConfidence: 'medium');
      const noConf = MedicalInsight(icdCode: 'J06.9');
      expect(high, isNot(equals(medium)));
      expect(medium, isNot(equals(noConf)));
    });
  });
}
