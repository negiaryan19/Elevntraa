// RxVarta automated eval harness — bench_v2.
//
// One command turns the 12 answer-key scripts into a full report card:
//   1. Synthesize audio for each script via Sarvam Bulbul TTS (cached).
//   2. Run each clip through the REAL pipeline (imported from
//      supabase/functions/_shared/pipeline.ts) N times for a latency spread.
//   3. Grade the extraction against the ground-truth answer key, per field.
//   4. Write results.json + report.md and print a console report card.
//
// Usage:
//   deno task bench                 # full run (needs SARVAM/GEMINI keys)
//   deno task dry-run               # grader/report demo, no API calls or keys
//   deno run -A bin/bench_v2.ts [--runs N] [--only script_01] [--dry-run]
//
// This is a READ-ONLY wrapper around the existing pipeline: it never modifies
// app code, STT routing, or the Gemini config.

import {
  dirname,
  fromFileUrl,
  join,
} from "https://deno.land/std@0.224.0/path/mod.ts";

import { loadAnswerKey, type Script } from "../lib/answer_key.ts";
import { loadKeys } from "../lib/env.ts";
import { generateAudio, profileFor } from "../lib/tts.ts";
import { type MedicalInsight, runPipeline } from "../lib/pipeline_runner.ts";
import { normalizeTiming } from "../../../supabase/functions/_shared/pipeline.ts";
import { gradeScript } from "../lib/grader.ts";
import { consultCost, ttsCost } from "../lib/cost.ts";
import {
  type BenchSummary,
  printConsole,
  type RunTiming,
  type ScriptResult,
  writeOutputs,
} from "../lib/report.ts";

interface Options {
  dryRun: boolean;
  runs: number;
  only: string | null;
  answerKeyPath: string | null;
}

function parseArgs(args: string[], repoRoot: string): Options {
  const opts: Options = {
    dryRun: false,
    runs: 3,
    only: null,
    answerKeyPath: null,
  };
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--dry-run") opts.dryRun = true;
    else if (a === "--runs") opts.runs = parseInt(args[++i], 10) || 3;
    else if (a.startsWith("--runs=")) {
      opts.runs = parseInt(a.split("=")[1], 10) || 3;
    } else if (a === "--only") opts.only = args[++i];
    else if (a.startsWith("--only=")) opts.only = a.split("=")[1];
    else if (a === "--answer-key") opts.answerKeyPath = args[++i];
    else if (a.startsWith("--answer-key=")) {
      opts.answerKeyPath = a.split("=")[1];
    }
  }
  opts.answerKeyPath ??= join(repoRoot, "rxvarta_answer_key.json");
  return opts;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// Parse the server-instructed back-off from a Gemini 429 body. Gemini reports
// it both as "Please retry in 46.3s" and as a RetryInfo `retryDelay: "44s"`.
// Returns milliseconds (with a small buffer), or null if not a rate-limit error.
function parseRetryAfterMs(message: string): number | null {
  const m = message.match(/retry in ([0-9.]+)s/i) ??
    message.match(/retryDelay"\s*:\s*"([0-9.]+)s/i);
  if (!m) return null;
  return Math.ceil(parseFloat(m[1]) * 1000) + 2000; // +2s safety buffer
}

// ── Retry helper: retry once, then rethrow ──────────────────────────────────
// If the failure is a rate-limit (Gemini 429), wait the server-instructed
// retryDelay before the single retry so it doesn't land in the same throttled
// window; otherwise retry immediately. Still exactly one retry, per spec.
async function withRetry<T>(fn: () => Promise<T>, label: string): Promise<T> {
  try {
    return await fn();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const waitMs = parseRetryAfterMs(msg);
    if (waitMs !== null) {
      console.error(
        `   ↻ ${label} rate-limited; waiting ${
          (waitMs / 1000).toFixed(0)
        }s before retry…`,
      );
      await sleep(waitMs);
    } else {
      console.error(`   ↻ ${label} failed once (${msg}); retrying…`);
    }
    return await fn();
  }
}

// Proactive throttle: keep consecutive pipeline runs at least this far apart so
// Gemini calls stay under the free tier's ~5 requests/minute ceiling. Each run
// already spends several seconds on STT+Gemini, so the added wait is small.
const MIN_PIPELINE_INTERVAL_MS = 15_000;
let lastPipelineStart = 0;
async function throttlePipeline(): Promise<void> {
  const elapsed = Date.now() - lastPipelineStart;
  if (lastPipelineStart !== 0 && elapsed < MIN_PIPELINE_INTERVAL_MS) {
    await sleep(MIN_PIPELINE_INTERVAL_MS - elapsed);
  }
  lastPipelineStart = Date.now();
}

