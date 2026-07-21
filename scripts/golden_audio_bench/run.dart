/// Golden-audio end-to-end harness.
///
/// Replays real recorded consultations through the PRODUCTION backend — the
/// exact path the app uses (see lib/features/consultation/data/pipeline_service
/// .dart): authenticate → upload the audio to the `consultation-audio` bucket →
/// invoke the `process-consultation` Edge Function → await the sync result, or
/// poll `check-job-status` for the async batch path → assert the extracted
/// insight against a per-case `expected.json`.
///
/// This mirrors the structure/style of scripts/pipeline_bench (standalone Dart,
/// reads keys from the project `.env`, prints a summary table) but goes through
/// the real Supabase pipeline instead of re-implementing Sarvam/Gemini, so it
/// exercises server-side validateExtraction / drug-dictionary / prompt changes.
///
/// Deliberately uses ONLY dart:io + dart:convert (no package deps) so the
/// documented one-liner works from the repo root with no `pub get`:
///
///   dart run scripts/golden_audio_bench/run.dart
///
/// Each real API run costs money (Sarvam + Gemini). This is a MANUAL
/// pre-release gate — it is intentionally NOT wired into GitHub Actions CI.
/// See scripts/golden_audio_bench/README.md.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ── Constants ──────────────────────────────────────────────────────────────

const _defaultGoldenDir = 'test/golden_audio';
const _bucket = 'consultation-audio';
const _audioFilename = 'audio.m4a';
const _expectedFilename = 'expected.json';

const _pollInterval = Duration(seconds: 3);
const _maxPollDuration = Duration(minutes: 20);
const _httpTimeout = Duration(minutes: 5);

const _usage =
    '''
Usage: dart run scripts/golden_audio_bench/run.dart [--env <path>] [--dir <path>] [--debug]

  --env <path>   Path to the .env file with Supabase config. Defaults to
                 \$BENCH_ENV_PATH, then '.env' in the current directory.
                 Required keys: SUPABASE_URL, SUPABASE_ANON_KEY,
                 AUTO_LOGIN_EMAIL, AUTO_LOGIN_PASSWORD.
  --dir <path>   Golden-audio cases directory. Defaults to $_defaultGoldenDir.
  --debug        Print the transcript and full extracted insight per case.
                 WARNING: exposes PHI/PII in the terminal. Off by default.
''';

