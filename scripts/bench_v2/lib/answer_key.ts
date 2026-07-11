// Types + loader for rxvarta_answer_key.json (the ground-truth eval set).

export interface ExpectedMed {
  name: string;
  accept_name: string[];
  dosage: string;
  frequency: string;
  duration: string;
  timing: string;
}

export interface ExpectedInsight {
  medications: ExpectedMed[];
  followUpDays: number | null;
  icdConfidence_allowed?: (string | null)[];
  icdConfidence_required?: string | null;
  assert_medications_empty?: boolean;
  assert_icd_is_null?: boolean;
}

export type Category = "easy" | "medium" | "hard" | "trap";

export interface Script {
  id: string;
  category: Category;
  text: string;
  expected: ExpectedInsight;
  _trap_purpose?: string;
}

export interface AnswerKey {
  meta: { language: string; total_scripts: number; categories: string[] };
  scripts: Script[];
  grading_rules: Record<string, string>;
}

/** Normalize a raw expected medication (fill missing optional fields). */
function normalizeExpectedMed(raw: Record<string, unknown>): ExpectedMed {
  return {
    name: String(raw.name ?? ""),
    accept_name: Array.isArray(raw.accept_name)
      ? (raw.accept_name as unknown[]).map(String)
      : [],
    dosage: String(raw.dosage ?? ""),
    frequency: String(raw.frequency ?? ""),
    duration: String(raw.duration ?? ""),
    timing: String(raw.timing ?? ""),
  };
}

export async function loadAnswerKey(path: string): Promise<AnswerKey> {
  const raw = await Deno.readTextFile(path);
  const json = JSON.parse(raw) as Record<string, unknown>;
  const rawScripts = (json.scripts as Record<string, unknown>[]) ?? [];

  const scripts: Script[] = rawScripts.map((s) => {
    const exp = (s.expected as Record<string, unknown>) ?? {};
    const meds = (exp.medications as Record<string, unknown>[]) ?? [];
    return {
      id: String(s.id),
      category: s.category as Category,
      text: String(s.text ?? ""),
      _trap_purpose: s._trap_purpose ? String(s._trap_purpose) : undefined,
      expected: {
        medications: meds.map(normalizeExpectedMed),
        followUpDays: (exp.followUpDays as number | null) ?? null,
        icdConfidence_allowed: exp.icdConfidence_allowed as
          | (string | null)[]
          | undefined,
        icdConfidence_required: exp.icdConfidence_required as
          | string
          | null
          | undefined,
        assert_medications_empty: exp.assert_medications_empty === true,
        assert_icd_is_null: exp.assert_icd_is_null === true,
      },
    };
  });

  return {
    meta: json.meta as AnswerKey["meta"],
    scripts,
    grading_rules: (json.grading_rules as Record<string, string>) ?? {},
  };
}
