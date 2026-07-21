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

// ── Devanagari transliteration ────────────────────────────────────────────
// Sarvam now returns consultation transcripts in Devanagari script. Both norm()
// and romanNorm() strip every non-[a-z0-9] byte, which would erase Devanagari
// text entirely — every drug name, brand, and vernacular phrase would fail to
// ground. We therefore transliterate Devanagari to a Latin phonetic form FIRST,
// so grounding and variant matching compare like-for-like (क्रोसिन → "krosin",
// तीन दिन → "teendin"). Already-romanized (pure-Latin) transcripts contain no
// Devanagari code points, so this is a fast no-op for them.

const _DEVA_VOWELS: Record<string, string> = {
  "अ": "a",
  "आ": "aa",
  "इ": "i",
  "ई": "ee",
  "उ": "u",
  "ऊ": "oo",
  "ऋ": "ri",
  "ए": "e",
  "ऐ": "ai",
  "ओ": "o",
  "औ": "au",
  "ऍ": "e",
  "ऑ": "o",
  "ॲ": "a",
};

const _DEVA_MATRAS: Record<string, string> = {
  "ा": "aa",
  "ि": "i",
  "ी": "ee",
  "ु": "u",
  "ू": "oo",
  "ृ": "ri",
  "े": "e",
  "ै": "ai",
  "ो": "o",
  "ौ": "au",
  "ॉ": "o",
  "ॅ": "e",
};

const _DEVA_CONSONANTS: Record<string, string> = {
  "क": "k",
  "ख": "kh",
  "ग": "g",
  "घ": "gh",
  "ङ": "ng",
  "च": "ch",
  "छ": "chh",
  "ज": "j",
  "झ": "jh",
  "ञ": "ny",
  "ट": "t",
  "ठ": "th",
  "ड": "d",
  "ढ": "dh",
  "ण": "n",
  "त": "t",
  "थ": "th",
  "द": "d",
  "ध": "dh",
  "न": "n",
  "प": "p",
  "फ": "ph",
  "ब": "b",
  "भ": "bh",
  "म": "m",
  "य": "y",
  "र": "r",
  "ल": "l",
  "व": "v",
  "ळ": "l",
  "श": "sh",
  "ष": "sh",
  "स": "s",
  "ह": "h",
};

const _DEVA_DIGITS: Record<string, string> = {
  "०": "0",
  "१": "1",
  "२": "2",
  "३": "3",
  "४": "4",
  "५": "5",
  "६": "6",
  "७": "7",
  "८": "8",
  "९": "9",
};

const _DEVA_VIRAMA = "्";
const _DEVA_NASAL = new Set(["ं", "ँ"]); // anusvara / chandrabindu → n
const _DEVA_VISARGA = "ः";

function _isDevanagari(ch: string | undefined): boolean {
  if (ch === undefined) return false;
  const c = ch.codePointAt(0) ?? 0;
  return c >= 0x0900 && c <= 0x097f;
}

// Word-final inherent schwa is dropped ("दिन" → "din", not "dina"). A schwa is
// word-final when the next char is absent, whitespace/punctuation, or a
// non-Devanagari letter (a code-mixed boundary).
function _isDevaWordEnd(ch: string | undefined): boolean {
  if (ch === undefined) return true;
  if (/\s/.test(ch)) return true;
  return !_isDevanagari(ch);
}

/**
 * Transliterate Devanagari to a Latin phonetic approximation. Handles the
 * abugida's inherent-'a' rule (consonant carries an implicit vowel), vowel
 * signs (matras), the virama (conjunct/half-consonant), nasalization, and
 * word-final schwa deletion. Non-Devanagari characters pass through unchanged,
 * so mixed and pure-Latin strings survive intact.
 */
export function transliterateDevanagari(input: string): string {
  // Fast path: nothing to do for already-romanized (pure-Latin) text.
  let hasDeva = false;
  for (const ch of input) {
    if (_isDevanagari(ch)) {
      hasDeva = true;
      break;
    }
  }
  if (!hasDeva) return input;

  const chars = Array.from(input);
  const out: string[] = [];
  for (let i = 0; i < chars.length; i++) {
    const ch = chars[i];
    const cons = _DEVA_CONSONANTS[ch];
    if (cons !== undefined) {
      const next = chars[i + 1];
      if (next === _DEVA_VIRAMA) {
        out.push(cons); // conjunct: inherent vowel suppressed
      } else if (next !== undefined && _DEVA_MATRAS[next] !== undefined) {
        out.push(cons); // vowel supplied by the following matra
      } else if (_isDevaWordEnd(next)) {
        out.push(cons); // word-final schwa deletion
      } else {
        out.push(cons + "a"); // inherent 'a'
      }
      continue;
    }
    const matra = _DEVA_MATRAS[ch];
    if (matra !== undefined) {
      out.push(matra);
      continue;
    }
    const vowel = _DEVA_VOWELS[ch];
    if (vowel !== undefined) {
      out.push(vowel);
      continue;
    }
    const digit = _DEVA_DIGITS[ch];
    if (digit !== undefined) {
      out.push(digit);
      continue;
    }
    if (_DEVA_NASAL.has(ch)) {
      out.push("n");
      continue;
    }
    if (ch === _DEVA_VISARGA) {
      out.push("h");
      continue;
    }
    if (ch === _DEVA_VIRAMA) continue; // consumed via look-ahead above
    out.push(ch); // non-Devanagari passthrough (incl. nukta, dropped by norm)
  }
  return out.join("");
}

// ── Normalization ─────────────────────────────────────────────────────────