// ── Entry point ────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  if (opts.containsKey('help') || opts.containsKey('h')) {
    print(_usage);
    return;
  }

  final rootDir = opts['dir'] ?? _defaultGoldenDir;
  final debug = opts.containsKey('debug');

  _header('Golden Audio Harness');
  print('Cases dir : $rootDir');

  // ── Discover cases first (no network / env needed) ──────────────────────
  final discovery = _discoverCases(rootDir);
  for (final w in discovery.warnings) {
    print('  ! $w');
  }

  if (discovery.placeholders.isNotEmpty) {
    print('\nPlaceholders (no $_audioFilename yet — skipped):');
    for (final p in discovery.placeholders) {
      print('  · ${p.name}');
    }
  }

  if (discovery.runnable.isEmpty) {
    print(
      '\nNo runnable cases present '
      '(${discovery.placeholders.length} placeholder(s) skipped).',
    );
    print(
      'Add a case: drop $_audioFilename + write $_expectedFilename into a '
      'folder under $rootDir/ (see README).',
    );
    print('Nothing to run — clean exit.');
    _footer();
    // No runnable cases is not a failure — this is the empty/seed state.
    exit(0);
  }

  // ── Env + auth are only needed once we actually have audio to send ──────
  final envPath =
      opts['env'] ?? Platform.environment['BENCH_ENV_PATH'] ?? '.env';
  final env = _loadEnv(envPath);
  final supabaseUrl = _stripTrailingSlash(env['SUPABASE_URL'] ?? '');
  final anonKey = env['SUPABASE_ANON_KEY'] ?? '';
  final email = env['AUTO_LOGIN_EMAIL'] ?? '';
  final password = env['AUTO_LOGIN_PASSWORD'] ?? '';

  for (final entry in <String, String>{
    'SUPABASE_URL': supabaseUrl,
    'SUPABASE_ANON_KEY': anonKey,
    'AUTO_LOGIN_EMAIL': email,
    'AUTO_LOGIN_PASSWORD': password,
  }.entries) {
    if (entry.value.isEmpty) {
      stderr.writeln('ERROR: ${entry.key} not found in $envPath');
      exit(1);
    }
  }

  print('\nBackend  : $supabaseUrl');
  print('Runnable : ${discovery.runnable.length} case(s)');
  if (!debug) {
    print('(transcript & insight hidden — pass --debug to show)');
  }

  final http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 30);

  _Auth auth;
  try {
    print('\nAuthenticating as $email ...');
    auth = await _authenticate(http, supabaseUrl, anonKey, email, password);
    print('Authenticated (user ${auth.userId}).');
  } catch (e) {
    stderr.writeln('ERROR: authentication failed: $e');
    http.close(force: true);
    exit(1);
  }

  // ── Run each case ───────────────────────────────────────────────────────
  final results = <_CaseResult>[];
  for (final c in discovery.runnable) {
    _divider('Case: ${c.name}');
    final started = DateTime.now();
    try {
      final extraction = await _runOneCase(http, supabaseUrl, anonKey, auth, c);
      final elapsed = DateTime.now().difference(started);

      final insight = extraction.insight;
      final medNames = _medicineNames(insight);
      final failures = _assertCase(c.expected, insight);

      if (debug) {
        _printDebug(extraction.transcript, insight);
      }
      print('  Medicines expected : ${_fmtList(c.expected.mustContain)}');
      print('  Medicines got      : ${_fmtList(medNames)}');
      if (c.expected.mustNotContain.isNotEmpty) {
        print('  Must NOT contain   : ${_fmtList(c.expected.mustNotContain)}');
      }
      if (c.expected.diagnosisContains != null) {
        print('  Diagnosis          : "${insight['diagnosis'] ?? ''}"');
      }
      if (c.expected.followUpDays != null) {
        print(
          '  Follow-up days     : '
          '${insight['followUpDays']} (want ${c.expected.followUpDays})',
        );
      }

      if (failures.isEmpty) {
        print('  Result             : PASS  (${_s(elapsed)})');
      } else {
        print('  Result             : FAIL  (${_s(elapsed)})');
        for (final f in failures) {
          print('    ✗ $f');
        }
      }

      results.add(
        _CaseResult(
          name: c.name,
          elapsed: elapsed,
          expected: c.expected.mustContain,
          got: medNames,
          failures: failures,
        ),
      );
    } catch (e) {
      final elapsed = DateTime.now().difference(started);
      print('  Result             : ERROR (${_s(elapsed)})');
      print('    ✗ $e');
      results.add(
        _CaseResult(
          name: c.name,
          elapsed: elapsed,
          expected: c.expected.mustContain,
          got: const <String>[],
          failures: <String>['pipeline error: $e'],
        ),
      );
    }
  }

  http.close();

  // ── Summary table ───────────────────────────────────────────────────────
  _printTable(results);

  final failed = results.where((r) => !r.passed).length;
  print('');
  print(
    '${results.length} case(s): ${results.length - failed} passed, '
    '$failed failed.',
  );
  _footer();

  exit(failed == 0 ? 0 : 1);
}

// ── Case discovery ─────────────────────────────────────────────────────────

class _Case {
  _Case({required this.name, required this.audioPath, required this.expected});
  final String name;
  final String audioPath;
  final _Expected expected;
}

class _Placeholder {
  _Placeholder(this.name);
  final String name;
}

class _Discovery {
  _Discovery(this.runnable, this.placeholders, this.warnings);
  final List<_Case> runnable;
  final List<_Placeholder> placeholders;
  final List<String> warnings;
}

_Discovery _discoverCases(String rootPath) {
  final root = Directory(rootPath);
  final runnable = <_Case>[];
  final placeholders = <_Placeholder>[];
  final warnings = <String>[];

  if (!root.existsSync()) {
    warnings.add('cases directory not found: $rootPath');
    return _Discovery(runnable, placeholders, warnings);
  }

  final dirs = root.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final dir in dirs) {
    final name = dir.path.split(Platform.pathSeparator).last;
    final expectedFile = File('${dir.path}/$_expectedFilename');
    final audioFile = File('${dir.path}/$_audioFilename');

    if (!expectedFile.existsSync()) {
      warnings.add('$name: no $_expectedFilename — ignored');
      continue;
    }

    final _Expected expected;
    try {
      expected = _Expected.parse(
        jsonDecode(expectedFile.readAsStringSync()) as Map<String, dynamic>,
      );
    } catch (e) {
      warnings.add('$name: invalid $_expectedFilename ($e) — ignored');
      continue;
    }

    if (!audioFile.existsSync()) {
      placeholders.add(_Placeholder(name));
      continue;
    }

    runnable.add(
      _Case(name: name, audioPath: audioFile.path, expected: expected),
    );
  }

  return _Discovery(runnable, placeholders, warnings);
}

