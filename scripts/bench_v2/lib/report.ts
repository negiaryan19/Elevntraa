// Renders the eval report: colored console output, results.json (raw), and
// report.md (screenshot-ready). Trap failures are shown in RED — that is the
// headline safety signal.

import type { FieldKind, FieldScore, ScriptGrade } from "./grader.ts";
import { aggregate } from "./grader.ts";
import type { ConsultCost } from "./cost.ts";
import type { MedicalInsight } from "./pipeline_runner.ts";

export interface RunTiming {
  sttMs: number;
  geminiMs: number;
  totalMs: number;
}

export interface ScriptResult {
  id: string;
  category: string;
  status: "ok" | "error";
  error?: string;
  routing?: string;
  ttsCached?: boolean;
  ttsWallSeconds?: number;
  ttsChars?: number;
  audioSeconds?: number;
  runs: RunTiming[];
  grade?: ScriptGrade;
  cost?: ConsultCost;
  transcript?: string;
  insight?: MedicalInsight;
}

export interface BenchSummary {
  results: ScriptResult[];
  ttsTotalInr: number;
  dryRun: boolean;
  startedAt: string;
}

// ── ANSI colors (console only) ──────────────────────────────────────────────
const C = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  cyan: "\x1b[36m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
};

const FIELD_ORDER: FieldKind[] = [
  "medicine_name",
  "dosage",
  "frequency",
  "duration",
  "timing",
  "followUp",
  "icd",
  "trap_safety",
];

const FIELD_LABEL: Record<FieldKind, string> = {
  medicine_name: "Medicine name",
  dosage: "Dosage",
  frequency: "Frequency",
  duration: "Duration",
  timing: "Timing",
  followUp: "Follow-up",
  icd: "ICD",
  trap_safety: "Trap safety",
};

function pct(score: FieldScore): string {
  if (score.total === 0) return "—";
  return `${((score.correct / score.total) * 100).toFixed(0)}%`;
}

function errPct(score: FieldScore): string {
  if (score.total === 0) return "—";
  return `${(((score.total - score.correct) / score.total) * 100).toFixed(0)}%`;
}

// ── Latency stats ───────────────────────────────────────────────────────────
export interface LatencyStat {
  min: number;
  median: number;
  p95: number;
}

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const idx = Math.min(
    sorted.length - 1,
    Math.max(0, Math.ceil((p / 100) * sorted.length) - 1),
  );
  return sorted[idx];
}

function statOf(values: number[]): LatencyStat {
  const sorted = [...values].sort((a, b) => a - b);
  return {
    min: sorted[0] ?? 0,
    median: percentile(sorted, 50),
    p95: percentile(sorted, 95),
  };
}

function collectLatency(results: ScriptResult[]): {
  stt: LatencyStat;
  gemini: LatencyStat;
  total: LatencyStat;
} {
  const stt: number[] = [];
  const gem: number[] = [];
  const tot: number[] = [];
  for (const r of results) {
    for (const run of r.runs) {
      stt.push(run.sttMs);
      gem.push(run.geminiMs);
      tot.push(run.totalMs);
    }
  }
  return { stt: statOf(stt), gemini: statOf(gem), total: statOf(tot) };
}

const s = (ms: number) => `${(ms / 1000).toFixed(2)}s`;

// ── Cost aggregation ────────────────────────────────────────────────────────
function avgCost(results: ScriptResult[]): ConsultCost {
  const ok = results.filter((r) => r.cost);
  if (ok.length === 0) return { sttInr: 0, geminiInr: 0, totalInr: 0 };
  const sum = ok.reduce(
    (acc, r) => ({
      sttInr: acc.sttInr + r.cost!.sttInr,
      geminiInr: acc.geminiInr + r.cost!.geminiInr,
      totalInr: acc.totalInr + r.cost!.totalInr,
    }),
    { sttInr: 0, geminiInr: 0, totalInr: 0 },
  );
  return {
    sttInr: sum.sttInr / ok.length,
    geminiInr: sum.geminiInr / ok.length,
    totalInr: sum.totalInr / ok.length,
  };
}

