// ── Drug Matcher ──────────────────────────────────────────────────────────
// Romanization-aware drug-name matcher. Reuses the same three-stage
// algorithm as Icd10LocalMapper (exact → substring → fuzzy at 0.82 blend)
// with an additional romanization normalization step.
//
// Recognition/grounding only — the matcher never rewrites a drug name. The
// voice pipeline uses it as a confidence signal for the needsReview flag:
//   1. findInTranscript: is this drug name plausibly present in the transcript?
//   2. isKnownDrug: is this name catalogued in the dictionary at all?
// (The dictionary is also the data source for the typing-autocomplete feature,
// which is separate from this file.)

// ── Dictionary ────────────────────────────────────────────────────────────

interface DrugEntry {
  // Canonical generic name.
  generic: string;
  // Commercial brand names (e.g. "Crocin"), indexed for RECOGNITION/grounding.
  brands: string[];
  // Spelling / romanization variants used for RECOGNITION/grounding.
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
  // corrector's `(.)\1+`, so a doubled-letter mangling still grounds against its
  // single-letter dictionary form.
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

const MIN_FUZZY = 0.82;

// Per-entry precomputed normalizations. Built once at construction so the
// grounding scan (findInTranscript) never re-normalizes the same dictionary
// strings on every comparison.
interface PreparedEntry {
  // norm() of [generic, ...variants, ...brands] in that exact order — consumed
  // by the grounding scan in findInTranscript.
  termNorms: string[];
}

function _prepareEntry(entry: DrugEntry): PreparedEntry {
  const termNorms = [entry.generic, ...entry.variants, ...entry.brands].map(
    norm,
  );
  return { termNorms };
}

class DrugMatcher {
  /** normalized generic/variant/brand → entry */
  private _exactIndex = new Map<string, DrugEntry>();
  /** romanNorm'd generic/variant/brand → entry */
  private _romanIndex = new Map<string, DrugEntry>();
  /** entry → its precomputed normalizations (see PreparedEntry). */
  private _prepared = new Map<DrugEntry, PreparedEntry>();
  private _entries: DrugEntry[];

  constructor(entries: DrugEntry[]) {
    this._entries = entries;
    for (const entry of entries) {
      // Index generic + variants + brands for RECOGNITION/grounding. First-write
      // wins so an earlier entry keeps ownership of a shared string (mirrors the
      // Dart loader's putIfAbsent).
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
      // Precompute per-entry normalizations for the grounding scan.
      this._prepared.set(entry, _prepareEntry(entry));
    }
  }

  // Precomputed normalizations for an entry. Every dictionary entry is prepared
  // at construction; the fallback keeps the return type non-nullable and covers
  // an entry that somehow bypassed the constructor loop.
  private _prep(entry: DrugEntry): PreparedEntry {
    let prep = this._prepared.get(entry);
    if (prep === undefined) {
      prep = _prepareEntry(entry);
      this._prepared.set(entry, prep);
    }
    return prep;
  }

  /**
   * Recognize which dictionary entry an input best corresponds to, using the
   * same three stages as Icd10LocalMapper.lookup. Recognition only — it never
   * rewrites; callers that ground (findInTranscript) use it to locate an entry
   * from a generic, variant, or brand string.
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
   * Is this name a drug our dictionary knows at all (exact / substring / fuzzy)?
   * Used by the needsReview flag pass: a catalogued drug Gemini reported is
   * recognized even when it never grounds literally in the transcript, so it is
   * not flagged. A name that is neither grounded nor known is flagged for the
   * doctor to confirm — but still kept, never dropped.
   */
  isKnownDrug(input: string): boolean {
    return this._recognize(input) !== null;
  }

  /**
   * Is this drug name (from Gemini output) plausibly present in the transcript?
   * Grounding uses generic + variants + brands, so a brand mentioned in the
   * transcript still grounds the medicine. Recognition-only, no rewrite: the
   * caller uses this purely as a confidence signal for the needsReview flag.
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
  ): boolean {
    const nameNorm = norm(drugName);

    // Too short to cross-reference reliably — treat as grounded.
    if (nameNorm.length < 4) return true;

    // Direct normalized substring in transcript
    if (transcriptNorm.includes(nameNorm)) return true;

    // We know which drug this is — check if ANY of its generic/variant/brand
    // spellings appear in the transcript. Spellings are normalized once at
    // dictionary load, so this scan never re-normalizes per call.
    const m = this._recognize(drugName);
    if (m) {
      for (const termNorm of this._prep(m.entry).termNorms) {
        if (transcriptNorm.includes(termNorm)) return true;
      }
    }

    // Leading-prefix tolerance (transliteration may truncate)
    for (let k = nameNorm.length; k >= 4; k--) {
      if (transcriptNorm.includes(nameNorm.slice(0, k))) return true;
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
        if (levRatio(nameRoman, romanNorm(window)) >= MIN_FUZZY) return true;
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
          return true;
        }
        if (i + 1 < words.length) {
          const joined = words[i] + words[i + 1];
          if (levRatio(nameRoman, romanNorm(joined)) >= MIN_FUZZY) return true;
        }
      }
    }

    return false;
  }
}

// ── Singleton ─────────────────────────────────────────────────────────────

export const drugMatcher = new DrugMatcher(DRUG_DICTIONARY);
