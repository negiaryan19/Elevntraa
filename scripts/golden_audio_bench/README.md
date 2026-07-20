# Golden audio harness

End-to-end pre-release gate. Replays real recorded consultations through the
**production backend** — the exact path the app uses
(`lib/features/consultation/data/pipeline_service.dart`):

1. Authenticate against Supabase (email/password from `.env`).
2. Upload `audio.m4a` to the `consultation-audio` storage bucket.
3. Invoke the `process-consultation` Edge Function.
4. Await the `sync` result, or poll `check-job-status` for the `async` batch
   path.
5. Assert the extracted insight against each case's `expected.json`.

It exercises the real server-side `validateExtraction`, drug dictionary, and
Gemini prompts — so it catches regressions that unit tests (which stub the
transcript) cannot.

## Run

```
dart run scripts/golden_audio_bench/run.dart
```

Options:

```
--env <path>   .env file (default: $BENCH_ENV_PATH, then ./.env)
--dir <path>   cases directory (default: test/golden_audio)
--debug        print the full extracted insight per case (PHI — off by default)
```

Requires these keys in `.env` (same file/config as `scripts/pipeline_bench`):

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
AUTO_LOGIN_EMAIL=...
AUTO_LOGIN_PASSWORD=...
```

No `pub get` needed — the script uses only `dart:io`, so it runs straight from
the repo root.

## Output

Per-case detail (expected vs got medicines, each failed assertion) plus a
summary table:

```
Case                    | Result | Medicines (expected vs got)          | Time
---------------------------------------------------------------------------------
fungal_infection_3meds  | PASS   | exp {Luliconazole, …} → got {…}       | 41.7s
```

**Exit code is non-zero if any case fails**, so it can gate a release. A case
with no `audio.m4a` yet is a placeholder — listed and skipped, never a failure.
With zero runnable cases the harness exits 0.

## Adding cases

See [`test/golden_audio/README.md`](../../test/golden_audio/README.md): drop an
`audio.m4a` + write an `expected.json` in a folder under `test/golden_audio/`.

## When to run

> **Run `dart run scripts/golden_audio_bench/run.dart` before every merge that
> touches `supabase/functions/_shared/pipeline.ts`, the drug dictionaries
> (`drug_dictionary.json` / `medi.json`), or the Gemini prompts.**

This is a **manual** gate. It is intentionally **not** wired into GitHub Actions
CI: each run makes real Sarvam + Gemini API calls and costs money per case. Run
it locally against real audio, confirm all cases pass, then merge.
