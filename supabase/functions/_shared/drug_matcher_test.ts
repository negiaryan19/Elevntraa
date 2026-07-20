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

Deno.test("case 3 — ungrounded but catalogued drug kept for review (tier b)", () => {
  // Transcript mentions no medicine at all. Azithromycin IS in our dictionary,
  // so rather than dropping it (a likely STT-grounding failure), we keep it and
  // flag needsReview so the doctor confirms. Pure inventions — not in the
  // dictionary — are still dropped (see the Zorafinib case below).
  const transcript =
    "Doctor: bukhar thoda hai, aaram karo aur paani zyada piyo, teen din mein theek ho jayega.";
  const out = validateExtraction(
    insightWith([med("Azithromycin")]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "catalogued drug kept for review");
  assertEquals(out.medications[0].name, "Azithromycin", "name preserved");
  assertEquals(
    out.medications[0].needsReview,
    true,
    "kept-for-review medicine must be flagged",
  );
});

Deno.test("case 4 — dollo recognized but NOT rewritten", () => {
  const out = validateExtraction(
    insightWith([med("Dollo")]),
    line("Dollo"),
  );
  assertEquals(out.medications.length, 1, "dollo must be recognized/kept");
  assertEquals(out.medications[0].name, "Dollo", "dollo must NOT be rewritten");
});

// ── Real phone-test regressions (ungrounded-med handling) ──────────────────

Deno.test("bug A — split manglings 'Etra Cozol'/'Atrex' both kept", () => {
  // STT mangled Itraconazole -> "Etra Cozol" and Atarax -> "Atrex". Gemini
  // recovered the correct names; grounding must still find both via the
  // dictionary variants so neither is silently dropped.
  const transcript =
    "Doctor: Aap ko fungal infection hai. Etra Cozol 100mg subah shaam lena " +
    "aur Atrex raat ko sone se pehle lena teen hafte tak.";
  const out = validateExtraction(
    insightWith([med("Itraconazole"), med("Atarax")]),
    transcript,
  );
  const names = out.medications.map((m) => m.name);
  assertEquals(out.medications.length, 2, "both medicines must be kept");
  assertEquals(names.includes("Itraconazole"), true, "Itraconazole kept");
  assertEquals(names.includes("Atarax"), true, "Atarax (brand) kept verbatim");
});

Deno.test("bug B — 'Paracetamol (Crocin)' resolves to spoken brand Crocin", () => {
  const transcript =
    "Doctor: bukhar ke liye Crocin lena din mein do baar khana khane ke baad.";
  const out = validateExtraction(
    insightWith([med("Paracetamol (Crocin)")]),
    transcript,
  );
  assertEquals(out.medications.length, 1, "compound medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Crocin",
    "resolves to the spoken brand, kept verbatim",
  );
});

Deno.test("tier c — invented drug, not in transcript nor dictionary, dropped", () => {
  const transcript =
    "Doctor: bukhar thoda hai, aaram karo aur paani zyada piyo, teen din mein theek ho jayega.";
  const out = validateExtraction(
    insightWith([med("Zorafinib")]),
    transcript,
  );
  assertEquals(out.medications.length, 0, "pure invention must be dropped");
});

// ── Compound-name fragment filtering ──────────────────────────────────────

Deno.test("fragment — 'Amoxicillin (500 mg)' resolves to the drug, not the dose", () => {
  const out = validateExtraction(
    insightWith([med("Amoxicillin (500 mg)")]),
    "Doctor: amoxicillin 500 mg din mein do baar khana khane ke baad lena.",
  );
  assertEquals(out.medications.length, 1, "medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Amoxicillin",
    "name must be the drug, never the dose fragment",
  );
});

Deno.test("fragment — 'Amoxicillin (BD)' resolves to the drug, not the qualifier", () => {
  const out = validateExtraction(
    insightWith([med("Amoxicillin (BD)")]),
    "Doctor: amoxicillin lena, BD, khana khane ke baad paanch din tak.",
  );
  assertEquals(out.medications.length, 1, "medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Amoxicillin",
    "name must be the drug, never the 'BD' qualifier",
  );
});

Deno.test("fragment — 'Pantoprazole (Pan)' kept via tier b, named by generic", () => {
  // Transcript is mangled so the full generic never grounds, and the short
  // brand fragment "Pan" is filtered out (never becomes the name). The medicine
  // survives via tier b (catalogued) with the canonical generic name.
  const out = validateExtraction(
    insightWith([med("Pantoprazole (Pan)")]),
    "Doctor: acidity aur gas ki shikayat hai, subah khali pet ye goli lena teen din tak.",
  );
  assertEquals(out.medications.length, 1, "catalogued medicine must be kept");
  assertEquals(
    out.medications[0].name,
    "Pantoprazole",
    "name must be the generic, not the 'Pan' fragment",
  );
  assertEquals(
    out.medications[0].needsReview,
    true,
    "tier-b medicine must be flagged for review",
  );
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
