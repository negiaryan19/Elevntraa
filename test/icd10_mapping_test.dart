import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import 'package:rxvarta/domain/models/medical_insight.dart';
import 'package:rxvarta/features/consultation/data/insight_service.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
import 'icd10_mapping_test.mocks.dart';

void main() {
  // ── ICD-10 regex pattern ──────────────────────────────────────────────────

  group('ICD-10 pattern validation', () {
    final pattern = InsightService.icdPattern;

    // Valid codes
    const validCodes = [
      'J06.9', // Acute upper-respiratory infection
      'B34.9', // Viral infection, unspecified
      'A00', // Cholera (base code, no decimal)
      'K21.0', // GERD with oesophagitis
      'E11.9', // Type 2 diabetes, no complications
      'I10', // Essential hypertension
      'Z00.0', // General health examination
      'M54.5', // Low back pain
      'J45.9', // Asthma, unspecified (4-char suffix)
    ];

    for (final code in validCodes) {
      test('accepts valid code $code', () {
        expect(pattern.hasMatch(code), isTrue);
      });
    }

    // Invalid codes
    const invalidCodes = [
      '', // empty
      'j06.9', // lowercase letter
      '106.9', // digit instead of letter prefix
      'JO6.9', // letter O instead of digit 0
      'J6.9', // only one digit after letter
      'J069', // no dot, four digits
      'J06.99999', // suffix too long (5 chars)
      'J06.', // trailing dot, no suffix
      '.J06', // wrong prefix
      'J06.9X1Z5', // suffix way too long
      'null', // literal "null" string
    ];

    for (final code in invalidCodes) {
      test('rejects invalid code "$code"', () {
        expect(pattern.hasMatch(code), isFalse);
      });
    }
  });

  // ── _coerce ICD field handling ────────────────────────────────────────────

  group('InsightService.coerce ICD fields', () {
    late InsightService service;

    setUp(() {
      service = InsightService(MockDio());
    });

    Map<String, dynamic> base({String? icdCode, String? icdDescription}) => {
      'consultationSummary': 'Patient has fever.',
      'symptoms': ['fever'],
      'diagnosis': 'Viral fever',
      'differentials': <String>[],
      'medications': <dynamic>[],
      'tests': <String>[],
      'advice': <String>[],
      'instructions': <String>[],
      'followUpDays': null,
      'doctorNotes': '',
      'icdCode': icdCode,
      'icdDescription': icdDescription,
    };

    test('passes through a valid ICD code and description', () {
      final result = service.coerce(
        base(
          icdCode: 'J06.9',
          icdDescription: 'Acute upper-respiratory infection',
        ),
      );
      expect(result['icdCode'], 'J06.9');
      expect(result['icdDescription'], 'Acute upper-respiratory infection');
    });

    test('passes through a valid code without decimal suffix', () {
      final result = service.coerce(
        base(
          icdCode: 'I10',
          icdDescription: 'Essential (primary) hypertension',
        ),
      );
      expect(result['icdCode'], 'I10');
      expect(result['icdDescription'], 'Essential (primary) hypertension');
    });

    // ── icdConfidence ────────────────────────────────────────────────────────

    test('passes through confidence "high"', () {
      final result = service.coerce(
        base(icdCode: 'J06.9', icdDescription: 'Acute URI')
          ..['icdConfidence'] = 'high',
      );
      expect(result['icdConfidence'], 'high');
    });

    test('passes through confidence "medium"', () {
      final result = service.coerce(
        base(icdCode: 'J06.9', icdDescription: 'Acute URI')
          ..['icdConfidence'] = 'medium',
      );
      expect(result['icdConfidence'], 'medium');
    });

    test('discards unknown confidence value', () {
      final result = service.coerce(
        base(icdCode: 'J06.9', icdDescription: 'Acute URI')
          ..['icdConfidence'] = 'low',
      );
      expect(result['icdConfidence'], isNull);
    });

    test('discards confidence when icdCode is invalid', () {
      final result = service.coerce(
        base(icdCode: 'bad', icdDescription: 'Something')
          ..['icdConfidence'] = 'high',
      );
      expect(result['icdCode'], isNull);
      expect(result['icdConfidence'], isNull);
    });

    test('nulls confidence when icdCode is absent', () {
      final input = base()..['icdConfidence'] = 'high';
      final result = service.coerce(input);
      expect(result['icdConfidence'], isNull);
    });

    test('nulls out a malformed ICD code', () {
      final result = service.coerce(
        base(icdCode: 'j06.9', icdDescription: 'Something'),
      );
      expect(result['icdCode'], isNull);
      expect(result['icdDescription'], isNull);
    });

    test('nulls out icdDescription when code is invalid', () {
      final result = service.coerce(
        base(icdCode: '12345', icdDescription: 'Should be dropped'),
      );
      expect(result['icdCode'], isNull);
      expect(result['icdDescription'], isNull);
    });

    test('nulls out icdDescription when it is an empty string', () {
      final result = service.coerce(base(icdCode: 'J06.9', icdDescription: ''));
      expect(result['icdCode'], 'J06.9');
      expect(result['icdDescription'], isNull);
    });

    test('handles missing icdCode key', () {
      final result = service.coerce(base());
      expect(result['icdCode'], isNull);
      expect(result['icdDescription'], isNull);
    });

    test('handles null icdCode value explicitly', () {
      final input = base()..['icdCode'] = null;
      final result = service.coerce(input);
      expect(result['icdCode'], isNull);
    });

    test('handles non-string icdCode type', () {
      final input = base()..['icdCode'] = 12345;
      final result = service.coerce(input);
      expect(result['icdCode'], isNull);
    });

    test('does not set icdDescription when code is absent', () {
      final input = base()..['icdDescription'] = 'Orphan description';
      final result = service.coerce(input);
      expect(result['icdDescription'], isNull);
    });
  });

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
