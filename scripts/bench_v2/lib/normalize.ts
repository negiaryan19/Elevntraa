// Normalization + fuzzy matching used by the grader.
//
// The pipeline outputs English fields, but STT spelling drift and phrasing
// variety mean we must normalize before comparing. We lowercase, strip
// punctuation, and map known synonyms (Hindi phrasings, dosing shorthand like
// "BD"/"1-0-1", etc.) to a single canonical token per grading_rules in the
// answer key.

/** Levenshtein edit distance (used for medicine-name fuzzy match ≤ 2). */
export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;

  let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  let curr = new Array<number>(b.length + 1);

  for (let i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      curr[j] = Math.min(
        prev[j] + 1, // deletion
        curr[j - 1] + 1, // insertion
        prev[j - 1] + cost, // substitution
      );
    }
    [prev, curr] = [curr, prev];
  }
  return prev[b.length];
}

/** Lowercase, collapse whitespace, drop punctuation (keep digits + hyphen). */
export function normalize(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// Each map turns a normalized surface form into a canonical key. Both the
// expected value and the actual value are canonicalized; equal keys == match.
type SynonymMap = Record<string, string>;

const FREQUENCY_SYNONYMS: SynonymMap = {
  "once daily": "qd",
  "once a day": "qd",
  "once day": "qd",
  "one time a day": "qd",
  "od": "qd",
  "qd": "qd",
  "1-0-0": "qd",
  "0-0-1": "qd",
  "din mein ek baar": "qd",
  "roz": "qd",
  "daily": "qd",

  "twice a day": "bd",
  "twice daily": "bd",
  "two times a day": "bd",
  "bd": "bd",
  "bid": "bd",
  "1-0-1": "bd",
  "din mein do baar": "bd",
  "do baar": "bd",
  "subah shaam": "bd",
  "morning and evening": "bd",

  "three times a day": "tds",
  "thrice a day": "tds",
  "three times daily": "tds",
  "tds": "tds",
  "tid": "tds",
  "1-1-1": "tds",
  "din mein teen baar": "tds",
  "teen baar": "tds",

  "four times a day": "qds",
  "qds": "qds",
  "qid": "qds",

  "once a week": "weekly",
  "once weekly": "weekly",
  "weekly": "weekly",
  "hafte mein ek baar": "weekly",

  "as needed": "prn",
  "when required": "prn",
  "sos": "prn",
  "prn": "prn",
  "zaroorat padne par": "prn",
};

const DOSAGE_SYNONYMS: SynonymMap = {
  "1 tablet": "1tab",
  "one tablet": "1tab",
  "1 tab": "1tab",
  "ek tablet": "1tab",
  "1 cap": "1tab",
  "1 capsule": "1tab",
  "one capsule": "1tab",

  "2 tablets": "2tab",
  "two tablets": "2tab",
  "2 tab": "2tab",

  "1 packet": "1packet",
  "one packet": "1packet",
  "ek packet": "1packet",

  "1 sachet": "1sachet",
  "one sachet": "1sachet",

  "2 spoons": "2spoon",
  "two spoons": "2spoon",
  "do chammach": "2spoon",
  "2 tsp": "2spoon",

  "1 spoon": "1spoon",
  "one spoon": "1spoon",
};

const DURATION_SYNONYMS: SynonymMap = {
  "1 day": "1d",
  "one day": "1d",
  "2 days": "2d",
  "two days": "2d",
  "do din": "2d",
  "3 days": "3d",
  "three days": "3d",
  "teen din": "3d",
  "5 days": "5d",
  "five days": "5d",
  "paanch din": "5d",
  "7 days": "7d",
  "seven days": "7d",
  "1 week": "7d",
  "one week": "7d",
  "ek hafta": "7d",
  "10 days": "10d",
  "ten days": "10d",
  "das din": "10d",
  "15 days": "15d",
  "fifteen days": "15d",
  "pandrah din": "15d",
  "8 weeks": "8w",
  "eight weeks": "8w",
  "aath hafte": "8w",
  "1 month": "1mo",
  "one month": "1mo",
  "ek mahina": "1mo",
  "30 days": "1mo",
  "continue": "continue",
  "ongoing": "continue",
  "long term": "continue",
};

function canonical(map: SynonymMap, value: string): string {
  const norm = normalize(value);
  return map[norm] ?? norm;
}

/**
 * Compare two field values of a given kind. Returns true if they match after
 * synonym canonicalization, exact-normalized equality, or (as a last resort for
 * spelling drift) a small edit distance.
 */
export function fieldsMatch(
  kind: "frequency" | "dosage" | "duration",
  expected: string,
  actual: string,
): boolean {
  const map = kind === "frequency"
    ? FREQUENCY_SYNONYMS
    : kind === "dosage"
    ? DOSAGE_SYNONYMS
    : DURATION_SYNONYMS;

  const ce = canonical(map, expected);
  const ca = canonical(map, actual);
  if (ce === ca) return true;

  // Absorb minor STT/formatting drift on the raw normalized strings.
  const ne = normalize(expected);
  const na = normalize(actual);
  if (ne === na) return true;
  return levenshtein(ne, na) <= 1;
}

/**
 * Medicine-name match: case-insensitive against name + accept_name, fuzzy
 * (Levenshtein ≤ 2) to absorb STT spelling drift. Also accepts the case where
 * one is a leading token of the other (e.g. "Dolo 650" vs "Dolo").
 */
export function nameMatches(
  candidates: string[],
  actual: string,
): boolean {
  const na = normalize(actual);
  if (na === "") return false;
  for (const cand of candidates) {
    const nc = normalize(cand);
    if (nc === "") continue;
    if (nc === na) return true;
    if (levenshtein(nc, na) <= 2) return true;
    // Token-prefix tolerance: "dolo" matches "dolo 650" and vice-versa.
    if (na.startsWith(nc + " ") || nc.startsWith(na + " ")) return true;
  }
  return false;
}
