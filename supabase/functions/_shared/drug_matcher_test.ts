// Contract tests for the simplified voice pipeline, exercised through the real
// post-extraction path (validateExtraction). The server is no longer a rewriter
// or a filter: it keeps every medicine Gemini returned, exactly as returned, and
// only raises needsReview as a confidence FLAG when a name is neither grounded in
// the transcript nor recognized in the drug dictionary. The review screen + the
// doctor are the safety gate — nothing is silently corrected or dropped here.
//
// Run: deno test supabase/functions/_shared/drug_matcher_test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  type MedicalInsight,
  type Medication,
  validateExtraction,
} from "./pipeline.ts";

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

// A doctor line long enough to hold a real consultation, with the drug name
// embedded verbatim.
const line = (drug: string) =>
  `Doctor: ${drug} ek tablet din mein do baar khana khane ke baad lena.`;

Deno.test("Terbinafine — kept as returned, recognized in dictionary, not flagged", () => {
  // The doctor said टेट्राफाइन (an STT mangle); Gemini interpreted it as the
  // generic Terbinafine. The exact name is not in the transcript, but Terbinafine
  // IS catalogued, so it is kept verbatim and NOT flagged.
  const out = validateExtraction(
    insightWith([med("Terbinafine")]),
    "Doctor: फंगल इन्फेक्शन के लिए टेट्राफाइन 250 दिन में एक बार लें।",
  );
  assertEquals(out.medications.length, 1, "kept, never dropped");
  assertEquals(
    out.medications[0].name,
    "Terbinafine",
    "kept exactly as Gemini returned it",
  );
  assertEquals(
    out.medications[0].needsReview,
    false,
    "recognized in dictionary -> not flagged",
  );
});

Deno.test("Candid — brand kept as returned, recognized, not flagged", () => {
  const out = validateExtraction(
    insightWith([med("Candid")]),
    "Doctor: aapko fungal infection hai, Candid cream din mein do baar lagao.",
  );
  assertEquals(out.medications.length, 1, "kept");
  assertEquals(out.medications[0].name, "Candid", "brand kept verbatim");
  assertEquals(
    out.medications[0].needsReview,
    false,
    "brand recognized -> not flagged",
  );
});

Deno.test("Xanadol — absent from transcript AND dictionary: KEPT but flagged", () => {
  // The anti-hallucination behaviour is now a flag, not a drop. An invented-
  // looking medicine is still shown to the doctor, just marked for review.
  const out = validateExtraction(
    insightWith([med("Xanadol")]),
    "Doctor: bukhar thoda hai, aaram karo aur paani zyada piyo, teen din mein theek ho jayega.",
  );
  assertEquals(
    out.medications.length,
    1,
    "never dropped — shown to the doctor",
  );
  assertEquals(
    out.medications[0].name,
    "Xanadol",
    "kept exactly as Gemini returned it",
  );
  assertEquals(
    out.medications[0].needsReview,
    true,
    "ungrounded + unknown -> flagged for review",
  );
});

Deno.test("Crocin — grounded brand untouched, not flagged", () => {
  const out = validateExtraction(insightWith([med("Crocin")]), line("Crocin"));
  assertEquals(out.medications.length, 1, "kept");
  assertEquals(out.medications[0].name, "Crocin", "untouched");
  assertEquals(
    out.medications[0].needsReview,
    false,
    "grounded -> not flagged",
  );
});

Deno.test("B-Complex — kept as B-Complex, never a category substitution", () => {
  const out = validateExtraction(
    insightWith([med("B-Complex")]),
    "Doctor: kamzori ke liye B-Complex lena roz subah khana khane ke baad.",
  );
  assertEquals(out.medications.length, 1, "kept");
  assertEquals(
    out.medications[0].name,
    "B-Complex",
    "spoken product preserved, never 'Multivitamins'",
  );
});

// Diagnosis is a paraphrase, not a quotation, so it is intentionally kept even
// when no word grounds in the transcript. The doctor edits it on the review
// screen.
Deno.test("diagnosis kept even when ungrounded", () => {
  const out = validateExtraction(
    insightWith([med("Crocin")], "Viral upper respiratory infection"),
    line("Crocin"),
  );
  assertEquals(out.diagnosis, "Viral upper respiratory infection");
});
