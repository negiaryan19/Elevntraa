# bench_v2 — RxVarta automated eval harness

Turns the 12 ground-truth scripts in `rxvarta_answer_key.json` into a full
report card, fully automated: **synthesize audio → run the real pipeline → grade
per field → print + write a report.** No human recording, no manual steps.

```
./run.sh --dry-run        # verify grader + report format, no API calls / keys
./run.sh                  # full live run (needs Sarvam + Gemini keys)
./run.sh --only script_11 --runs 1
```

Outputs land in `scripts/bench_v2/results/`:

- `report.md` — screenshot-ready summary (trap safety, per-field accuracy,
  latency, cost, per-script detail).
- `results.json` — full raw per-script output + pass/fail per field.

## Why this is Deno/TypeScript (not Dart like `pipeline_bench`)

The guardrail is: **reuse the SAME extraction code path the real app uses — do
not re-implement extraction.** In the current architecture the Flutter app no
longer runs STT/Gemini itself; it uploads audio and calls the Supabase Edge
Function `process-consultation`, whose STT routing + Gemini extraction live in
[`supabase/functions/_shared/pipeline.ts`](../../supabase/functions/_shared/pipeline.ts).

That TypeScript module **is** the real pipeline. So bench_v2:

- `import`s `decideRouting`, `transcribeRest`, `transcribeBatchSync`,
  `extractInsight`, and `normalizeTiming` **directly** from
  `_shared/pipeline.ts` (`lib/pipeline_runner.ts`) — verbatim, nothing
  re-implemented.
- mirrors the exact routing/wiring of `process-consultation/index.ts` (duration
  → `decideRouting` → REST vs batch → `extractInsight`).

The only production difference: audio is read from a local WAV instead of being
downloaded from Supabase Storage. The Gemini config (model, `temperature: 0.3`,
`responseMimeType`, `responseSchema`, system prompt) and the Sarvam routing
thresholds are untouched — they come from the imported module.

`scripts/pipeline_bench` (Dart) predates this and _mirrors_ the logic in a copy;
bench_v2 deliberately does the opposite and imports the source of truth.

## Requirements

- **Deno** (already required by the repo's Supabase Edge Functions).
- For a **live** run, two keys — these are Supabase **server-side secrets**, not
  in the committed `.env` (which only holds Supabase connection details):
  - `SARVAM_API_KEY` — Sarvam STT **and** Bulbul TTS.
  - `GEMINI_API_KEY` — Gemini extraction.

  Provide them via the environment or a local (git-ignored) `.env`:

  ```
  SARVAM_API_KEY=... GEMINI_API_KEY=... ./run.sh
  ```

`--dry-run` needs no keys and makes no network calls — it feeds deliberately
imperfect mock extractions through the real grader so you can see the report.

## Pipeline

1. **TTS (`lib/tts.ts`)** — each script is a PATIENT/DOCTOR dialogue; the two
   roles get **different Bulbul voices**, stitched in order into one WAV, so the
   clip is genuinely two-speaker (what the app's diarized STT expects). Voice
   pair + pace (±10%) rotate across the 12. Spoken `PATIENT:`/`DOCTOR:` labels
   are stripped. Audio is cached in `audio/<id>.wav` (skips regeneration — TTS
   costs money).
2. **Pipeline (`lib/pipeline_runner.ts`)** — WAV duration → `decideRouting` →
   `transcribeRest`/`transcribeBatchSync` → `extractInsight`. Run 3× per clip
   (configurable) for a latency distribution.
3. **Grading (`lib/grader.ts` + `lib/normalize.ts`)** — per `grading_rules`:
   fuzzy medicine-name match (Levenshtein ≤ 2 against `name` + `accept_name`);
   dosage/frequency/duration/timing normalized with a synonym map
   (`din mein do baar` = `twice a day` = `BD` = `1-0-1`); `followUpDays` exact
   (null == null); **trap** cases pass only if medicines are empty / ICD is
   null. Fields scored separately: medicine_name, dosage, frequency, duration,
   timing, followUp, icd, trap_safety. Timing reuses the pipeline's own
   `normalizeTiming`.
4. **Report (`lib/report.ts`)** — console (trap fails in RED) + `report.md` +
   `results.json`.

## Cost

`lib/cost.ts` holds the rate constants. API responses don't include per-call
billing, so cost figures are **estimates** — edit those constants to match your
plan.

## Options

| Flag                  | Default        | Meaning                                                 |
| --------------------- | -------------- | ------------------------------------------------------- |
| `--dry-run`           | off            | No API calls; mock extractions through the real grader. |
| `--runs N`            | `3`            | Pipeline executions per clip (latency spread).          |
| `--only <id>`         | all            | Run a single script, e.g. `--only script_11`.           |
| `--answer-key <path>` | repo-root JSON | Alternate answer key.                                   |

## Safety

Read-only wrapper. Touches nothing under `lib/`, does not modify STT routing,
ICD/confidence logic, the recording state machine, or the Gemini config, and
never commits. Generated `audio/` and `results/` are git-ignored.
