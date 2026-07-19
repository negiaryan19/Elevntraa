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
  // Canonical generic name — the only value we ever REWRITE a mangled input to.
  generic: string;
  // Commercial brand names (e.g. "Crocin"). Indexed for RECOGNITION/grounding
  // but never rewritten to the generic — see the brand-guard in `correct`.
  brands: string[];
  // Spelling / romanization variants used for RECOGNITION/grounding. May include
  // brand strings too; the brand-guard keeps those from being rewritten.
  variants: string[];
}

// Single source of truth for drug data.
// Update drug_dictionary.json (one file) when the full list lands.
import dictJson from "./drug_dictionary.json" with { type: "json" };

const DRUG_DICTIONARY: DrugEntry[] =
  (dictJson as unknown as { entries: DrugEntry[] }).entries;

// ── Normalization ─────────────────────────────────────────────────────────

/** Strip to lowercase alphanumeric only. */
function norm(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, "");
}

/**
 * Romanization-aware normalization. Collapses common Indian transliteration
 * variants so "parasitamol" and "paracetamol" end up closer in edit distance.
 */
function romanNorm(s: string): string {
  let out = norm(s);
  out = out.replace(/ph/g, "f");
  out = out.replace(/th/g, "t");
  out = out.replace(/dh/g, "d");
  out = out.replace(/bh/g, "b");
  out = out.replace(/kh/g, "k");
  out = out.replace(/gh/g, "g");
  out = out.replace(/sh/g, "s");
  out = out.replace(/ch/g, "c");
  out = out.replace(/ee/g, "i");
  out = out.replace(/oo/g, "u");
  out = out.replace(/aa/g, "a");
  // Collapse runs of the same character ("dollo" -> "dolo"), mirroring the Dart
  // corrector's `(.)\1+`. This backreference had been corrupted to a literal
  // SOH byte, so doubles were never collapsed and the brand-guard's "dollo"
  // case (romanNorm must equal brand "dolo") silently failed.
  out = out.replace(/(.)\1+/g, "$1");
  return out;
}

// ── Similarity (mirrored from Icd10LocalMapper) ───────────────────────────

function levenshtein(a: string, b: string): number {
  const m = a.length, n = b.length;
  if (m === 0) return n;
  if (n === 0) return m;
  const prev = Array.from({ length: n + 1 }, (_, i) => i);
  const curr = new Array<number>(n + 1).fill(0);
  for (let i = 1; i <= m; i++) {
    curr[0] = i;
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      curr[j] = Math.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost);
    }
    for (let j = 0; j <= n; j++) prev[j] = curr[j];
  }
  return prev[n];
}

function levRatio(a: string, b: string): number {
  const d = levenshtein(a, b);
  const maxLen = Math.max(a.length, b.length);
  return maxLen === 0 ? 1.0 : 1.0 - d / maxLen;
}

function similarity(a: string, b: string): number {
  if (a === b) return 1.0;
  const ta = new Set(a.split(/\s+/).filter((w) => w.length > 0));
  const tb = new Set(b.split(/\s+/).filter((w) => w.length > 0));
  let inter = 0;
  for (const w of ta) if (tb.has(w)) inter++;
  const union = new Set([...ta, ...tb]).size;
  const jaccard = union === 0 ? 0.0 : inter / union;
  const lev = levRatio(a, b);
  const blend = 0.55 * jaccard + 0.45 * lev;
  return blend > lev ? blend : lev;
}

// ── Matcher ───────────────────────────────────────────────────────────────

export interface DrugMatch {
  canonical: string;
  confidence: "high" | "medium";
}

const MIN_FUZZY = 0.82;

class DrugMatcher {
  /** normalized generic/variant/brand → entry */
  private _exactIndex = new Map<string, DrugEntry>();
  /** romanNorm'd generic/variant/brand → entry */
  private _romanIndex = new Map<string, DrugEntry>();
  private _entries: DrugEntry[];

  constructor(entries: DrugEntry[]) {
    this._entries = entries;
    for (const entry of entries) {
      // Index generic + variants + brands for RECOGNITION/grounding. The
      // brand-guard in `correct` decides separately whether a match may be
      // rewritten to the generic. First-write wins so an earlier entry keeps
      // ownership of a shared string (mirrors the Dart loader's putIfAbsent).
      for (const term of [entry.generic, ...entry.variants, ...entry.brands]) {
        const n = norm(term);
        if (n.length > 0 && !this._exactIndex.has(n)) {
          this._exactIndex.set(n, entry);
        }
        const r = romanNorm(term);
        if (r.length > 0 && !this._romanIndex.has(r)) {
          this._romanIndex.set(r, entry);
        }
      }
    }
  }

