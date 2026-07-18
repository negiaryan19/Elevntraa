import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

/// Result of a drug-name correction attempt.
///
/// [canonical] is the standard English drug name (e.g. "Paracetamol").
/// [confidence] is "high" (exact/substring match) or "medium" (fuzzy).
/// A null result from [DrugNameCorrector.correct] means no match — keep the
/// original name and let the doctor fix it manually.
class DrugMatch {
  final String canonical;
  final String confidence; // "high" | "medium"

  const DrugMatch({required this.canonical, required this.confidence});
}

/// On-device drug-name corrector.
///
/// Maps mangled / romanized / brand-name drug strings to their canonical
/// English names using the same three-stage algorithm as [Icd10LocalMapper]:
///   1. Exact match on normalized name → high confidence
///   2. Substring containment → high / medium
///   3. Fuzzy (Jaccard + Levenshtein blend ≥ 0.82) → medium
///
/// Romanization normalization is applied before fuzzy matching so that
/// Indian-transliteration drift (th→t, ph→f, ee→i, etc.) is absorbed.
///
/// Loaded from `assets/data/drug_dictionary.json`. Register the asset in
/// pubspec.yaml:
///   assets:
///     - assets/data/drug_dictionary.json
class DrugNameCorrector {
  final List<_DrugEntry> _entries;
  final Map<String, String> _exactIndex;  // norm'd variant → canonical
  final Map<String, String> _romanIndex;  // romanNorm'd variant → canonical

  DrugNameCorrector._(this._entries, this._exactIndex, this._romanIndex);

  /// Load from the bundled asset.
  static Future<DrugNameCorrector> load({
    String assetPath = 'assets/data/drug_dictionary.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = (map['entries'] as List).cast<Map<String, dynamic>>();
    return fromJsonList(list);
  }

  /// Build directly from decoded JSON (used in tests, no rootBundle needed).
  static DrugNameCorrector fromJsonList(List<Map<String, dynamic>> list) {
    final entries = <_DrugEntry>[];
    final exact = <String, String>{};
    final roman = <String, String>{};
    for (final e in list) {
      final entry = _DrugEntry(
        canonical: e['canonical'] as String,
        variants:
            (e['variants'] as List).map((v) => v.toString()).toList(),
      );
      entries.add(entry);
      // Index canonical name + every variant
      for (final term in [entry.canonical, ...entry.variants]) {
        final n = _normalize(term);
        if (n.isNotEmpty) exact.putIfAbsent(n, () => entry.canonical);
        final r = _romanNorm(term);
        if (r.isNotEmpty) roman.putIfAbsent(r, () => entry.canonical);
      }
    }
    return DrugNameCorrector._(entries, exact, roman);
  }

  /// Correct a (possibly mangled) drug name to its canonical form.
  ///
  /// Returns null if no match above threshold — the doctor fills it manually.
  DrugMatch? correct(String input) {
    final q = _normalize(input);
    if (q.length < 3) return null;

    // Stage 1: exact match
    final exactHit = _exactIndex[q];
    if (exactHit != null) {
      return DrugMatch(canonical: exactHit, confidence: 'high');
    }
    // Also try romanNorm for exact
    final qr = _romanNorm(input);
    final romanHit = _romanIndex[qr];
    if (romanHit != null) {
      return DrugMatch(canonical: romanHit, confidence: 'high');
    }

    // Stage 2: substring containment
    for (final entry in _exactIndex.entries) {
      final term = entry.key;
      if (term.length < 4 || q.length < 4) continue;
      if (q == term) continue;
      if (q.contains(term) || term.contains(q)) {
        final specific = term.length >= 6;
        return DrugMatch(
          canonical: entry.value,
          confidence: specific ? 'high' : 'medium',
        );
      }
    }

    // Stage 3: fuzzy with romanization normalization
    String? bestCanonical;
    double bestScore = 0;
    for (final entry in _romanIndex.entries) {
      if (entry.key.length < 3) continue;
      final score = _similarity(qr, entry.key);
      if (score > bestScore) {
        bestScore = score;
        bestCanonical = entry.value;
      }
    }
    if (bestCanonical != null && bestScore >= 0.82) {
      return DrugMatch(canonical: bestCanonical, confidence: 'medium');
    }

    return null;
  }

  /// Correct all medication names in a list. Returns a new list with
  /// canonical names where a match was found; originals where not.
  ///
  /// Designed to be called right after Gemini extraction lands on-device,
  /// before the doctor sees the Review screen.
  List<Map<String, dynamic>> correctMedications(
    List<Map<String, dynamic>> medications,
  ) {
    return medications.map((med) {
      final name = med['name'] as String? ?? '';
      final match = correct(name);
      if (match != null && match.canonical != name) {
        return {
          ...med,
          'name': match.canonical,
          'originalName': name, // preserve for debugging / audit
        };
      }
      return med;
    }).toList();
  }

  // ── Normalization ─────────────────────────────────────────────────────

  static String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Romanization-aware normalization — collapses common Indian
  /// transliteration variants before fuzzy matching.
  static String _romanNorm(String s) {
    var out = _normalize(s);
    // Aspirate collapse
    out = out
        .replaceAll('ph', 'f')
        .replaceAll('th', 't')
        .replaceAll('dh', 'd')
        .replaceAll('bh', 'b')
        .replaceAll('kh', 'k')
        .replaceAll('gh', 'g')
        .replaceAll('sh', 's')
        .replaceAll('ch', 'c');
    // Vowel simplification
    out = out
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('aa', 'a');
    // Double-consonant collapse
    out = out.replaceAll(RegExp(r'(.)\1+'), r'$1');
    return out;
  }

  // ── Similarity (mirrored from Icd10LocalMapper) ───────────────────────

  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    final ta = a.split(' ').toSet();
    final tb = b.split(' ').toSet();
    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    final jaccard = union == 0 ? 0.0 : inter / union;
    final lev = _levRatio(a, b);
    final blend = (0.55 * jaccard) + (0.45 * lev);
    return math.max(blend, lev);
  }

  static double _levRatio(String a, String b) {
    final d = _levenshtein(a, b);
    final maxLen = math.max(a.length, b.length);
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

class _DrugEntry {
  final String canonical;
  final List<String> variants;
  const _DrugEntry({required this.canonical, required this.variants});
}
