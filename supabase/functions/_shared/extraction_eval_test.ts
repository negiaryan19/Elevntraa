// Eval cases distilled from the 12-run real-audio field test. These exercise
// the post-extraction path (validateExtraction) plus the Devanagari
// transliteration that grounding and variant matching now depend on, since
// Sarvam returns transcripts in Devanagari script.
//
// The prompt-side behaviour (Gemini placing frequency/duration/timing in the
// structured fields, keeping the exact spoken drug name, and extracting from a
// distractor-heavy transcript) is enforced by the hardened system instructions
// in pipeline.ts; these tests guard the deterministic post-processing that runs
// on Gemini's output.
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

// ── Transliteration: grounding + variant matching transliterate before compare ─
// Without transliteration, _norm() strips every Devanagari byte and the
// transcript normalizes to the empty string — every medicine would be
// ungrounded. These assertions prove the transliteration step exists and feeds
// grounding.

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

Deno.test("transliteration — Devanagari drug grounds via romanized variant", () => {
  // The generic "Paracetamol" never appears in the transcript; the medicine can
  // only ground because the VARIANT "dolo" matches the transliterated डोलो. If
  // variant matching did not transliterate first, this would be dropped.
  const transcript = "Doctor: बुखार के लिए डोलो ६५० दिन में दो बार लें।";
  const out = validateExtraction(insightWith([med("Paracetamol")]), transcript);
  assertEquals(out.medications.length, 1, "Devanagari medicine must be kept");
  // FIX 2a then restores the spoken brand present in the transcript.
  assertEquals(out.medications[0].name, "Dolo", "spoken brand Dolo restored");
});

// ── Case 1 — Devanagari Crocin, frequency + duration land in fields ──────────

Deno.test("case 1 — Devanagari 'Crocin twice daily, 3 days' keeps fields", () => {
  const transcript = "Doctor: क्रोसिन एक टैबलेट दिन में दो बार, तीन दिन।";
  const out = validateExtraction(
    insightWith([
      med("Crocin", { frequency: "twice daily", duration: "3 days" }),
    ]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "Crocin must be kept");
  assertEquals(out.medications[0].name, "Crocin", "spoken name preserved");
  // The suspicious-default guard must NOT clear these — they are grounded in the
  // Devanagari transcript via transliteration ("दो बार" -> twice, "तीन दिन" -> 3
  // days).
  assertEquals(
    out.medications[0].frequency,
    "twice daily",
    "grounded frequency kept in field",
  );
  assertEquals(
    out.medications[0].duration,
    "3 days",
    "grounded duration kept in field",
  );
});

// ── Case 2 — Gemini normalized brand -> spoken brand restored ────────────────

Deno.test("case 2 — Candid normalized to Clotrimazole resolves back to Candid", () => {
  const transcript =
    "Doctor: aapko fungal infection hai, Candid cream din mein do baar lagao.";
  const out = validateExtraction(
    insightWith([med("Clotrimazole")]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Candid",
    "must print the spoken brand, not the generic",
  );
});

// ── Case 3 — mangled brand spelling corrected ───────────────────────────────

Deno.test("case 3 — 'azithrol 500' corrects to Azithral, dosage kept", () => {
  const transcript =
    "Doctor: infection ke liye azithrol 500 lena din mein ek baar paanch din.";
  const out = validateExtraction(
    insightWith([med("azithrol", { dosage: "500mg" })]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Azithral",
    "mangled brand corrected to canonical brand",
  );
  assertStringIncludes(out.medications[0].dosage, "500", "dosage 500 kept");
});

// ── Case 4 — Devanagari generic-mangle grounds to Itraconazole ──────────────

Deno.test("case 4 — 'petra consoli 100' (Devanagari) yields Itraconazole", () => {
  // "petra consoli" is an observed STT mangle of Itraconazole (added as a
  // dictionary variant). The medicine must survive as Itraconazole whether it
  // grounds via the variant or is kept for review as a catalogued drug.
  const transcript =
    "Doctor: फंगल इन्फेक्शन के लिए petra consoli 100 mg दिन में एक बार लें।";
  const out = validateExtraction(
    insightWith([med("Itraconazole", { dosage: "100mg" })]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "medicine must be kept");
  assertEquals(out.medications[0].name, "Itraconazole", "resolves to generic");
});

// ── Case 5 — category must never replace the spoken product ──────────────────

Deno.test("case 5 — B-Complex stays B-Complex, never Multivitamins", () => {
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

// ── Case 6 — distractor-heavy transcript still extracts the medicine ─────────

Deno.test("case 6 — one clear medicine amid unrelated talk is not dropped", () => {
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
});
