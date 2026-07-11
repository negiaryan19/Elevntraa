import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Result of a local ICD-10 lookup.
///
/// [confidence] mirrors the existing app convention: "high", "medium", or
/// null. A null [code] means NO confident match was found — the doctor fills
/// it manually, exactly like today. Nothing here is ever auto-printed on the
/// patient PDF; ICD is doctor-facing only.
class IcdMatch {
  final String? code;
  final String? description;
  final String? confidence; // "high" | "medium" | null

  const IcdMatch({this.code, this.description, this.confidence});

  static const IcdMatch none = IcdMatch();

  bool get hasMatch => code != null;
}

/// Deterministic, on-device ICD-10 lookup.
///
/// The LLM extracts the diagnosis TEXT; this class assigns the code from a
/// curated WHO ICD-10 map. No network, no model call, no guessing. If the
/// text does not resolve above threshold, it returns [IcdMatch.none].
class Icd10LocalMapper {
  final List<_IcdEntry> _entries;
  final Map<String, _IcdEntry> _exactIndex; // normalized term -> entry

  Icd10LocalMapper._(this._entries, this._exactIndex);

  /// Load from the bundled asset. Register the asset in pubspec.yaml:
  ///   assets:
  ///     - assets/data/icd10_opd_map.json
  static Future<Icd10LocalMapper> load({
    String assetPath = 'assets/data/icd10_opd_map.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = (map['entries'] as List).cast<Map<String, dynamic>>();
    return fromJsonList(list);
  }

  /// Build directly from decoded JSON (used in tests, no rootBundle needed).
  static Icd10LocalMapper fromJsonList(List<Map<String, dynamic>> list) {
    final entries = <_IcdEntry>[];
    final index = <String, _IcdEntry>{};
    for (final e in list) {
      final entry = _IcdEntry(
        code: e['code'] as String,
        name: e['name'] as String,
        description: e['description'] as String,
        synonyms: (e['synonyms'] as List).map((s) => s.toString()).toList(),
      );
      entries.add(entry);
      // exact index: canonical name + every synonym
      for (final term in [entry.name, ...entry.synonyms]) {
        final n = _normalize(term);
        if (n.isNotEmpty) index.putIfAbsent(n, () => entry);
      }
    }
    return Icd10LocalMapper._(entries, index);
  }

  /// Map a free-text diagnosis to an ICD-10 code.
  ///
  /// [minFuzzy] is the similarity threshold (0..1) below which we return no
  /// match. Default 0.82 is deliberately conservative — better to return null
  /// and let the doctor fill it than to surface a wrong code.
  IcdMatch lookup(String diagnosisText, {double minFuzzy = 0.82}) {
    final q = _normalize(diagnosisText);
    if (q.isEmpty) return IcdMatch.none;

    // 1) Exact term match -> high confidence.
    final exact = _exactIndex[q];
    if (exact != null) {
      return IcdMatch(
        code: exact.code,
        description: exact.description,
        confidence: 'high',
      );
    }

    // 2) Whole-phrase containment (query contains a known term, or vice
    //    versa) -> high if the known term is multi-word/specific, else medium.
    for (final term in _exactIndex.keys) {
      if (term.length < 4) continue; // skip tiny tokens to avoid noise
      if (q.length < 4) continue; // don't let a 1-3 char query substring-match
      if (q == term) continue;
      if (q.contains(term) || term.contains(q)) {
        final entry = _exactIndex[term]!;
        final specific = term.contains(' ') || term.length >= 6;
        return IcdMatch(
          code: entry.code,
          description: entry.description,
          confidence: specific ? 'high' : 'medium',
        );
      }
    }

    // 3) Fuzzy match against every term -> medium confidence.
    _IcdEntry? bestEntry;
    double best = 0;
    for (final entry in _entries) {
      for (final term in [entry.name, ...entry.synonyms]) {
        final t = _normalize(term);
        if (t.isEmpty) continue;
        final score = _similarity(q, t);
        if (score > best) {
          best = score;
          bestEntry = entry;
        }
      }
    }
    if (bestEntry != null && best >= minFuzzy) {
      return IcdMatch(
        code: bestEntry.code,
        description: bestEntry.description,
        confidence: 'medium',
      );
    }

    // 4) No confident match -> doctor fills it.
    return IcdMatch.none;
  }

  // ---- helpers ----

  static String _normalize(String s) {
    var out = s.toLowerCase().trim();
    // strip common diacritics so "dengue"/"déngue" collapse
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final b = StringBuffer();
    for (final ch in out.split('')) {
      final i = from.indexOf(ch);
      b.write(i == -1 ? ch : to[i]);
    }
    out = b.toString();
    // remove punctuation, collapse whitespace
    out = out.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out;
  }

  /// Similarity in [0,1]. Blends token overlap (Jaccard) with normalized
  /// Levenshtein so both "kamar dard" ~ "back pain kamar dard" and small
  /// typos ("diabetis" ~ "diabetes") score well.
  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    final ta = a.split(' ').toSet();
    final tb = b.split(' ').toSet();
    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    final jaccard = union == 0 ? 0.0 : inter / union;
    final lev = _levRatio(a, b);
    // weight token overlap a bit higher for multi-word clinical phrases
    final blend = (0.55 * jaccard) + (0.45 * lev);
    // let a strong single-token typo match ("diabetis" ~ "diabetes") through
    return blend > lev ? blend : lev;
  }

  static double _levRatio(String a, String b) {
    final d = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (d / maxLen);
  }

  static int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final prev = List<int>.generate(n + 1, (i) => i);
    final curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      for (var j = 0; j <= n; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[n];
  }
}

class _IcdEntry {
  final String code;
  final String name;
  final String description;
  final List<String> synonyms;
  const _IcdEntry({
    required this.code,
    required this.name,
    required this.description,
    required this.synonyms,
  });
}