// ── Expected schema ────────────────────────────────────────────────────────

class _Expected {
  _Expected({
    required this.mustContain,
    required this.mustNotContain,
    required this.minMedicineCount,
    required this.diagnosisContains,
    required this.followUpDays,
    required this.languageCode,
  });

  final List<String> mustContain;
  final List<String> mustNotContain;
  final int? minMedicineCount;
  final String? diagnosisContains;
  final int? followUpDays;
  final String languageCode;

  static _Expected parse(Map<String, dynamic> j) {
    List<String> strList(dynamic v) =>
        (v as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    // A blank/absent string field is treated as "not asserted" (null).
    String? nonEmpty(dynamic v) {
      final s = (v as String?)?.trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return _Expected(
      mustContain: strList(j['medicines_must_contain']),
      mustNotContain: strList(j['medicines_must_not_contain']),
      minMedicineCount: (j['min_medicine_count'] as num?)?.toInt(),
      diagnosisContains: nonEmpty(j['diagnosis_contains']),
      followUpDays: (j['followUpDays'] as num?)?.toInt(),
      // Optional extra: default 'unknown' → Sarvam auto-detect (transcribe mode),
      // matching how the harness replays language-agnostic recordings.
      languageCode: nonEmpty(j['languageCode']) ?? 'unknown',
    );
  }
}

// ── Assertions (all case-insensitive; brand names matched verbatim) ─────────

List<String> _assertCase(_Expected e, Map<String, dynamic> insight) {
  final failures = <String>[];
  final names = _medicineNames(insight);
  final lower = names.map((n) => n.toLowerCase()).toList();

  // Case-insensitive substring so a brand ("Atarax") is asserted verbatim: it
  // must appear as-typed in an extracted name, never silently canonicalized to
  // a generic ("Hydroxyzine").
  bool present(String needle) {
    final q = needle.toLowerCase();
    return lower.any((n) => n.contains(q));
  }

  for (final want in e.mustContain) {
    if (!present(want)) failures.add('missing medicine "$want"');
  }
  for (final forbidden in e.mustNotContain) {
    if (present(forbidden)) {
      failures.add('forbidden medicine "$forbidden" present');
    }
  }
  if (e.minMedicineCount != null && names.length < e.minMedicineCount!) {
    failures.add(
      'medicine count ${names.length} < min_medicine_count ${e.minMedicineCount}',
    );
  }
  if (e.diagnosisContains != null) {
    final diag = (insight['diagnosis']?.toString() ?? '').toLowerCase();
    if (!diag.contains(e.diagnosisContains!.toLowerCase())) {
      failures.add(
        'diagnosis "${insight['diagnosis'] ?? ''}" does not contain '
        '"${e.diagnosisContains}"',
      );
    }
  }
  if (e.followUpDays != null) {
    final got = insight['followUpDays'];
    final gotInt = got is num ? got.toInt() : null;
    if (gotInt != e.followUpDays) {
      failures.add('followUpDays $got != expected ${e.followUpDays}');
    }
  }
  return failures;
}

List<String> _medicineNames(Map<String, dynamic> insight) {
  final meds = (insight['medications'] as List?) ?? const [];
  return meds
      .map((m) => m is Map ? (m['name']?.toString() ?? '') : m.toString())
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

// ── One case: upload → invoke → (poll) → insight ────────────────────────────

/// The two backend outputs we care about, kept together so the transcript is
/// available for --debug rendering (it rides alongside the insight in both the
/// sync and async responses).
class _Extraction {
  _Extraction(this.transcript, this.insight);
  final String transcript;
  final Map<String, dynamic> insight;
}

Future<_Extraction> _runOneCase(
  HttpClient http,
  String url,
  String anonKey,
  _Auth auth,
  _Case c,
) async {
  final bytes = await File(c.audioPath).readAsBytes();
  print(
    '  Audio    : ${c.audioPath} '
    '(${(bytes.length / 1024).toStringAsFixed(1)} KB)',
  );

  // Same storage path convention as PipelineService: <userId>/<uuid>.m4a
  final storagePath = '${auth.userId}/${_uuidV4()}.m4a';

  // Step 1 — upload to the consultation-audio bucket (create, no upsert).
  print('  Uploading to $_bucket/$storagePath ...');
  final upload = await _send(
    http,
    'POST',
    Uri.parse('$url/storage/v1/object/$_bucket/$storagePath'),
    headers: {
      'Authorization': 'Bearer ${auth.accessToken}',
      'apikey': anonKey,
      'x-upsert': 'false',
    },
    contentType: 'audio/mp4',
    body: bytes,
  );
  if (upload.status >= 300) {
    throw Exception('audio upload HTTP ${upload.status}: ${upload.body}');
  }

  // Step 2 — invoke process-consultation. We omit audioDurationSeconds (as the
  // app does when duration is unknown), which routes to the async batch path.
  print('  Invoking process-consultation ...');
  final invoke = await _send(
    http,
    'POST',
    Uri.parse('$url/functions/v1/process-consultation'),
    headers: {'Authorization': 'Bearer ${auth.accessToken}', 'apikey': anonKey},
    contentType: 'application/json',
    body: utf8.encode(
      jsonEncode({
        'audioPath': storagePath,
        'languageCode': c.expected.languageCode,
      }),
    ),
  );
  if (invoke.status != 200) {
    throw Exception(
      'process-consultation HTTP ${invoke.status}: ${invoke.body}',
    );
  }

  final data = jsonDecode(invoke.body) as Map<String, dynamic>;
  final mode = data['mode'] as String?;

  if (mode == 'sync') {
    print('  Mode     : sync');
    return _extractionOf(data);
  }
  if (mode == 'async') {
    final jobId = data['jobId'] as String;
    print('  Mode     : async (job $jobId) — polling ...');
    return _pollUntilDone(http, url, anonKey, auth, jobId);
  }
  throw Exception('unknown pipeline response mode: $mode');
}

Future<_Extraction> _pollUntilDone(
  HttpClient http,
  String url,
  String anonKey,
  _Auth auth,
  String jobId,
) async {
  final deadline = DateTime.now().add(_maxPollDuration);
  var elapsed = 0;

  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(_pollInterval);
    elapsed += _pollInterval.inSeconds;

    final poll = await _send(
      http,
      'POST',
      Uri.parse('$url/functions/v1/check-job-status'),
      headers: {
        'Authorization': 'Bearer ${auth.accessToken}',
        'apikey': anonKey,
      },
      contentType: 'application/json',
      body: utf8.encode(jsonEncode({'jobId': jobId})),
    );
    if (poll.status != 200) {
      throw Exception('check-job-status HTTP ${poll.status}: ${poll.body}');
    }

    final result = jsonDecode(poll.body) as Map<String, dynamic>;
    final status = result['status'] as String?;
    stdout.write(
      '\r    state: ${(status ?? '...').padRight(10)} '
      '(${elapsed}s elapsed)',
    );

    if (status == 'running') continue;
    stdout.write('\n');

    if (status == 'done') return _extractionOf(result);
    if (status == 'failed') {
      final err =
          result['error'] ??
          result['error_code'] ??
          result['errorMessage'] ??
          'unknown pipeline error';
      throw Exception('transcription failed: $err');
    }
    throw Exception('unexpected job status: $status');
  }

  throw Exception(
    'transcription timed out after '
    '${_maxPollDuration.inMinutes} minutes',
  );
}

_Extraction _extractionOf(Map<String, dynamic> data) {
  final insight = data['insight'];
  final Map<String, dynamic> insightMap = insight is Map<String, dynamic>
      ? insight
      : insight is Map
      ? insight.cast<String, dynamic>()
      : <String, dynamic>{};
  final transcript = data['transcript']?.toString() ?? '';
  return _Extraction(transcript, insightMap);
}

// ── Supabase auth ──────────────────────────────────────────────────────────

class _Auth {
  _Auth(this.accessToken, this.userId);
  final String accessToken;
  final String userId;
}

Future<_Auth> _authenticate(
  HttpClient http,
  String url,
  String anonKey,
  String email,
  String password,
) async {
  final res = await _send(
    http,
    'POST',
    Uri.parse('$url/auth/v1/token?grant_type=password'),
    headers: {'apikey': anonKey},
    contentType: 'application/json',
    body: utf8.encode(jsonEncode({'email': email, 'password': password})),
  );
  if (res.status != 200) {
    throw Exception('auth HTTP ${res.status}: ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final token = data['access_token'] as String?;
  final userId = (data['user'] as Map?)?['id'] as String?;
  if (token == null || userId == null) {
    throw Exception('auth response missing access_token/user id');
  }
  return _Auth(token, userId);
}

// ── HTTP helper ────────────────────────────────────────────────────────────

class _HttpResult {
  _HttpResult(this.status, this.body);
  final int status;
  final String body;
}

Future<_HttpResult> _send(
  HttpClient http,
  String method,
  Uri uri, {
  Map<String, String>? headers,
  String? contentType,
  List<int>? body,
}) async {
  final req = await http.openUrl(method, uri);
  headers?.forEach((k, v) => req.headers.set(k, v));
  if (contentType != null) req.headers.set('Content-Type', contentType);
  if (body != null) req.add(body);
  final resp = await req.close().timeout(_httpTimeout);
  final text = await resp.transform(utf8.decoder).join();
  return _HttpResult(resp.statusCode, text);
}

// ── Output ─────────────────────────────────────────────────────────────────

class _CaseResult {
  _CaseResult({
    required this.name,
    required this.elapsed,
    required this.expected,
    required this.got,
    required this.failures,
  });

  final String name;
  final Duration elapsed;
  final List<String> expected;
  final List<String> got;
  final List<String> failures;

  bool get passed => failures.isEmpty;
}

void _printTable(List<_CaseResult> results) {
  _header('Summary Table');
  const wName = 24;
  const wResult = 7;
  const wMeds = 48;

  final head =
      '${'Case'.padRight(wName)}| ${'Result'.padRight(wResult)}| '
      '${'Medicines (expected vs got)'.padRight(wMeds)}| Time';
  print(head);
  print('-' * head.length);

  for (final r in results) {
    final meds = 'exp ${_fmtList(r.expected)} → got ${_fmtList(r.got)}';
    print(
      '${_truncate(r.name, wName).padRight(wName)}| '
      '${(r.passed ? 'PASS' : 'FAIL').padRight(wResult)}| '
      '${_truncate(meds, wMeds).padRight(wMeds)}| '
      '${_s(r.elapsed)}',
    );
  }
}

/// Max transcript characters shown under --debug. A real diarized consult can
/// run several KB; 1500 chars is enough to eyeball what Sarvam heard without
/// flooding the terminal.
const _debugTranscriptLimit = 1500;

void _printDebug(String transcript, Map<String, dynamic> insight) {
  print('\n  ── Transcript (--debug) ──');
  final t = transcript.trim();
  if (t.isEmpty) {
    print('    (empty)');
  } else if (t.length <= _debugTranscriptLimit) {
    print(_indent(t));
  } else {
    print(_indent(t.substring(0, _debugTranscriptLimit)));
    print(
      '    … [truncated ${t.length - _debugTranscriptLimit} of ${t.length} '
      'chars]',
    );
  }

  print('\n  ── Insight (--debug) ──');
  print(_indent(const JsonEncoder.withIndent('  ').convert(insight)));
}

String _indent(String s) => s.split('\n').map((l) => '    $l').join('\n');

String _fmtList(List<String> xs) => xs.isEmpty ? '{}' : '{${xs.join(', ')}}';

String _truncate(String s, int w) =>
    s.length <= w ? s : '${s.substring(0, w - 1)}…';

String _s(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';

void _header(String title) {
  print('\n${'=' * 64}');
  print(title);
  print('=' * 64);
}

void _divider(String title) {
  print('\n${'─' * 64}');
  print(title);
  print('─' * 64);
}

void _footer() => print('${'=' * 64}\n');

// ── Small utilities ─────────────────────────────────────────────────────────

String _stripTrailingSlash(String s) =>
    s.endsWith('/') ? s.substring(0, s.length - 1) : s;

Map<String, String> _loadEnv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: .env file not found: $path');
    exit(1);
  }
  return _parseEnv(file.readAsStringSync());
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

/// Minimal flag parser: supports `--key value`, `--key=value`, and bare
/// boolean flags. Mirrors pipeline_bench so no extra dependency is pulled in.
Map<String, String> _parseArgs(List<String> args) {
  const valueFlags = {'env', 'dir'};
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

/// RFC-4122 v4 UUID (mirrors `Uuid().v4()` used by PipelineService for the
/// storage path). Uses a cryptographically secure RNG.
String _uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 10
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
