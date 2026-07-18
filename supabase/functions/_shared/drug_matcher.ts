// ── Drug Matcher ──────────────────────────────────────────────────────────
// Romanization-aware drug-name matcher. Reuses the same three-stage
// algorithm as Icd10LocalMapper (exact → substring → fuzzy at 0.82 blend)
// with an additional romanization normalization step.
//
// Two primary uses:
//   1. validateExtraction: is this drug name plausibly in the transcript?
//   2. drug-name correction: map a mangled/romanized name to canonical form.
//
// Built once, used in two places — see ADI spec.

// ── Dictionary ────────────────────────────────────────────────────────────

interface DrugEntry {
  canonical: string;
  variants: string[];
}

// Single source of truth for drug data.
// Update drug_dictionary.json (one file) when the full list lands.
import dictJson from "./drug_dictionary.json" assert { type: "json" };

const DRUG_DICTIONARY: DrugEntry[] =
  (dictJson as unknown as { entries: DrugEntry[] }).entries;

// ── Matcher ───────────────────────────────────────────────────────────────

export interface DrugMatch {
  canonical: string;
  confidence: "high" | "medium";
}

const MIN_FUZZY = 0.82;

class DrugMatcher {
  /** normalized variant → canonical name */
  private _exactIndex = new Map<string, string>();
  /** romanNorm'd variant → canonical name */
  private _romanIndex = new Map<string, string>();
  private _entries: DrugEntry[];

  constructor(entries: DrugEntry[]) {
    this._entries = entries;
    for (const entry of entries) {
      for (const v of entry.variants) {
        const n = norm(v);
        if (n.length > 0) this._exactIndex.set(n, entry.canonical);
        const r = romanNorm(v);
        if (r.length > 0) this._romanIndex.set(r, entry.canonical);
      }
      // Also index the canonical name itself
      const cn = norm(entry.canonical);
      if (cn.length > 0) this._exactIndex.set(cn, entry.canonical);
      const cr = romanNorm(entry.canonical);
      if (cr.length > 0) this._romanIndex.set(cr, entry.canonical);
    }
  }

  /**
   * Correct a (possibly mangled) drug name to its canonical form.
   * Returns null if no match above threshold.
   *
   * Three stages (mirrors Icd10LocalMapper.lookup):
   *   1. Exact match on normalized name → high
   *   2. Substring containment → high/medium
   *   3. Fuzzy (Jaccard + Levenshtein blend ≥ 0.82) → medium
   */
  correct(input: string): DrugMatch | null {
    const q = norm(input);
    if (q.length < 3) return null;

    // Stage 1: exact
    const exact = this._exactIndex.get(q);
    if (exact) return { canonical: exact, confidence: "high" };

    // Also try romanNorm for exact
    const qr = romanNorm(input);
    const romanExact = this._romanIndex.get(qr);
    if (romanExact) return { canonical: romanExact, confidence: "high" };

    // Stage 2: substring (query contains a known variant, or vice versa)
    for (const [term, canonical] of this._exactIndex.entries()) {
      if (term.length < 4 || q.length < 4) continue;
      if (q === term) continue;
      if (q.includes(term) || term.includes(q)) {
        const specific = term.length >= 6;
        return { canonical, confidence: specific ? "high" : "medium" };
      }
    }

    // Stage 3: fuzzy with romanization normalization
    let bestCanonical: string | null = null;
    let bestScore = 0;
    for (const [term, canonical] of this._romanIndex.entries()) {
      if (term.length < 3) continue;
      const score = similarity(qr, term);
      if (score > bestScore) {
        bestScore = score;
        bestCanonical = canonical;
      }
    }
    if (bestCanonical && bestScore >= MIN_FUZZY) {
      return { canonical: bestCanonical, confidence: "medium" };
    }

    return null;
  }

  /**
   * Check if a drug name (from Gemini output) is plausibly present in a
   * normalized transcript. Replaces the old _medicineFoundInTranscript +
   * hardcoded _MEDICINE_VARIANTS approach.
   *
   * Returns the canonical name if matched, or null if the drug is not
   * grounded in the transcript.
   */
  findInTranscript(
    drugName: string,
    transcriptNorm: string,
  ): { found: boolean; canonical: string | null } {
    const nameNorm = norm(drugName);
    // Too short to cross-reference reliably — keep it.
    if (nameNorm.length < 4) return { found: true, canonical: null };

    // Direct normalized substring in transcript
    if (transcriptNorm.includes(nameNorm)) {
      return { found: true, canonical: null };
    }

    // Check every known variant of every drug that matches this name
    const match = this.correct(drugName);
    if (match) {
      // We know which drug this is — check if ANY of its variants appear
      // in the transcript
      const entry = this._entries.find((e) => e.canonical === match.canonical);
      if (entry) {
        for (const v of entry.variants) {
          if (transcriptNorm.includes(norm(v))) {
            return { found: true, canonical: match.canonical };
          }
        }
        // Also check canonical name itself
        if (transcriptNorm.includes(norm(entry.canonical))) {
          return { found: true, canonical: match.canonical };
        }
      }
    }

    // Leading-prefix tolerance (transliteration may truncate)
    for (let k = nameNorm.length; k >= 4; k--) {
      if (transcriptNorm.includes(nameNorm.slice(0, k))) {
        return { found: true, canonical: match?.canonical ?? null };
      }
    }

    // Fuzzy: check if any dictionary variant is close to any word cluster
    // in the transcript. This catches romanized forms the dictionary doesn't
    // explicitly list.
    const nameRoman = romanNorm(drugName);
    if (nameRoman.length >= 4) {
      // Slide a window over the transcript looking for fuzzy matches
      for (let i = 0; i <= transcriptNorm.length - 4; i++) {
        const windowLen = Math.min(
          nameRoman.length + 3,
          transcriptNorm.length - i,
        );
        const window = transcriptNorm.slice(i, i + windowLen);
        if (levRatio(nameRoman, romanNorm(window)) >= MIN_FUZZY) {
          return { found: true, canonical: match?.canonical ?? null };
        }
      }
    }

    return { found: false, canonical: match?.canonical ?? null };
  }
}

// ── Singleton ─────────────────────────────────────────────────────────────

export const drugMatcher = new DrugMatcher(DRUG_DICTIONARY);