// ── Console report ──────────────────────────────────────────────────────────
export function printConsole(summary: BenchSummary): void {
  const { results } = summary;
  const grades = results
    .filter((r) => r.grade)
    .map((r) => r.grade!);
  const agg = aggregate(grades);
  const lat = collectLatency(results);
  const cost = avgCost(results);

  const line = (n = 64) => "─".repeat(n);
  console.log(`\n${C.bold}${"═".repeat(64)}`);
  console.log(
    `RxVarta Eval Harness — bench_v2${
      summary.dryRun ? "  (DRY RUN — no real API calls)" : ""
    }`,
  );
  console.log(`${"═".repeat(64)}${C.reset}`);

  // Per-field accuracy
  console.log(`\n${C.bold}Per-field accuracy${C.reset}`);
  console.log(line());
  for (const k of FIELD_ORDER) {
    const sc = agg[k];
    if (sc.total === 0 && k !== "trap_safety") continue;
    const acc = pct(sc);
    const color = sc.total === 0
      ? C.dim
      : sc.correct === sc.total
      ? C.green
      : C.yellow;
    console.log(
      `  ${FIELD_LABEL[k].padEnd(16)} ${color}${
        `${sc.correct}/${sc.total}`.padEnd(8)
      } ${acc.padStart(4)}${C.reset}`,
    );
  }

  // Trap safety (headline)
  console.log(`\n${C.bold}Trap safety (headline)${C.reset}`);
  console.log(line());
  const traps = results.filter((r) => r.grade?.isTrap);
  for (const r of traps) {
    const g = r.grade!;
    const passed = g.trapPass === true;
    const color = passed ? C.green : C.red;
    const mark = passed ? "PASS" : "FAIL";
    console.log(
      `  ${
        r.id.padEnd(12)
      } ${color}${C.bold}${mark}${C.reset} ${color}${g.trapDetail}${C.reset}`,
    );
  }

  // Errors
  const errors = results.filter((r) => r.status === "error");
  if (errors.length > 0) {
    console.log(`\n${C.bold}${C.red}Errors${C.reset}`);
    console.log(line());
    for (const r of errors) {
      console.log(`  ${C.red}${r.id.padEnd(12)} ${r.error}${C.reset}`);
    }
  }

  // Latency
  console.log(
    `\n${C.bold}Latency (across ${
      results.reduce((n, r) => n + r.runs.length, 0)
    } runs)${C.reset}`,
  );
  console.log(line());
  console.log(
    `  ${"".padEnd(10)} ${"min".padStart(8)} ${"median".padStart(8)} ${
      "p95".padStart(8)
    }`,
  );
  const latRow = (label: string, st: LatencyStat) =>
    console.log(
      `  ${label.padEnd(10)} ${s(st.min).padStart(8)} ${
        s(st.median).padStart(8)
      } ${s(st.p95).padStart(8)}`,
    );
  latRow("STT", lat.stt);
  latRow("Gemini", lat.gemini);
  latRow("Total", lat.total);

  // Cost
  console.log(`\n${C.bold}Cost per consultation (estimated ₹)${C.reset}`);
  console.log(line());
  console.log(`  STT     ₹${cost.sttInr.toFixed(3)}`);
  console.log(`  Gemini  ₹${cost.geminiInr.toFixed(3)}`);
  console.log(`  ${C.bold}Total   ₹${cost.totalInr.toFixed(3)}${C.reset}`);

  console.log(`\n${C.bold}${C.cyan}${summaryLine(summary)}${C.reset}\n`);
}

// ── One-line summary ────────────────────────────────────────────────────────
export function summaryLine(summary: BenchSummary): string {
  const { results } = summary;
  const grades = results.filter((r) => r.grade).map((r) => r.grade!);
  const agg = aggregate(grades);

  // Overall per-field accuracy = correct fields / total fields (excl. trap).
  let correct = 0, total = 0;
  for (const k of FIELD_ORDER) {
    if (k === "trap_safety") continue;
    correct += agg[k].correct;
    total += agg[k].total;
  }
  const accuracy = total === 0 ? 0 : (correct / total) * 100;

  const traps = grades.filter((g) => g.isTrap);
  const trapFails = traps.filter((g) => g.trapPass === false).length;
  const hallucinations = trapFails;

  const lat = collectLatency(results);
  const cost = avgCost(results);
  const n = results.filter((r) => r.status === "ok").length;

  return (
    `${n} scripts, per-field accuracy ${accuracy.toFixed(0)}%, ` +
    `${hallucinations} hallucination${hallucinations === 1 ? "" : "s"} on ` +
    `trap cases, median latency ${(lat.total.median / 1000).toFixed(1)}s, ` +
    `₹${cost.totalInr.toFixed(2)}/consult.`
  );
}

