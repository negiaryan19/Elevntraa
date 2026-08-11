/// Standalone pipeline runner: exercises the EXACT production pipeline.
///
/// Production no longer runs Sarvam STT or Gemini extraction on-device. The app
/// (see lib/features/consultation/data/pipeline_service.dart) uploads the audio
/// to the `consultation-audio` storage bucket and invokes the deployed
/// `process-consultation` Edge Function, which runs Sarvam STT → Gemini
/// extraction server-side using supabase/functions/_shared/pipeline.ts.
///
/// This tool mirrors that path 1:1 — it authenticates with the same
/// AUTO_LOGIN credentials, uploads the audio, invokes the same Edge Function,
/// and handles the sync/async response modes exactly as the app does. It holds
/// NO copy of the Gemini prompt or schema, so it can never drift from
/// production: whatever pipeline.ts does today is what this runs.
///
/// It then prints:
///   1. the full raw transcript
///   2. the full Gemini extraction JSON (pretty-printed)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const _bucket = 'consultation-audio';
const _pollInterval = Duration(seconds: 3);
const _maxPollDuration = Duration(minutes: 20);

const _usage = '''
Usage: dart run bin/bench.dart --audio <path> [--env <path>] [options]

  --audio <path>      Path to the audio file to run through the pipeline.
                      Defaults to \$BENCH_AUDIO_PATH if set.
  --env <path>        Path to the .env file with backend credentials. Defaults
                      to \$BENCH_ENV_PATH, then '.env' in the current directory.
                      Requires: SUPABASE_URL, SUPABASE_ANON_KEY,
                      AUTO_LOGIN_EMAIL, AUTO_LOGIN_PASSWORD.
  --language <code>   Language code passed to the Edge Function. Default:
                      'unknown' (Sarvam auto-detects), matching the app.
  --duration <sec>    Audio duration in seconds. Drives server-side routing
                      (rest < 28s, batch_sync < 300s, else batch_async).
                      Omit to send null, which routes to batch_async — a valid
                      production value the app itself sends when duration is
                      unknown.
''';

// ── Entry point ────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);

  final envPath =
      opts['env'] ?? Platform.environment['BENCH_ENV_PATH'] ?? '.env';
  final audioPath = opts['audio'] ?? Platform.environment['BENCH_AUDIO_PATH'];
  final languageCode = opts['language'] ?? 'unknown';
  final durationRaw = opts['duration'];

  if (audioPath == null || audioPath.isEmpty) {
    stderr.writeln('ERROR: no audio file specified.\n');
    stderr.writeln(_usage);
    exit(64); // EX_USAGE
  }

  int? audioDurationSeconds;
  if (durationRaw != null && durationRaw.isNotEmpty) {
    audioDurationSeconds = int.tryParse(durationRaw);
    if (audioDurationSeconds == null) {
      stderr.writeln('ERROR: --duration must be an integer number of seconds.');
      exit(64);
    }
  }

  final envFile = File(envPath);
  if (!envFile.existsSync()) {
    stderr.writeln('ERROR: .env file not found: $envPath');
    exit(1);
  }

  final env = _parseEnv(envFile.readAsStringSync());
  final supabaseUrl = _trimTrailingSlash(env['SUPABASE_URL'] ?? '');
  final anonKey = env['SUPABASE_ANON_KEY'] ?? '';
  final email = env['AUTO_LOGIN_EMAIL'] ?? '';
  final password = env['AUTO_LOGIN_PASSWORD'] ?? '';

  final missing = <String>[
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (anonKey.isEmpty) 'SUPABASE_ANON_KEY',
    if (email.isEmpty) 'AUTO_LOGIN_EMAIL',
    if (password.isEmpty) 'AUTO_LOGIN_PASSWORD',
  ];
  if (missing.isNotEmpty) {
    stderr.writeln('ERROR: missing in $envPath: ${missing.join(', ')}');
    exit(1);
  }

  final audioFile = File(audioPath);
  if (!audioFile.existsSync()) {
    stderr.writeln('ERROR: Audio file not found: $audioPath');
    exit(1);
  }

  final dio = _buildDio();

  _header('Production Pipeline Run (process-consultation Edge Function)');
  print('Audio    : $audioPath');
  print('Size     : ${(audioFile.lengthSync() / 1024).toStringAsFixed(1)} KB');
  print('Backend  : $supabaseUrl');
  print('Language : $languageCode');
  print(
    'Duration : '
    '${audioDurationSeconds != null ? "$audioDurationSeconds s" : "null → batch_async"}',
  );
  print('');

  try {
    // ── 1. Authenticate (same AUTO_LOGIN creds the app uses) ───────────────
    print('[1/3] Signing in as $email ...');
    final auth = await _signIn(dio, supabaseUrl, anonKey, email, password);
    print('      OK — user ${auth.userId}');

    // ── 2. Upload audio to the consultation-audio bucket ───────────────────
    print('[2/3] Uploading audio to $_bucket ...');
    final storagePath = await _uploadAudio(
      dio,
      supabaseUrl,
      anonKey,
      auth,
      audioPath,
    );
    print('      OK — $storagePath');

    // ── 3. Invoke process-consultation, exactly like PipelineService ───────
    print('[3/3] Invoking process-consultation ...');
    final started = DateTime.now();
    final result = await _processConsultation(
      dio,
      supabaseUrl,
      anonKey,
      auth,
      audioPath: storagePath,
      languageCode: languageCode,
      audioDurationSeconds: audioDurationSeconds,
    );
    final elapsed = DateTime.now().difference(started).inMilliseconds / 1000.0;
    print('      OK — pipeline completed in ${elapsed.toStringAsFixed(1)}s');

    // ── Output ─────────────────────────────────────────────────────────────
    _header('1. Full raw transcript');
    print(result.transcript.isEmpty ? '(empty)' : result.transcript);

    _header('2. Full Gemini extraction JSON');
    print(const JsonEncoder.withIndent('  ').convert(result.insight));
    print('');
  } on DioException catch (e) {
    stderr.writeln('\nERROR: request failed — ${e.message}');
    stderr.writeln('  Status: ${e.response?.statusCode}');
    stderr.writeln('  Body  : ${e.response?.data}');
    exit(1);
  } catch (e) {
    stderr.writeln('\nERROR: $e');
    exit(1);
  } finally {
    dio.close();
  }
}

