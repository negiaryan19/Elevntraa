// Eval for the romanization-aware drug matcher + brand-guard, exercised through
// validateExtraction (i.e. validateExtraction ON — the real post-extraction
// path). Covers the four required cases:
//   1. crocin survives unchanged (brand kept, not rewritten to the generic)
//   2. parcetamol corrects to Paracetamol (fuzzy variant → generic)
//   3. an invented medicine not in the transcript is DROPPED
//   4. dollo is recognized (kept) but NOT rewritten (romanNorm → brand "dolo")
//
// Run: deno test supabase/functions/_shared/drug_matcher_test.ts

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
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

// A doctor line long enough to clear validateExtraction's meaningful-content
// gate, with the drug name embedded verbatim.
const line = (drug: string) =>
  `Doctor: ${drug} ek tablet din mein do baar khana khane ke baad lena.`;

Deno.test("case 1 — crocin survives unchanged (brand, not rewritten)", () => {
  const out = validateExtraction(
    insightWith([med("Crocin")]),
    line("Crocin"),
  );
  assertEquals(out.medications.length, 1, "crocin must be kept");
  assertEquals(
    out.medications[0].name,
    "Crocin",
    "crocin must NOT be rewritten",
  );
});

Deno.test("case 2 — parcetamol corrects to Paracetamol", () => {
  const out = validateExtraction(
    insightWith([med("parcetamol")]),
    line("parcetamol"),
  );
  assertEquals(out.medications.length, 1, "parcetamol must be kept");
  assertEquals(
    out.medications[0].name,
    "Paracetamol",
    "must correct to generic",
  );
});

Deno.test("case 3 — invented medicine not in transcript is dropped", () => {
  // Transcript mentions no medicine at all.
  const transcript =
    "Doctor: bukhar thoda hai, aaram karo aur paani zyada piyo, teen din mein theek ho jayega.";
  const out = validateExtraction(
    insightWith([med("Azithromycin")]),
    transcript,
  );
  assertEquals(out.medications.length, 0, "invented medicine must be dropped");
});

Deno.test("case 4 — dollo recognized but NOT rewritten", () => {
  const out = validateExtraction(
    insightWith([med("Dollo")]),
    line("Dollo"),
  );
  assertEquals(out.medications.length, 1, "dollo must be recognized/kept");
  assertEquals(out.medications[0].name, "Dollo", "dollo must NOT be rewritten");
});

// Sanity: the diagnosis is intentionally kept even when ungrounded (paraphrase),
// so we don't regress item-1 behavior.
Deno.test("diagnosis kept even when ungrounded", () => {
  const out = validateExtraction(
    insightWith(
      [med("parcetamol")],
      "Viral upper respiratory infection",
    ),
    line("parcetamol"),
  );
  assertExists(out.diagnosis);
  assertEquals(out.diagnosis, "Viral upper respiratory infection");
});