// ── Markdown report ─────────────────────────────────────────────────────────
export function renderMarkdown(summary: BenchSummary): string {
  const { results } = summary;
  const grades = results.filter((r) => r.grade).map((r) => r.grade!);
  const agg = aggregate(grades);
  const lat = collectLatency(results);
  const cost = avgCost(results);
  const totalRuns = results.reduce((n, r) => n + r.runs.length, 0);

  const md: string[] = [];
  md.push("# RxVarta Eval Report — bench_v2");
  md.push("");
  md.push(`_Generated: ${summary.startedAt}_`);
  if (summary.dryRun) {
    md.push("");
    md.push(
      "> ⚠️ **DRY RUN** — no real TTS/STT/Gemini calls were made. Numbers are " +
        "illustrative and exist to demonstrate the report format and grader.",
    );
  }
  md.push("");
  md.push(`**${summaryLine(summary)}**`);
  md.push("");

  // Trap safety FIRST — it is the headline safety metric.
  md.push("## 🛡️ Trap safety (headline)");
  md.push("");
  md.push("| Script | Correctly refused? | Result |");
  md.push("| --- | --- | --- |");
  for (const r of results.filter((x) => x.grade?.isTrap)) {
    const g = r.grade!;
    const passed = g.trapPass === true;
    const detail = g.trapDetail.replace(/\|/g, "\\|");
    md.push(
      `| \`${r.id}\` | ${
        passed ? "✅ yes — " + detail : "🔴 **NO** — " + detail
      } | ${passed ? "**PASS**" : "🔴 **FAIL**"} |`,
    );
  }
  const trapFails =
    grades.filter((g) => g.isTrap && g.trapPass === false).length;
  md.push("");
  md.push(
    trapFails === 0
      ? "✅ **Zero hallucinations on trap cases.**"
      : `🔴 **${trapFails} trap failure(s) — the app invented content it should have withheld.**`,
  );
  md.push("");

  // Per-field accuracy
  md.push("## 📊 Per-field accuracy");
  md.push("");
  md.push("| Field | Correct / Total | Accuracy | Error rate |");
  md.push("| --- | --- | --- | --- |");
  for (const k of FIELD_ORDER) {
    const sc = agg[k];
    if (sc.total === 0 && k !== "trap_safety") continue;
    md.push(
      `| ${FIELD_LABEL[k]} | ${sc.correct}/${sc.total} | ${pct(sc)} | ${
        errPct(sc)
      } |`,
    );
  }
  md.push("");

  // Latency
  md.push(`## ⏱️ Latency (${totalRuns} pipeline runs)`);
  md.push("");
  md.push("| Stage | Min | Median | p95 |");
  md.push("| --- | --- | --- | --- |");
  md.push(
    `| STT | ${s(lat.stt.min)} | ${s(lat.stt.median)} | ${s(lat.stt.p95)} |`,
  );
  md.push(
    `| Gemini | ${s(lat.gemini.min)} | ${s(lat.gemini.median)} | ${
      s(lat.gemini.p95)
    } |`,
  );
  md.push(
    `| **Total** | **${s(lat.total.min)}** | **${s(lat.total.median)}** | **${
      s(lat.total.p95)
    }** |`,
  );
  md.push("");

  // Cost
  md.push("## 💰 Cost per consultation (estimated ₹)");
  md.push("");
  md.push("| Component | ₹ / consult |");
  md.push("| --- | --- |");
  md.push(`| Sarvam STT | ₹${cost.sttInr.toFixed(3)} |`);
  md.push(`| Gemini extraction | ₹${cost.geminiInr.toFixed(3)} |`);
  md.push(`| **Total** | **₹${cost.totalInr.toFixed(3)}** |`);
  md.push("");
  md.push(
    `_TTS generation (one-time, test input): ₹${
      summary.ttsTotalInr.toFixed(2)
    } for all scripts. Cost figures are estimates — see \`lib/cost.ts\` to adjust rates._`,
  );
  md.push("");

  // Per-script detail
  md.push("## 🔍 Per-script detail");
  md.push("");
  for (const r of results) {
    md.push(`### \`${r.id}\` — ${r.category}`);
    if (r.status === "error") {
      md.push(`- 🔴 **ERROR:** ${r.error}`);
      md.push("");
      continue;
    }
    const g = r.grade!;
    md.push(
      `- routing: \`${r.routing}\`  ·  audio: ${
        (r.audioSeconds ?? 0).toFixed(1)
      }s  ·  followUp expected/actual: ${g.followUpExpected}/${g.followUpActual}` +
        `  ·  ICD: ${g.icdActual ?? "null"} (${g.icdConfidenceActual ?? "—"})`,
    );
    if (g.meds.length > 0) {
      md.push("");
      md.push(
        "  | Expected med | Matched | name | dosage | freq | duration | timing |",
      );
      md.push("  | --- | --- | :-: | :-: | :-: | :-: | :-: |");
      const mark = (b: boolean | undefined) =>
        b === undefined ? "·" : b ? "✅" : "❌";
      for (const m of g.meds) {
        md.push(
          `  | ${m.expectedName} | ${m.matchedActualName ?? "—"} | ${
            mark(m.fields.medicine_name)
          } | ${mark(m.fields.dosage)} | ${mark(m.fields.frequency)} | ${
            mark(m.fields.duration)
          } | ${mark(m.fields.timing)} |`,
        );
      }
    }
    if (g.invented.length > 0) {
      md.push("");
      md.push(
        `  - ${g.isTrap ? "🔴" : "⚠️"} invented med(s) not in answer key: ${
          g.invented.join(", ")
        }`,
      );
    }
    md.push("");
  }

  return md.join("\n");
}

export async function writeOutputs(
  summary: BenchSummary,
  resultsDir: string,
): Promise<{ jsonPath: string; mdPath: string }> {
  await Deno.mkdir(resultsDir, { recursive: true });
  const jsonPath = `${resultsDir}/results.json`;
  const mdPath = `${resultsDir}/report.md`;

  await Deno.writeTextFile(jsonPath, JSON.stringify(summary, null, 2));
  await Deno.writeTextFile(mdPath, renderMarkdown(summary));
  return { jsonPath, mdPath };
}
