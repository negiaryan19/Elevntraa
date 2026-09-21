// Re-grade saved bench runs with the CURRENT grader — no TTS, STT or Gemini
// calls, so it is free and instant.
//
// Why: results.json stores every script's extracted insight. When the grader
// changes (a new synonym, a stricter number rule), the runs already paid for
// can be judged again under the same rules instead of being re-run, and an
// old run can be compared fairly with a new one.
//
//   deno run --allow-read bin/regrade.ts results/a.json results/b.json
//   deno run --allow-read bin/regrade.ts --answer-key holdout_answer_key.json results/h.json
//   deno run --allow-read bin/regrade.ts --misses results/a.json     # list each miss
//
// Read-only: prints a table, writes nothing.

import {
  dirname,
  fromFileUrl,
  join,
} from "https://deno.land/std@0.224.0/path/mod.ts";
import { loadAnswerKey } from "../lib/answer_key.ts";
import { aggregate, type FieldKind, gradeScript } from "../lib/grader.ts";
import type { BenchSummary } from "../lib/report.ts";

const repoRoot = join(dirname(fromFileUrl(import.meta.url)), "..", "..", "..");

const args = [...Deno.args];
let answerKeyPath = join(repoRoot, "rxvarta_answer_key.json");
let showMisses = false;
const files: string[] = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--answer-key") answerKeyPath = args[++i];
  else if (args[i] === "--misses") showMisses = true;
  else files.push(args[i]);
}
if (files.length === 0) {
  console.error(
    "usage: regrade.ts [--answer-key <path>] [--misses] <results.json>...",
  );
  Deno.exit(2);
}

const key = await loadAnswerKey(answerKeyPath);
const scripts = new Map(key.scripts.map((s) => [s.id, s]));

const ORDER: FieldKind[] = [
  "medicine_name",
  "dosage",
  "frequency",
  "duration",
  "timing",
  "followUp",
  "icd",
  "trap_safety",
];

const columns: Array<
  { label: string; cells: Map<FieldKind, string>; overall: string }
> = [];

for (const file of files) {
  const summary = JSON.parse(await Deno.readTextFile(file)) as BenchSummary;
  const grades = [];
  for (const r of summary.results) {
    const script = scripts.get(r.id);
    if (!script || !r.insight) continue;
    const g = gradeScript(script, r.insight);
    grades.push(g);
    if (showMisses) {
      const lines: string[] = [];
      for (const m of g.meds) {
        const actual = r.insight.medications.find((x) =>
          x.name === m.matchedActualName
        );
        const expected = script.expected.medications.find((x) =>
          x.name === m.expectedName
        );
        for (const [field, ok] of Object.entries(m.fields)) {
          if (ok) continue;
          const exp = field === "medicine_name"
            ? m.expectedName
            : (expected as Record<string, unknown> | undefined)?.[field];
          const got = field === "medicine_name"
            ? r.insight.medications.map((x) => x.name).join(" | ")
            : (actual as Record<string, unknown> | undefined)?.[field];
          lines.push(
            `    ${field.padEnd(14)} ${m.expectedName.padEnd(24)} expected ${
              JSON.stringify(exp)
            }  got ${JSON.stringify(got)}`,
          );
        }
      }
      if (g.followUpExpected !== g.followUpActual) {
        lines.push(
          `    followUp       expected ${g.followUpExpected}  got ${g.followUpActual}`,
        );
      }
      if (g.invented.length) {
        lines.push(`    invented       ${JSON.stringify(g.invented)}`);
      }
      if (g.isTrap && g.trapPass === false) {
        lines.push(`    TRAP FAILED    ${g.trapDetail}`);
      }
      if (lines.length) {
        console.log(
          `${file.split("/").pop()} · ${r.id} (${r.category})\n${
            lines.join("\n")
          }`,
        );
      }
    }
  }
  const totals = aggregate(grades);
  const cells = new Map<FieldKind, string>();
  let correct = 0, total = 0;
  for (const k of ORDER) {
    const f = totals[k];
    cells.set(k, f.total === 0 ? "-" : `${f.correct}/${f.total}`);
    if (k !== "trap_safety" && k !== "icd") {
      correct += f.correct;
      total += f.total;
    }
  }
  columns.push({
    label: file.split("/").pop()!.replace(/\.json$/, ""),
    cells,
    overall: total === 0
      ? "-"
      : `${correct}/${total} ${Math.round((100 * correct) / total)}%`,
  });
}

const width = Math.max(14, ...columns.map((c) => c.label.length)) + 2;
console.log(
  "\n" + "field".padEnd(16) +
    columns.map((c) => c.label.padEnd(width)).join(""),
);
for (const k of ORDER) {
  console.log(
    k.padEnd(16) +
      columns.map((c) => (c.cells.get(k) ?? "-").padEnd(width)).join(""),
  );
}
console.log(
  "clinical fields ".padEnd(16) +
    columns.map((c) => c.overall.padEnd(width)).join(""),
);
console.log(
  "(clinical fields = name + dosage + frequency + duration + timing + followUp)",
);
