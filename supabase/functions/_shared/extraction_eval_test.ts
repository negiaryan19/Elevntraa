// Eval cases distilled from the real-audio field test. They exercise the
// post-extraction path (validateExtraction) plus the Devanagari transliteration
// that grounding depends on, since Sarvam returns transcripts in Devanagari.
//
// Under the simplified pipeline the server keeps every medicine Gemini returned,
// exactly as returned, and never rewrites or drops one — it only raises the
// needsReview flag when a name is neither grounded nor recognized. These tests
// guard that grounding/recognition (and its Devanagari support) still work, so a
// legitimately spoken medicine is kept and not spuriously flagged.
//
// Run: deno test --allow-read supabase/functions/_shared/extraction_eval_test.ts

import {
  assertEquals,
  assertNotEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  type MedicalInsight,
  type Medication,
  validateExtraction,
} from "./pipeline.ts";
import { transliterateDevanagari } from "./drug_matcher.ts";

function med(name: string, over: Partial<Medication> = {}): Medication {
  return {
    name,
    dosage: "",
    frequency: "",
    duration: "",
    timing: "",
    needsReview: false,
    ...over,
  };
}

function insightWith(meds: Medication[], diagnosis = ""): MedicalInsight {
  return {
    consultationSummary: "",
    symptoms: [],
    diagnosis,
    differentials: [],
    medications: meds,
    tests: [],
    advice: [],
    instructions: [],
    followUpDays: null,
    doctorNotes: "",
    icdCode: null,
    icdDescription: null,
    icdConfidence: null,
  };
}

// ── Transliteration: grounding transliterates before comparing ───────────────
// Without transliteration, _norm() strips every Devanagari byte and the
// transcript normalizes to the empty string — every medicine would be
// ungrounded (and therefore spuriously flagged). These assertions prove the
// transliteration step exists and feeds grounding.

Deno.test("transliteration — Devanagari maps to a Latin phonetic form", () => {
  assertEquals(transliterateDevanagari("डोलो"), "dolo");
  assertEquals(transliterateDevanagari("क्रोसिन"), "krosin");
  // Word-final schwa is dropped; matras carry the vowels.
  assertStringIncludes(transliterateDevanagari("तीन दिन"), "teen");
  assertStringIncludes(transliterateDevanagari("तीन दिन"), "din");
  // Pure-Latin input is returned unchanged (fast no-op path).
  assertEquals(transliterateDevanagari("Crocin 650"), "Crocin 650");
});

// The Latin fast-path must be a byte-for-byte passthrough: any string with no
// Devanagari code point (U+0900–U+097F) is returned exactly as given — same
// case, punctuation, and digits. This guards the perf skip against ever
// mutating Latin input, which is the vast majority of comparisons.
Deno.test("transliteration — Latin-only input is byte-identical passthrough", () => {
  for (
    const s of [
      "",
      "Paracetamol",
      "AZITHRAL 500 MG",
      "Dolo-650, twice daily!",
      "b-complex (multivitamin)",
      "café", // non-ASCII but non-Devanagari — still untouched
    ]
  ) {
    assertEquals(transliterateDevanagari(s), s);
  }
  // A mixed string transliterates only the Devanagari run; the Latin bytes
  // survive unchanged around it.
  assertEquals(transliterateDevanagari("Take डोलो now"), "Take dolo now");
});

Deno.test("Devanagari drug grounds via romanized variant — kept, not flagged", () => {
  // The generic "Paracetamol" never appears in the transcript; it grounds only
  // because the VARIANT "dolo" matches the transliterated डोलो. Grounding must
  // transliterate first, otherwise this would be flagged for review. The name is
  // kept exactly as Gemini returned it (no rewrite to the spoken brand).
  const transcript = "Doctor: बुखार के लिए डोलो ६५० दिन में दो बार लें।";
  const out = validateExtraction(insightWith([med("Paracetamol")]), transcript);
  assertEquals(out.medications.length, 1, "Devanagari medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Paracetamol",
    "kept exactly as returned",
  );
  assertEquals(
    out.medications[0].needsReview,
    false,
    "grounded via variant -> not flagged",
  );
});

// ── Fields Gemini placed are preserved verbatim (no clearing) ────────────────

Deno.test("Devanagari 'Crocin twice daily, 3 days' — fields preserved untouched", () => {
  const transcript = "Doctor: क्रोसिन एक टैबलेट दिन में दो बार, तीन दिन।";
  const out = validateExtraction(
    insightWith([
      med("Crocin", { frequency: "twice daily", duration: "3 days" }),
    ]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "Crocin must be kept");
  assertEquals(out.medications[0].name, "Crocin", "spoken name preserved");
  assertEquals(
    out.medications[0].needsReview,
    false,
    "recognized -> not flagged",
  );
  // The server never rewrites fields — whatever Gemini placed stays.
  assertEquals(out.medications[0].frequency, "twice daily", "frequency kept");
  assertEquals(out.medications[0].duration, "3 days", "duration kept");
});

// ── Category must never replace the spoken product ───────────────────────────

Deno.test("B-Complex stays B-Complex, never Multivitamins", () => {
  const transcript =
    "Doctor: kamzori ke liye B-Complex lena roz subah khana khane ke baad.";
  const out = validateExtraction(insightWith([med("B-Complex")]), transcript);
  assertEquals(out.medications.length, 1, "medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "B-Complex",
    "spoken product preserved",
  );
  assertNotEquals(
    out.medications[0].name,
    "Multivitamins",
    "category must never replace the product",
  );
});

// ── Distractor-heavy transcript still keeps the real medicine ────────────────

Deno.test("one clear medicine amid unrelated talk is not dropped", () => {
  const transcript =
    "Speaker: kal match dekha? TV pe news chal rahi thi, phone bhi baj raha tha. " +
    "Doctor: haan haan, dekho bukhar ke liye Crocin 650 din mein do baar teen " +
    "din lena. Patient: theek hai doctor sahab, dhanyavaad.";
  const out = validateExtraction(
    insightWith([med("Crocin", { dosage: "650mg", frequency: "twice daily" })]),
    transcript,
  );
  assertNotEquals(out.medications.length, 0, "extraction must not be empty");
  assertEquals(out.medications[0].name, "Crocin", "the real medicine survives");
  assertEquals(
    out.medications[0].needsReview,
    false,
    "grounded -> not flagged",
  );
});