/** Transliterate Devanagari, then strip to lowercase alphanumeric only. */
function norm(s: string): string {
  return transliterateDevanagari(s).toLowerCase().replace(/[^a-z0-9]/g, "");
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
  /** Every distinct brand string across the dictionary (correctly spelled). */
  private _brands: string[] = [];
  private _entries: DrugEntry[];

  constructor(entries: DrugEntry[]) {
    this._entries = entries;
    const seenBrand = new Set<string>();
    for (const entry of entries) {
      for (const b of entry.brands) {
        const bn = norm(b);
        if (bn.length > 0 && !seenBrand.has(bn)) {
          seenBrand.add(bn);
          this._brands.push(b);
        }
      }
    }
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
   * Is this name a drug our dictionary knows at all (exact / substring / fuzzy),
   * regardless of the brand-guard? Used by validateExtraction's middle tier: a
   * catalogued drug that Gemini reported but grounding couldn't locate is far
   * more likely an STT-grounding failure than an invention, so it is kept for
   * doctor review rather than silently dropped.
   */
  isKnownDrug(input: string): boolean {
    return this._recognize(input) !== null;
  }

  /**
   * Is this name an EXACT known spelling — a generic, variant, or brand exactly
   * as catalogued (normalized or romanization-normalized)? Used to decide
   * whether a name still needs brand-spelling correction: a correctly-spelled
   * brand ("Crocin", "Candid") is left alone; a mangled one ("azithrol") is not
   * exact and is routed to `correctToBrand`.
   */
  isExactTerm(input: string): boolean {
    const n = norm(input);
    if (n.length > 0 && this._exactIndex.has(n)) return true;
    const r = romanNorm(input);
    return r.length > 0 && this._romanIndex.has(r);
  }

  /**
   * FIX 2b — Brand-spelling correction. A mangled brand the doctor spoke
   * ("azithrol", "azithrol") that never matched a generic variant is
   * fuzzy-compared (romanization-aware) against every catalogued brand. On a
   * ≥0.82 hit it returns the correctly-spelled brand ("Azithral"); otherwise
   * null so the caller keeps the name verbatim.
   */
  correctToBrand(input: string): string | null {
    const qr = romanNorm(input);
    if (qr.length < 4) return null;
    let best: string | null = null;
    let bestScore = 0;
    for (const brand of this._brands) {
      const score = similarity(qr, romanNorm(brand));
      if (score > bestScore) {
        bestScore = score;
        best = brand;
      }
    }
    return bestScore >= MIN_FUZZY ? best : null;
  }

  /**
   * FIX 2a — Spoken-brand reverse lookup. Given a medicine name that resolved to
   * a generic (or was kept for review), check whether any brand of that name's
   * dictionary entry is actually present in the transcript (romanization-aware).
   * Returns the correctly-spelled brand or null. Restores the brand the doctor
   * actually spoke when Gemini normalized it to the generic — doctor said
   * "Candid" → we print "Candid", not "Clotrimazole".
   *
   * `spoken` is the raw (space-preserving) transcript, used for the word-join
   * fuzzy pass, exactly as in findInTranscript.
   */
  brandInTranscript(
    drugName: string,
    transcriptNorm: string,
    spoken?: string,
  ): string | null {
    const m = this._recognize(drugName);
    if (!m) return null;

    const words = spoken
      ? spoken.split(/\s+/).map((w) => norm(w)).filter((w) => w.length > 0)
      : [];

    for (const brand of m.entry.brands) {
      const bn = norm(brand);
      if (bn.length < 3) continue;
      // Direct: the brand spelling is present in the normalized transcript.
      if (transcriptNorm.includes(bn)) return brand;
      // Romanization-aware fuzzy: match each spoken word, and each pair of
      // consecutive words joined, so a split/romanized brand still grounds.
      const br = romanNorm(brand);
      for (let i = 0; i < words.length; i++) {
        if (
          words[i].length >= 3 &&
          levRatio(br, romanNorm(words[i])) >= MIN_FUZZY
        ) {
          return brand;
        }
        if (i + 1 < words.length) {
          const joined = words[i] + words[i + 1];
          if (levRatio(br, romanNorm(joined)) >= MIN_FUZZY) return brand;
        }
      }
    }
    return null;
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
   *
   * `spoken` is the raw (space-preserving) transcript. It is optional and used
   * only for the word-join fuzzy pass: the normalized transcript has no word
   * boundaries, so split manglings ("etra cozol") are recovered by joining two
   * consecutive spoken words ("etracozol") and fuzzy-comparing to the name.
   */
  findInTranscript(
    drugName: string,
    transcriptNorm: string,
    spoken?: string,
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

    // Word-join fuzzy: the normalized transcript is one unspaced blob, so a
    // char-window that straddles a split mangling drags in trailing tokens
    // ("etracozol100mg") and dilutes the ratio. Using the spoken text we can
    // fuzzy-match each spoken word AND each pair of consecutive words joined,
    // recovering split manglings ("etra cozol" -> "etracozol") cleanly.
    if (spoken && nameRoman.length >= 4) {
      const words = spoken
        .split(/\s+/)
        .map((w) => norm(w))
        .filter((w) => w.length > 0);
      for (let i = 0; i < words.length; i++) {
        if (
          words[i].length >= 4 &&
          levRatio(nameRoman, romanNorm(words[i])) >= MIN_FUZZY
        ) {
          return { found: true, canonical };
        }
        if (i + 1 < words.length) {
          const joined = words[i] + words[i + 1];
          if (levRatio(nameRoman, romanNorm(joined)) >= MIN_FUZZY) {
            return { found: true, canonical };
          }
        }
      }
    }

    return { found: false, canonical };
  }
}

// ── Singleton ─────────────────────────────────────────────────────────────

export const drugMatcher = new DrugMatcher(DRUG_DICTIONARY);
