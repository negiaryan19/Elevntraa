import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/errors/failure.dart';

/// Wraps the `record` package with a simple start/stop API + an amplitude
/// stream the waveform widget consumes. The recording is stored as M4A
/// (AAC inside an MP4 container) — small files, supported by Sarvam's STT.
class RecordingService {
  RecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  StreamSubscription<Amplitude>? _ampSub;
  final _amplitudeController = StreamController<double>.broadcast();
  String? _currentPath;

  /// Normalized amplitude stream [0..1]. Drives the waveform.
  Stream<double> get amplitude => _amplitudeController.stream;

  /// Start recording. Returns the file path being written.
  Future<String> start() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const PermissionFailure('Microphone permission was denied.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(dir.path, 'recordings'));
    if (!recordingsDir.existsSync()) recordingsDir.createSync(recursive: true);

    final path = p.join(
      recordingsDir.path,
      'visit_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
        // iOS only (Android ignores this). The package default also enables
        // allowBluetooth/allowBluetoothA2DP, which lets iOS route capture to
        // a paired Mac/AirPods/watch whose HFP channel can deliver zero
        // frames — the recorder then writes a silent ~28-byte m4a. Keeping
        // only defaultToSpeaker pins capture to the built-in microphone.
        iosConfig: IosRecordConfig(
          categoryOptions: [IosAudioCategoryOption.defaultToSpeaker],
        ),
      ),
      path: path,
    );

    _currentPath = path;

    // Sample amplitude ~10x/sec — smooth enough for the bar visualiser,
    // cheap enough not to cause UI jank.
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((a) {
      // dBFS range is roughly -60..0. Normalize so silence ≈ 0 and loud ≈ 1.
      final db = a.current;
      final normalized = ((db + 50) / 50).clamp(0.0, 1.0);
      if (!_amplitudeController.isClosed) {
        _amplitudeController.add(normalized);
      }
    });

    return path;
  }

  /// Pause the underlying recorder. Audio capture halts until [resume].
  Future<void> pause() async {
    try {
      if (await _recorder.isRecording() && !(await _recorder.isPaused())) {
        await _recorder.pause();
      }
    } catch (_) {/* best-effort */}
  }

  /// Resume after a [pause]. No-op if not paused.
  Future<void> resume() async {
    try {
      if (await _recorder.isPaused()) {
        await _recorder.resume();
      }
    } catch (_) {/* best-effort */}
  }

  /// Stop recording. Returns the saved file path, or null on error.
  Future<String?> stop() async {
    try {
      final path = await _recorder.stop();
      await _ampSub?.cancel();
      _ampSub = null;
      return path ?? _currentPath;
    } finally {
      _currentPath = null;
    }
  }

  /// Read the true duration of a recorded file. Used to decide between the
  /// Sarvam REST (≤30s) and Batch (>30s) paths — far more reliable than a
  /// UI timer, which drifts under jank or fake-pause.
  Future<Duration?> probeDuration(String path) async {
    final player = AudioPlayer();
    try {
      return await player.setFilePath(path);
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }

  /// Cancel without saving. Best-effort cleanup of the partial file.
  Future<void> cancel() async {
    try {
      await _recorder.cancel();
      final path = _currentPath;
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      }
    } catch (_) {/* swallowed — cancel is best-effort */}
    await _ampSub?.cancel();
    _ampSub = null;
    _currentPath = null;
  }

  Future<bool> isRecording() => _recorder.isRecording();

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final svc = RecordingService();
  ref.onDispose(svc.dispose);
  return svc;
});
