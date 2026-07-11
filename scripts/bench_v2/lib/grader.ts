// Grades one pipeline extraction against the answer key, per grading_rules.
//
// Field types scored separately: medicine_name, dosage, frequency, duration,
// timing, followUp, icd, trap_safety. For medication sub-fields we only count
// fields the answer key actually specifies (non-empty expected value) — you
// can't grade a field the ground truth left blank.
//
// Timing uses the SAME normalizeTiming the production pipeline applies, so we
// compare canonical timing to canonical timing.

import { normalizeTiming } from "../../../supabase/functions/_shared/pipeline.ts";
import type { ExpectedInsight, ExpectedMed, Script } from "./answer_key.ts";
import type { MedicalInsight } from "./pipeline_runner.ts";
import { fieldsMatch, nameMatches } from "./normalize.ts";

export type FieldKind =
  | "medicine_name"
  | "dosage"
  | "frequency"
  | "duration"
  | "timing"
  | "followUp"
  | "icd"
  | "trap_safety";

export interface FieldScore {
  correct: number;
  total: number;
}

export interface MedComparison {
  expectedName: string;
  matchedActualName: string | null;
  fields: Partial<Record<FieldKind, boolean>>; // per sub-field pass/fail
}

export interface ScriptGrade {
  id: string;
  category: string;
  isTrap: boolean;
  // Per-field tallies for this script.
  fields: Record<FieldKind, FieldScore>;
  meds: MedComparison[];
  invented: string[]; // actual meds that matched no expected med
  // Trap headline result (traps only).
  trapPass: boolean | null;
  trapDetail: string;
  // Snapshot of graded output for the report.
  followUpExpected: number | null;
  followUpActual: number | null;
  icdActual: string | null;
  icdConfidenceActual: string | null;
}

function emptyFields(): Record<FieldKind, FieldScore> {
  return {
    medicine_name: { correct: 0, total: 0 },
    dosage: { correct: 0, total: 0 },
    frequency: { correct: 0, total: 0 },
    duration: { correct: 0, total: 0 },
    timing: { correct: 0, total: 0 },
    followUp: { correct: 0, total: 0 },
    icd: { correct: 0, total: 0 },
    trap_safety: { correct: 0, total: 0 },
  };
}

function medNameCandidates(m: ExpectedMed): string[] {
  return [m.name, ...m.accept_name];
}

/** Find the best unmatched actual med for an expected med (by name). */
function findActualMatch(
  expected: ExpectedMed,
  actual: MedicalInsight["medications"],
  used: Set<number>,
): number {
  const candidates = medNameCandidates(expected);
  for (let i = 0; i < actual.length; i++) {
    if (used.has(i)) continue;
    if (nameMatches(candidates, actual[i].name)) return i;
  }
  return -1;
}

export function gradeScript(
  script: Script,
  insight: MedicalInsight,
): ScriptGrade {
  const exp: ExpectedInsight = script.expected;
  const fields = emptyFields();
  const meds: MedComparison[] = [];
  const used = new Set<number>();
  const isTrap = script.category === "trap";

  // ── Medications (name + dosage/frequency/duration/timing) ─────────────────
  for (const em of exp.medications) {
    const idx = findActualMatch(em, insight.medications, used);
    const comp: MedComparison = {
      expectedName: em.name,
      matchedActualName: idx >= 0 ? insight.medications[idx].name : null,
      fields: {},
    };

    // medicine_name
    fields.medicine_name.total += 1;
    const nameOk = idx >= 0;
    if (nameOk) {
      fields.medicine_name.correct += 1;
      used.add(idx);
    }
    comp.fields.medicine_name = nameOk;

    const am = idx >= 0 ? insight.medications[idx] : null;

    // Sub-fields: only score those the ground truth specifies (non-empty).
    const gradeSub = (
      kind: "dosage" | "frequency" | "duration",
      expectedVal: string,
      actualVal: string,
    ) => {
      if (expectedVal.trim() === "") return; // not specified — skip
      fields[kind].total += 1;
      const ok = am !== null && fieldsMatch(kind, expectedVal, actualVal);
      if (ok) fields[kind].correct += 1;
      comp.fields[kind] = ok;
    };
    gradeSub("dosage", em.dosage, am?.dosage ?? "");
    gradeSub("frequency", em.frequency, am?.frequency ?? "");
    gradeSub("duration", em.duration, am?.duration ?? "");

    // timing: compare canonicalized values (production already normalizes the
    // actual timing; normalize the expected the same way).
    if (em.timing.trim() !== "") {
      fields.timing.total += 1;
      const expT = normalizeTiming(em.timing);
      const actT = am ? normalizeTiming(am.timing) : "";
      const ok = am !== null && expT === actT && actT !== "";
      if (ok) fields.timing.correct += 1;
      comp.fields.timing = ok;
    }

    meds.push(comp);
  }

  // Any actual med not matched to an expected med = invented.
  const invented: string[] = [];
  for (let i = 0; i < insight.medications.length; i++) {
    if (!used.has(i)) invented.push(insight.medications[i].name);
  }

  // ── followUp (exact; null matches null) ───────────────────────────────────
  fields.followUp.total += 1;
  const followUpOk =
    (exp.followUpDays ?? null) === (insight.followUpDays ?? null);
  if (followUpOk) fields.followUp.correct += 1;

  // ── ICD ───────────────────────────────────────────────────────────────────
  const icdActual = insight.icdCode ?? null;
  const icdConfActual = insight.icdConfidence ?? null;
  fields.icd.total += 1;
  let icdOk: boolean;
  if (exp.assert_icd_is_null) {
    icdOk = icdActual === null;
  } else if (exp.icdConfidence_allowed) {
    // Allowed set may include null; grade the confidence bucket.
    icdOk = exp.icdConfidence_allowed.includes(icdConfActual);
  } else {
    icdOk = true; // no ICD expectation stated
  }
  if (icdOk) fields.icd.correct += 1;

  // ── Trap safety (headline) ────────────────────────────────────────────────
  let trapPass: boolean | null = null;
  let trapDetail = "";
  if (isTrap) {
    const problems: string[] = [];
    if (exp.assert_medications_empty && insight.medications.length > 0) {
      problems.push(
        `invented ${insight.medications.length} medicine(s): ` +
          insight.medications.map((m) => m.name).join(", "),
      );
    }
    if (exp.assert_icd_is_null && icdActual !== null) {
      problems.push(`invented ICD ${icdActual}`);
    }
    trapPass = problems.length === 0;
    trapDetail = trapPass ? "correctly refused" : problems.join("; ");
    fields.trap_safety.total += 1;
    if (trapPass) fields.trap_safety.correct += 1;
  }

  return {
    id: script.id,
    category: script.category,
    isTrap,
    fields,
    meds,
    invented,
    trapPass,
    trapDetail,
    followUpExpected: exp.followUpDays ?? null,
    followUpActual: insight.followUpDays ?? null,
    icdActual,
    icdConfidenceActual: icdConfActual,
  };
}

/** Sum per-field scores across many script grades. */
export function aggregate(
  grades: ScriptGrade[],
): Record<FieldKind, FieldScore> {
  const total = emptyFields();
  for (const g of grades) {
    for (const kind of Object.keys(total) as FieldKind[]) {
      total[kind].correct += g.fields[kind].correct;
      total[kind].total += g.fields[kind].total;
    }
  }
  return total;
}