// ── Dry-run mock: build a plausible, deliberately-imperfect extraction ──────
// Exercises the grader (fuzzy name match, a wrong field, trap safety) without
// any network. Traps correctly return empty/null so the safety metric is green.
function mockInsight(script: Script): MedicalInsight {
  const exp = script.expected;
  const meds = exp.medications.map((m, i) => {
    let name = m.name;
    let frequency = m.frequency;
    let timing = m.timing;
    // Inject a little realism: STT spelling drift on one name, one wrong freq,
    // one dropped timing — so the report isn't a perfect 100%.
    if (script.id === "script_01" && i === 0) name = "Krocin"; // drift (≤2)
    if (script.id === "script_01" && i === 1) frequency = "twice a day"; // wrong
    if (script.id === "script_04" && m.name.startsWith("Dolo")) timing = ""; // dropped
    return {
      name,
      dosage: m.dosage,
      frequency,
      duration: m.duration,
      timing: normalizeTiming(timing),
      needsReview: false,
    };
  });

  const isTrap = script.category === "trap";
  return {
    consultationSummary: "",
    symptoms: [],
    diagnosis: "",
    differentials: [],
    medications: meds,
    tests: [],
    advice: [],
    instructions: [],
    followUpDays: exp.followUpDays ?? null,
    doctorNotes: "",
    icdCode: isTrap ? null : "J06.9",
    icdDescription: isTrap ? null : "Acute upper respiratory infection",
    icdConfidence: isTrap ? null : "medium",
  };
}

function mockTiming(script: Script, audioSeconds: number): RunTiming[] {
  // Deterministic pseudo-latencies so the dry-run report looks realistic.
  const seed = script.id.split("").reduce((n, c) => n + c.charCodeAt(0), 0);
  const runs: RunTiming[] = [];
  for (let i = 0; i < 3; i++) {
    const jitter = ((seed + i * 37) % 11) / 10; // 0.0 – 1.0
    const sttMs = 1200 + audioSeconds * 90 + jitter * 400;
    const geminiMs = 2200 + script.expected.medications.length * 260 +
      jitter * 500;
    runs.push({ sttMs, geminiMs, totalMs: sttMs + geminiMs });
  }
  return runs;
}

