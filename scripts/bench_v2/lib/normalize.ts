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
  "thrice daily": "tds",
  "three times daily": "tds",
  "3 times a day": "tds",
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
  // The extraction prompt itself asks for this exact phrase; punctuation is
  // stripped before lookup, so "as needed (SOS)" arrives as "as needed sos".
  "as needed sos": "prn",
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

  // Absorb minor STT/formatting drift on the raw normalized strings — but
  // never in the numbers. One edit separates "5 days" from "3 days", "5 ml"
  // from "2 ml" and "1 tablet" from "2 tablet", and this fallback used to pass
  // all three: the wrong-number error, the one a prescription eval exists to
  // catch, was the one it forgave. The numbers must agree exactly; only the
  // words around them may drift ("5ml" / "5 ml", "tablet" / "tablets").
  const ne = numberWords(normalize(expected));
  const na = numberWords(normalize(actual));
  if (ne === na) return true;
  if (numbersIn(ne) !== numbersIn(na)) return false;
  return levenshtein(ne, na) <= 1;
}

const NUMBER_WORDS: Record<string, string> = {
  one: "1",
  two: "2",
  three: "3",
  four: "4",
  five: "5",
  six: "6",
  seven: "7",
  eight: "8",
  nine: "9",
  ten: "10",
};

/** "two drops" -> "2 drops", so a spelled-out count compares as a number. */
function numberWords(s: string): string {
  return s.split(" ").map((w) => NUMBER_WORDS[w] ?? w).join(" ");
}

/** Every number in [s], in order: "250 mg 5 ml" -> "250,5". */
function numbersIn(s: string): string {
  return (s.match(/\d+(?:\.\d+)?/g) ?? []).join(",");
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
  // A strength that is present and wrong is never a match. Without this,
  // "Dolo 500" passed for "Dolo 650" (two edits), and "Azithromycin 501" — a
  // mis-heard "500 ek tablet" — passed through the bare alias "azithromycin".
  // A name with NO strength still matches: the key's aliases allow that.
  const expectedNumbers = numbersIn(normalize(candidates[0] ?? ""));
  const actualNumbers = numbersIn(na);
  if (
    expectedNumbers !== "" && actualNumbers !== "" &&
    expectedNumbers !== actualNumbers
  ) {
    return false;
  }
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
