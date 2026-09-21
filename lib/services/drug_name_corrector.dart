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
  final Map<String, int> _exactIndex; // norm'd generic/variant/brand → entry ix
  final Map<String, int> _romanIndex; // romanNorm'd term → entry index

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
    final exact = <String, int>{};
    final roman = <String, int>{};
    for (final e in list) {
      final entry = _DrugEntry(
        generic: e['generic'] as String,
        brands: (e['brands'] as List? ?? const [])
            .map((v) => v.toString())
            .toList(),
        variants: (e['variants'] as List? ?? const [])
            .map((v) => v.toString())
            .toList(),
      );
      final ix = entries.length;
      entries.add(entry);
      // Index generic + variants + brands for RECOGNITION/grounding. The
      // brand-guard in [correct] decides separately whether a match may be
      // rewritten to the generic. First-write wins (putIfAbsent).
      for (final term in [entry.generic, ...entry.variants, ...entry.brands]) {
        final n = _normalize(term);
        if (n.isNotEmpty) exact.putIfAbsent(n, () => ix);
        final r = _romanNorm(term);
        if (r.isNotEmpty) roman.putIfAbsent(r, () => ix);
      }
    }
    return DrugNameCorrector._(entries, exact, roman);
  }

  /// Recognize which entry an input best corresponds to (recognition only — no
  /// brand-guard), using the same three stages as [correct] describes. Returns
  /// the entry index + confidence, or null if nothing matches above threshold.
  ({int idx, String confidence})? _recognize(String input) {
    final q = _normalize(input);
    if (q.length < 3) return null;

    // Stage 1: exact match
    final exactHit = _exactIndex[q];
    if (exactHit != null) return (idx: exactHit, confidence: 'high');
    final qr = _romanNorm(input);
    final romanHit = _romanIndex[qr];
    if (romanHit != null) return (idx: romanHit, confidence: 'high');

    // Stage 2: containment, restricted so it can only strip noise or finish a
    // truncation. It must never turn one molecule into a different one.
    //   * The dictionary term appears as a whole word in the input
    //     ("tab paracetamol 500mg" -> Paracetamol).
    //   * Or the input is a truncated start of the term
    //     ("amoxicil" -> Amoxicillin).
    // A term buried inside a longer word is rejected: "levocetirizine"
    // contains "cetirizine" and "escitalopram" contains "citalopram", and
    // both are different drugs.
    final tokens = _tokens(input);
    for (final entry in _exactIndex.entries) {
      final term = entry.key;
      if (term.length < 4 || q.length < 4) continue;
      if (q == term) continue;
      final wholeWord = _containsAsWholeWords(tokens, term);
      final truncation = term.startsWith(q) && q.length >= 5;
      if (wholeWord || truncation) {
        final specific = term.length >= 6;
        return (idx: entry.value, confidence: specific ? 'high' : 'medium');
      }
    }

    // Stage 3: fuzzy with romanization normalization
    int? bestIdx;
    double bestScore = 0;
    for (final entry in _romanIndex.entries) {
      if (entry.key.length < 3) continue;
      final score = _similarity(qr, entry.key);
      if (score > bestScore) {
        bestScore = score;
        bestIdx = entry.value;
      }
    }
    if (bestIdx != null && bestScore >= 0.82) {
      return (idx: bestIdx, confidence: 'medium');
    }

    return null;
  }

  /// Brand-guard: variants exist for RECOGNITION only, so a recognized input is
  /// rewritten to the generic ONLY when it is a plain (mis)spelling of the
  /// generic — not a brand and not a romanized look-alike of one. Returns true
  /// when [input] must be LEFT AS-IS because it is (or resembles) a brand of
  /// [entry]. e.g. "crocin" (exact brand) and "dollo" (romanNorm → "dolo", a
  /// brand) both return true; "parcetamol" returns false so it corrects.
  bool _isBrandLike(String input, _DrugEntry entry) {
    final qn = _normalize(input);
    for (final b in entry.brands) {
      if (_normalize(b) == qn) return true;
    }
    final qr = _romanNorm(input);
    for (final b in entry.brands) {
      if (_similarity(qr, _romanNorm(b)) >= 0.82) return true;
    }
    return false;
  }

  /// Correct a (possibly mangled) drug name to its canonical generic form.
  ///
  /// Returns null when there is no confident match OR when the brand-guard says
  /// the input is a brand (or brand look-alike) that must be kept verbatim —
  /// the doctor fills / keeps it manually.
  DrugMatch? correct(String input) {
    // A product naming two or more ingredients is kept exactly as dictated,
    // unless the whole string is itself a known product. Rewriting it to one
    // molecule silently deletes the other ingredient from the prescription.
    if (_isCombination(input) && !_exactIndex.containsKey(_normalize(input))) {
      return null;
    }
    // Doctors dictate the strength with the name ("Telma 40", "Metformin
    // 500", "Propranolol 10 mg"). Matching the whole string made the brand
    // guard miss ("telma40" is not the brand "telma"), so Telma 40 was
    // rewritten to plain "Telmisartan": the brand and the strength both
    // vanished from the prescription. The name is matched without its
    // strength, and the strength is put back on whatever comes out.
    final (:name, :strength) = _splitStrength(input);
    if (name.isEmpty) return null; // "500", "650 mg": not a medicine
    final m = _recognize(name);
    if (m == null) return null;
    final entry = _entries[m.idx];
    // Recognized, but a brand / brand look-alike: keep the original name.
    if (_isBrandLike(name, entry)) return null;
    return DrugMatch(
      canonical: strength.isEmpty
          ? entry.generic
          : '${entry.generic} $strength',
      confidence: m.confidence,
    );
  }

  /// A strength at the end of a name, as dictated: "625", "10 mg", "10mg",
  /// "0.5 mg", "250 mg/5 ml". It must follow whitespace, so a number that is
  /// part of a word ("B12", "D3") is never taken for one.
  static final RegExp _trailingStrength = RegExp(
    r'\s+(\d+(?:\.\d+)?\s*(?:mg|mcg|g|gm|ml|iu|%)?'
    r'(?:\s*/\s*\d+(?:\.\d+)?\s*(?:mg|mcg|g|ml))?)\s*$',
    caseSensitive: false,
  );
  static final RegExp _onlyStrength = RegExp(
    r'^\s*\d+(?:\.\d+)?\s*(?:mg|mcg|g|gm|ml|iu|%)?\s*$',
    caseSensitive: false,
  );

  /// Splits "Metformin 500" into the name and the strength exactly as it was
  /// dictated. [name] is empty when the input is nothing but a strength.
  static ({String name, String strength}) _splitStrength(String input) {
    if (_onlyStrength.hasMatch(input)) {
      return (name: '', strength: input.trim());
    }
    final m = _trailingStrength.firstMatch(input);
    if (m == null) return (name: input, strength: '');
    return (
      name: input.substring(0, m.start).trim(),
      strength: m.group(1)!.trim(),
    );
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

  // ── Combination and word-boundary guards ─────────────────────────────

  /// Lower-case alphanumeric words of [input], keeping word boundaries that
  /// [_normalize] throws away.
  static List<String> _tokens(String input) => input
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// True when [term] (already normalized, so spaces removed) equals a run of
  /// one or more consecutive whole words of the input. Multi-word generics
  /// such as "clavulanic acid" are matched across the word boundary.
  static bool _containsAsWholeWords(List<String> tokens, String term) {
    for (var start = 0; start < tokens.length; start++) {
      final buffer = StringBuffer();
      for (var end = start; end < tokens.length; end++) {
        buffer.write(tokens[end]);
        final joined = buffer.toString();
        if (joined == term) return true;
        if (joined.length >= term.length) break;
      }
    }
    return false;
  }

  /// True when [input] names more than one ingredient: an explicit
  /// combination separator, or two different dictionary drugs appearing as
  /// whole words.
  bool _isCombination(String input) {
    if (RegExp(r'[+/&]').hasMatch(input)) return true;
    final tokens = _tokens(input);
    final found = <int>{};
    for (final entry in _exactIndex.entries) {
      if (entry.key.length < 4) continue;
      if (_containsAsWholeWords(tokens, entry.key)) {
        found.add(entry.value);
        if (found.length > 1) return true;
      }
    }
    return false;
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
    out = out.replaceAll('ee', 'i').replaceAll('oo', 'u').replaceAll('aa', 'a');
    // Double-consonant collapse ("dollo" -> "dolo"). Must use replaceAllMapped:
    // String.replaceAll treats the replacement literally, so r'$1' inserted the
    // text "$1" instead of the captured char, silently breaking double-letter
    // names (and the brand-guard's "dollo" case).
    out = out.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m.group(1)!);
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
  final String generic;
  final List<String> brands;
  final List<String> variants;
  const _DrugEntry({
    required this.generic,
    required this.brands,
    required this.variants,
  });
}