// ── Main ────────────────────────────────────────────────────────────────────
async function main() {
  const scriptDir = dirname(fromFileUrl(import.meta.url)); // scripts/bench_v2/bin
  const benchDir = join(scriptDir, "..");
  const repoRoot = join(scriptDir, "..", "..", "..");
  const opts = parseArgs(Deno.args, repoRoot);

  const audioDir = join(benchDir, "audio");
  const resultsDir = join(benchDir, "results");
  await Deno.mkdir(audioDir, { recursive: true });

  console.log(
    `\nRxVarta bench_v2 — ${
      opts.dryRun ? "DRY RUN" : "live"
    } · runs/clip=${opts.runs}`,
  );

  const answerKey = await loadAnswerKey(opts.answerKeyPath!);
  let scripts = answerKey.scripts;
  if (opts.only) scripts = scripts.filter((s) => s.id === opts.only);
  if (scripts.length === 0) {
    console.error(`No scripts matched --only ${opts.only}`);
    Deno.exit(1);
  }

  // Keys are only needed for a live run.
  let keys = { sarvamKey: "", geminiKey: "" };
  if (!opts.dryRun) {
    keys = await loadKeys([join(repoRoot, ".env"), join(benchDir, ".env")]);
  }

  const results: ScriptResult[] = [];
  let ttsTotalInr = 0;

  for (let i = 0; i < scripts.length; i++) {
    const script = scripts[i];
    const profile = profileFor(i);
    console.log(
      `\n[${i + 1}/${scripts.length}] ${script.id} (${script.category})`,
    );

    // ── DRY RUN ──────────────────────────────────────────────────────────────
    if (opts.dryRun) {
      const audioSeconds = script.text.length / 14; // ~14 chars/sec of speech
      const insight = mockInsight(script);
      const runs = mockTiming(script, audioSeconds);
      const grade = gradeScript(script, insight);
      const outputChars = JSON.stringify(insight).length;
      results.push({
        id: script.id,
        category: script.category,
        status: "ok",
        routing: audioSeconds < 28 ? "rest" : "batch_sync",
        ttsCached: true,
        audioSeconds,
        runs,
        grade,
        cost: consultCost(audioSeconds, script.text.length, outputChars),
        transcript: "(dry-run — no transcript)",
        insight,
      });
      console.log(
        `   graded (dry-run). trap=${grade.isTrap ? grade.trapPass : "n/a"}`,
      );
      continue;
    }

    // ── LIVE RUN ──────────────────────────────────────────────────────────────
    try {
      // Step 1 — TTS (cached)
      const audioPath = join(audioDir, `${script.id}.wav`);
      const tts = await withRetry(
        () => generateAudio(keys.sarvamKey, script.text, audioPath, profile),
        `${script.id} TTS`,
      );
      if (tts.cached) {
        console.log(
          `   TTS: cached (${tts.durationSeconds.toFixed(1)}s audio)`,
        );
      } else {
        const c = ttsCost(tts.charCount);
        ttsTotalInr += c;
        console.log(
          `   TTS: ${tts.charCount} chars in ${
            tts.wallSeconds.toFixed(1)
          }s → ` +
            `₹${
              c.toFixed(2)
            } · voices d=${profile.doctorSpeaker}/p=${profile.patientSpeaker} pace=${profile.pace} · ${
              tts.durationSeconds.toFixed(1)
            }s audio`,
        );
      }

      // Step 2 — run the real pipeline N times. Individual run failures are
      // tolerated: a throttled latency sample must not discard an otherwise
      // good extraction. We grade on the first successful run and keep whatever
      // latency samples we got; a script is only ERROR if EVERY run failed.
      const runs: RunTiming[] = [];
      let graded: MedicalInsight | null = null;
      let transcript = "";
      let routing = "";
      let lastRunError = "";
      for (let r = 0; r < opts.runs; r++) {
        await throttlePipeline();
        try {
          const run = await withRetry(
            () => runPipeline(audioPath, keys.sarvamKey, keys.geminiKey),
            `${script.id} pipeline run ${r + 1}`,
          );
          runs.push({
            sttMs: run.sttMs,
            geminiMs: run.geminiMs,
            totalMs: run.totalMs,
          });
          routing = run.routing;
          // Grade the first successful run's extraction.
          if (graded === null) {
            graded = run.insight;
            transcript = run.transcript;
          }
          console.log(
            `   run ${r + 1}/${opts.runs}: stt=${
              (run.sttMs / 1000).toFixed(1)
            }s ` +
              `gemini=${(run.geminiMs / 1000).toFixed(1)}s`,
          );
        } catch (e) {
          lastRunError = e instanceof Error ? e.message : String(e);
          console.error(
            `   ✗ run ${r + 1}/${opts.runs} failed: ${lastRunError}`,
          );
        }
      }

      if (graded === null) {
        // Every run failed — surface as a script-level ERROR (outer catch).
        throw new Error(
          `all ${opts.runs} pipeline runs failed — ${lastRunError}`,
        );
      }
      if (runs.length < opts.runs) {
        console.log(
          `   ⚠️ graded on ${runs.length}/${opts.runs} successful run(s) ` +
            `(latency uses ${runs.length} sample(s))`,
        );
      }

      const grade = gradeScript(script, graded);
      const outputChars = JSON.stringify(graded).length;
      results.push({
        id: script.id,
        category: script.category,
        status: "ok",
        routing,
        ttsCached: tts.cached,
        ttsWallSeconds: tts.wallSeconds,
        ttsChars: tts.charCount,
        audioSeconds: tts.durationSeconds,
        runs,
        grade,
        cost: consultCost(tts.durationSeconds, transcript.length, outputChars),
        transcript,
        insight: graded,
      });
      if (grade.isTrap) {
        console.log(
          `   trap: ${grade.trapPass ? "PASS" : "FAIL — " + grade.trapDetail}`,
        );
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error(`   ✗ ERROR: ${msg}`);
      results.push({
        id: script.id,
        category: script.category,
        status: "error",
        error: msg,
        runs: [],
      });
    }
  }

  // ── Report ────────────────────────────────────────────────────────────────
  const summary: BenchSummary = {
    results,
    ttsTotalInr,
    dryRun: opts.dryRun,
    startedAt: new Date().toISOString(),
  };

  printConsole(summary);
  const { jsonPath, mdPath } = await writeOutputs(summary, resultsDir);

  console.log("Open these for the report:");
  console.log(`  • ${mdPath}`);
  console.log(`  • ${jsonPath}\n`);
}

if (import.meta.main) {
  await main();
}