// ── Backend calls (mirror PipelineService.processConsultation) ───────────────

/// Holds the transcript plus the extracted insight returned by the pipeline.
class _InsightResult {
  const _InsightResult({required this.transcript, required this.insight});
  final String transcript;
  final Map<String, dynamic> insight;
}

class _Auth {
  const _Auth({required this.token, required this.userId});
  final String token;
  final String userId;
}

/// Password grant against Supabase GoTrue — same credentials the app auto-login
/// uses. Returns the user JWT (required by the Edge Function) and the user id
/// (used as the storage folder prefix, matching the bucket's RLS policy).
Future<_Auth> _signIn(
  Dio dio,
  String base,
  String anonKey,
  String email,
  String password,
) async {
  final res = await dio.post<Map<String, dynamic>>(
    '$base/auth/v1/token?grant_type=password',
    data: {'email': email, 'password': password},
    options: Options(
      headers: {'apikey': anonKey, 'Content-Type': 'application/json'},
      responseType: ResponseType.json,
    ),
  );
  final token = res.data?['access_token'] as String?;
  final userId = (res.data?['user'] as Map<String, dynamic>?)?['id'] as String?;
  if (token == null || userId == null) {
    throw Exception('Sign-in did not return an access token / user id.');
  }
  return _Auth(token: token, userId: userId);
}

/// Uploads the audio to `consultation-audio/<userId>/<uuid><ext>`, matching the
/// path shape PipelineService uses so the bucket's per-user RLS policy passes.
Future<String> _uploadAudio(
  Dio dio,
  String base,
  String anonKey,
  _Auth auth,
  String audioPath,
) async {
  final dot = audioPath.lastIndexOf('.');
  final ext = dot >= 0 ? audioPath.substring(dot) : '.m4a';
  final storagePath = '${auth.userId}/${_uuidV4()}$ext';
  final bytes = await File(audioPath).readAsBytes();

  final res = await dio.post<dynamic>(
    '$base/storage/v1/object/$_bucket/$storagePath',
    data: bytes,
    options: Options(
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'apikey': anonKey,
        'x-upsert': 'false',
      },
      contentType: _mimeForExt(ext),
      responseType: ResponseType.json,
    ),
  );
  if ((res.statusCode ?? 0) >= 300) {
    throw Exception('Audio upload failed (${res.statusCode}): ${res.data}');
  }
  return storagePath;
}

