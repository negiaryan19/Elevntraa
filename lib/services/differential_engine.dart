import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// A single differential-diagnosis suggestion returned by the engine.
class DifferentialMatch {
  final String name;
  final String icdCode;
  final String icdDescription;
  final String reason;
  final List<String> matchedSymptoms;
  final String? redFlag;
  final double score;
  final String category;

  const DifferentialMatch({
    required this.name,
    required this.icdCode,
    required this.icdDescription,
    required this.reason,
    required this.matchedSymptoms,
    this.redFlag,
    required this.score,
    required this.category,
  });

  /// True when the rule carries a clinical red-flag escalation note.
  bool get isRedFlag => redFlag != null;
}

/// Internal representation of one rule from differential_rules.json.
class _Rule {
  final String id;
  final String category;
  final String name;
  final String icdCode;
  final String icdDescription;
  final List<String> symptoms;
  final List<String> anchorSymptoms;
  final int minSymptoms;
  final String reason;
  final String? redFlag;

  _Rule({
    required this.id,
    required this.category,
    required this.name,
    required this.icdCode,
    required this.icdDescription,
    required this.symptoms,
    required this.anchorSymptoms,
    required this.minSymptoms,
    required this.reason,
    this.redFlag,
  });

  factory _Rule.fromJson(Map<String, dynamic> json) => _Rule(
    id: json['id'] as String,
    category: json['category'] as String,
    name: json['name'] as String,
    icdCode: json['icdCode'] as String,
    icdDescription: json['icdDescription'] as String,
    symptoms: (json['symptoms'] as List).cast<String>(),
    anchorSymptoms: (json['anchorSymptoms'] as List).cast<String>(),
    minSymptoms: json['minSymptoms'] as int,
    reason: json['reason'] as String,
    redFlag: json['redFlag'] as String?,
  );
}

/// On-device differential-diagnosis engine.
///
/// Matches patient symptoms (as extracted by Gemini) against a curated,
/// clinician-validated rule table and returns ranked suggestions.
///
/// Safety guarantees:
/// - A rule only fires when at least one **anchor symptom** matches.
/// - Substring direction: the patient's symptom string must *contain* the
///   rule keyword, not the reverse (prevents generic terms satisfying
///   specific keywords like "nocturnal itching").
/// - Results are deduplicated by ICD code, keeping the highest-scoring match.
/// - Nothing auto-fills the diagnosis — the doctor accepts or ignores.
class DifferentialEngine {
  final List<_Rule> _rules;

  DifferentialEngine._(this._rules);

  /// Load from the bundled Flutter asset.
  static Future<DifferentialEngine> load() async {
    final raw = await rootBundle.loadString(
      'assets/data/differential_rules.json',
    );
    return DifferentialEngine._parse(raw);
  }

  /// Construct from a raw JSON string (for unit tests without Flutter assets).
  factory DifferentialEngine.fromJsonString(String jsonString) {
    return DifferentialEngine._parse(jsonString);
  }

  static DifferentialEngine _parse(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final rules = (json['rules'] as List)
        .map((e) => _Rule.fromJson(e as Map<String, dynamic>))
        .toList();
    return DifferentialEngine._(rules);
  }

  /// Number of loaded rules (useful for tests / diagnostics).
  int get ruleCount => _rules.length;

  /// Given a list of patient symptom strings (from Gemini extraction),
  /// return up to [maxResults] ranked differential suggestions.
  ///
  /// Returns an empty list when [patientSymptoms] is empty or no rule fires.
  List<DifferentialMatch> suggest(
    List<String> patientSymptoms, {
    int maxResults = 5,
  }) {
    if (patientSymptoms.isEmpty) return [];

    // Normalize: lowercase, trimmed, drop blanks.
    final normalized = patientSymptoms
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (normalized.isEmpty) return [];

    final matches = <DifferentialMatch>[];

    for (final rule in _rules) {
      // ── FIX 1: Anchor-symptom gate ──────────────────────────────
      // At least one anchor must be present in the patient's symptoms.
      // Direction: patient symptom CONTAINS anchor keyword (FIX 2).
      final anchorHit = rule.anchorSymptoms.any(
        (anchor) => normalized.any((ps) => ps.contains(anchor.toLowerCase())),
      );
      if (!anchorHit) continue;

      // ── FIX 2: Correct substring direction ─────────────────────
      // For every rule keyword, check whether ANY patient symptom
      // *contains* it — NOT the reverse. This prevents a short
      // patient term like "khujli" from satisfying a long rule
      // keyword like "raat ko bahut khujli".
      final matched = <String>[];
      for (final ruleSymptom in rule.symptoms) {
        final key = ruleSymptom.toLowerCase();
        for (final ps in normalized) {
          if (ps.contains(key)) {
            matched.add(ruleSymptom);
            break; // each rule symptom counted at most once
          }
        }
      }

      // Must meet the rule's minimum symptom threshold.
      if (matched.length < rule.minSymptoms) continue;

      // Score = fraction of the rule's symptom list that matched.
      final score = matched.length / rule.symptoms.length;

      matches.add(
        DifferentialMatch(
          name: rule.name,
          icdCode: rule.icdCode,
          icdDescription: rule.icdDescription,
          reason: rule.reason,
          matchedSymptoms: matched,
          redFlag: rule.redFlag,
          score: score,
          category: rule.category,
        ),
      );
    }

    // Sort by score descending (strongest match first).
    matches.sort((a, b) => b.score.compareTo(a.score));

    // ── FIX 3: Deduplicate by ICD code ───────────────────────────
    // If two rules share the same ICD code, keep the highest-scoring one.
    final seen = <String>{};
    final deduped = <DifferentialMatch>[];
    for (final m in matches) {
      if (seen.add(m.icdCode)) {
        deduped.add(m);
      }
    }

    return deduped.take(maxResults).toList();
  }
}