  /**
   * Recognize which dictionary entry an input best corresponds to, using the
   * same three stages as Icd10LocalMapper.lookup. Recognition only — it does
   * NOT apply the brand-guard, so callers that ground (findInTranscript) can
   * still locate an entry from a brand string.
   *   1. Exact match on normalized name → high
   *   2. Substring containment → high/medium
   *   3. Fuzzy (Jaccard + Levenshtein blend ≥ 0.82) → medium
   */
  private _recognize(
    input: string,
  ): { entry: DrugEntry; confidence: "high" | "medium" } | null {
    const q = norm(input);
    if (q.length < 3) return null;

    // Stage 1: exact
    const exact = this._exactIndex.get(q);
    if (exact) return { entry: exact, confidence: "high" };

    const qr = romanNorm(input);
    const romanExact = this._romanIndex.get(qr);
    if (romanExact) return { entry: romanExact, confidence: "high" };

    // Stage 2: substring (query contains a known term, or vice versa)
    for (const [term, entry] of this._exactIndex.entries()) {
      if (term.length < 4 || q.length < 4) continue;
      if (q === term) continue;
      if (q.includes(term) || term.includes(q)) {
        const specific = term.length >= 6;
        return { entry, confidence: specific ? "high" : "medium" };
      }
    }

    // Stage 3: fuzzy with romanization normalization
    let bestEntry: DrugEntry | null = null;
    let bestScore = 0;
    for (const [term, entry] of this._romanIndex.entries()) {
      if (term.length < 3) continue;
      const score = similarity(qr, term);
      if (score > bestScore) {
        bestScore = score;
        bestEntry = entry;
      }
    }
    if (bestEntry && bestScore >= MIN_FUZZY) {
      return { entry: bestEntry, confidence: "medium" };
    }

    return null;
  }

  /**
   * Brand-guard: variants exist for RECOGNITION only, so a recognized input is
   * rewritten to the generic ONLY when it is a plain (mis)spelling of the
   * generic — not a brand and not a romanized look-alike of one. Returns true
   * when `input` must be LEFT AS-IS because it is (or resembles) a brand of
   * `entry`. Examples: "crocin" (exact brand) and "dollo" (romanNorm → "dolo",
   * a brand) both return true; "parcetamol" returns false so it corrects.
   */
  private _isBrandLike(input: string, entry: DrugEntry): boolean {
    const qn = norm(input);
    for (const b of entry.brands) {
      if (norm(b) === qn) return true;
    }
    const qr = romanNorm(input);
    for (const b of entry.brands) {
      if (similarity(qr, romanNorm(b)) >= MIN_FUZZY) return true;
    }
    return false;
  }

  /**
   * Correct a (possibly mangled) drug name to its canonical generic form.
   * Returns null when there is no confident match OR when the brand-guard says
   * the input is a brand (or brand look-alike) that must be kept verbatim.
   */
  correct(input: string): DrugMatch | null {
    const m = this._recognize(input);
    if (!m) return null;
    // Recognized, but a brand / brand look-alike: keep the original name.
    if (this._isBrandLike(input, m.entry)) return null;
    return { canonical: m.entry.generic, confidence: m.confidence };
  }

  /**
   * Check if a drug name (from Gemini output) is plausibly present in a
   * normalized transcript. Grounding uses generic + variants + brands, so a
   * brand mentioned in the transcript still grounds the medicine.
   *
   * `canonical` is the brand-guarded rewrite target (the generic) when the name
   * may be corrected, or null when it should be kept verbatim (brand / no
   * confident rewrite). `found` reports whether the drug is grounded at all.
   */
  findInTranscript(
    drugName: string,
    transcriptNorm: string,
  ): { found: boolean; canonical: string | null } {
    const nameNorm = norm(drugName);

    // Recognize the entry for grounding, and derive the brand-guarded rewrite.
    const m = this._recognize(drugName);
    const canonical = m && !this._isBrandLike(drugName, m.entry)
      ? m.entry.generic
      : null;

    // Too short to cross-reference reliably — keep it.
    if (nameNorm.length < 4) return { found: true, canonical };

    // Direct normalized substring in transcript
    if (transcriptNorm.includes(nameNorm)) {
      return { found: true, canonical };
    }

    // We know which drug this is — check if ANY of its generic/variant/brand
    // spellings appear in the transcript.
    if (m) {
      for (
        const term of [m.entry.generic, ...m.entry.variants, ...m.entry.brands]
      ) {
        if (transcriptNorm.includes(norm(term))) {
          return { found: true, canonical };
        }
      }
    }

    // Leading-prefix tolerance (transliteration may truncate)
    for (let k = nameNorm.length; k >= 4; k--) {
      if (transcriptNorm.includes(nameNorm.slice(0, k))) {
        return { found: true, canonical };
      }
    }

    // Fuzzy: check if the name is close to any word cluster in the transcript.
    // This catches romanized forms the dictionary doesn't explicitly list.
    const nameRoman = romanNorm(drugName);
    if (nameRoman.length >= 4) {
      for (let i = 0; i <= transcriptNorm.length - 4; i++) {
        const windowLen = Math.min(
          nameRoman.length + 3,
          transcriptNorm.length - i,
        );
        const window = transcriptNorm.slice(i, i + windowLen);
        if (levRatio(nameRoman, romanNorm(window)) >= MIN_FUZZY) {
          return { found: true, canonical };
        }
      }
    }

    return { found: false, canonical };
  }
}

// ── Singleton ─────────────────────────────────────────────────────────────

export const drugMatcher = new DrugMatcher(DRUG_DICTIONARY);