/// Invokes the process-consultation Edge Function and resolves the sync/async
/// response exactly as PipelineService does.
Future<_InsightResult> _processConsultation(
  Dio dio,
  String base,
  String anonKey,
  _Auth auth, {
  required String audioPath,
  required String languageCode,
  required int? audioDurationSeconds,
}) async {
  final res = await dio.post<Map<String, dynamic>>(
    '$base/functions/v1/process-consultation',
    data: {
      'audioPath': audioPath,
      'languageCode': languageCode,
      if (audioDurationSeconds != null)
        'audioDurationSeconds': audioDurationSeconds,
    },
    options: _fnOptions(anonKey, auth.token),
  );

  final data = res.data ?? <String, dynamic>{};
  final mode = data['mode'] as String?;

  if (mode == 'sync') return _parseResult(data);

  if (mode == 'async') {
    final jobId = data['jobId'] as String;
    print('      async job $jobId — polling check-job-status ...');
    return _pollUntilDone(dio, base, anonKey, auth, jobId);
  }

  throw Exception('Unknown pipeline response mode: $mode ($data)');
}

Future<_InsightResult> _pollUntilDone(
  Dio dio,
  String base,
  String anonKey,
  _Auth auth,
  String jobId,
) async {
  final deadline = DateTime.now().add(_maxPollDuration);
  var elapsed = 0;

  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(_pollInterval);
    elapsed += _pollInterval.inSeconds;

    final poll = await dio.post<Map<String, dynamic>>(
      '$base/functions/v1/check-job-status',
      data: {'jobId': jobId},
      options: _fnOptions(anonKey, auth.token),
    );

    final result = poll.data ?? <String, dynamic>{};
    final status = result['status'] as String?;

    stdout.write('\r      state: ${(status ?? '...').padRight(10)} (${elapsed}s)');

    if (status == 'running') continue;

    if (status == 'done') {
      print('');
      return _parseResult(result);
    }

    if (status == 'failed') {
      print('');
      throw Exception(
        'Pipeline failed: ${result['error'] ?? 'Unknown pipeline error'}',
      );
    }

    print('');
    throw Exception('Unexpected job status: $status');
  }

  throw Exception('Transcription timed out after 20 minutes.');
}

_InsightResult _parseResult(Map<String, dynamic> data) {
  final transcript = data['transcript'] as String? ?? '';
  final insight = (data['insight'] as Map<String, dynamic>?) ?? {};
  return _InsightResult(transcript: transcript, insight: insight);
}

Options _fnOptions(String anonKey, String token) => Options(
  headers: {
    'Authorization': 'Bearer $token',
    'apikey': anonKey,
    'Content-Type': 'application/json',
  },
  responseType: ResponseType.json,
);

// ── Dio setup ────────────────────────────────────────────────────────────────

Dio _buildDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
    // Don't throw on non-2xx so we can surface the backend's JSON error body.
    validateStatus: (_) => true,
  ),
);

// ── Utilities ────────────────────────────────────────────────────────────────

/// Minimal flag parser: supports `--key value`, `--key=value`, and bare
/// boolean flags. Avoids pulling in an extra dependency.
Map<String, String> _parseArgs(List<String> args) {
  const valueFlags = {'env', 'audio', 'language', 'duration'};
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final body = arg.substring(2);
    final eq = body.indexOf('=');
    if (eq >= 0) {
      map[body.substring(0, eq)] = body.substring(eq + 1);
    } else if (valueFlags.contains(body) && i + 1 < args.length) {
      map[body] = args[++i];
    } else {
      map[body] = '';
    }
  }
  return map;
}

Map<String, String> _parseEnv(String raw) {
  final map = <String, String>{};
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 0) continue;
    map[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }
  return map;
}

String _trimTrailingSlash(String s) =>
    s.endsWith('/') ? s.substring(0, s.length - 1) : s;

String _mimeForExt(String ext) {
  switch (ext.toLowerCase()) {
    case '.mp3':
      return 'audio/mpeg';
    case '.m4a':
    case '.mp4':
      return 'audio/mp4';
    case '.wav':
      return 'audio/wav';
    case '.ogg':
      return 'audio/ogg';
    default:
      return 'application/octet-stream';
  }
}

/// RFC 4122 version-4 UUID using a cryptographically secure RNG — avoids adding
/// the `uuid` package for a single call.
String _uuidV4() {
  final rnd = Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10xx
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

void _header(String title) {
  print('\n${'=' * 64}');
  print(title);
  print('=' * 64);
}
