import '../../../domain/models/medical_insight.dart';
import '../../../domain/models/medication.dart';
import 'pipeline_service.dart';

/// DEBUG ONLY stand-in for [PipelineService]. Returns a fixed transcript and
/// [MedicalInsight] without any network or AI calls, so the full
/// Review → Share → Add-More flow can be exercised on an emulator that cannot
/// feed real speech through its virtual mic.
///
/// Swapped in by [pipelineServiceProvider] when [kDebugSkipStt] is true
/// (build with `--dart-define=DEBUG_SKIP_STT=true`). Never used in real builds.
///
/// The hardcoded insight mirrors the old on-device debug transcript: a viral
/// fever with body ache, prescribing Paracetamol / Cetirizine / Vitamin C with
/// a 3-day follow-up.
class MockPipelineService implements PipelineService {
  static const String _mockTranscript =
      'Doctor: Aapko kya taklif ho rahi hai?\n'
      'Patient: Do din se bahut zyada headache ho raha hai. Body mein dard bhi '
      'hai aur thakaan lag rahi hai. Bukhar bhi hai, kal raat 101 degrees tha.\n'
      'Doctor: Yeh viral fever with body ache lag raha hai. Paracetamol 500mg '
      'din mein do baar khana khane ke baad teen din tak lena. Cetirizine 10mg '
      'raat ko sone se pehle teen din tak lena. Vitamin C 500mg subah ek baar '
      'teen din tak lena. Paani zyada piyo, aaram karo. Teen din baad follow up.';

  static const MedicalInsight _mockInsight = MedicalInsight(
    consultationSummary:
        'Patient presented with a two-day history of headache, body ache, '
        'fatigue and fever. Diagnosed with viral fever and prescribed '
        'symptomatic treatment with a 3-day follow-up.',
    symptoms: ['Headache', 'Body ache', 'Fatigue', 'Fever'],
    diagnosis: 'Viral fever with body ache',
    medications: [
      Medication(
        name: 'Paracetamol',
        dosage: '500mg',
        frequency: 'Twice a day',
        duration: '3 days',
        timing: 'After food',
      ),
      Medication(
        name: 'Cetirizine',
        dosage: '10mg',
        frequency: 'Once a day',
        duration: '3 days',
        timing: 'Before bed',
      ),
      Medication(
        name: 'Vitamin C',
        dosage: '500mg',
        frequency: 'Once a day',
        duration: '3 days',
        timing: 'After food',
      ),
    ],
    advice: ['Drink plenty of water', 'Take rest'],
    instructions: ['Return after 3 days for follow-up'],
    followUpDays: 3,
  );

  @override
  Future<InsightResult> processConsultation({
    required String audioPath,
    required String languageCode,
    Duration? audioDuration,
    String? previousTranscript,
  }) async {
    // Mirror the backend's "Add More" accumulation so the cumulative transcript
    // grows across segments exactly as it would in production.
    final hasPrevious =
        previousTranscript != null && previousTranscript.trim().isNotEmpty;
    final transcript = hasPrevious
        ? '$previousTranscript\n$_mockTranscript'
        : _mockTranscript;

    return InsightResult(transcript: transcript, insight: _mockInsight);
  }
}
