# Supabase CI — How it works

## Overview

`supabase-ci.yml` runs on every PR that touches `supabase/**` or `scripts/ci/**`. It validates
Supabase Edge Functions and SQL migrations **statically** — no live Supabase project is needed.

Production deploys are handled by the Supabase GitHub integration: merging to `main` auto-syncs
migrations and Edge Functions via the "Deploy to production" setting in the Supabase dashboard.

## What gets validated

| Step | Trigger condition |
|------|-------------------|
| Deno type-check `_shared/pipeline.ts` | file exists in PR |
| Deno type-check `process-consultation/index.ts` | file exists in PR |
| Deno type-check `check-job-status/index.ts` | file exists in PR |
| `deno lint supabase/functions/` | any `.ts` under `functions/` exists |
| `deno fmt --check supabase/functions/` | any `.ts` under `functions/` exists |
| SQL migration filename / emptiness checks | any `.sql` under `supabase/migrations/` exists |
| Gemini prompt drift check | `pipeline.ts` exists |
| Hardcoded key scan | any `.ts` under `functions/` exists |

## Running checks locally

All scripts are in `scripts/ci/` and are safe to run locally. Run from the **repo root**.

### Type-check and lint (requires Deno ≥ 1.x)

```bash
# Install Deno if needed: https://docs.deno.com/runtime/getting_started/installation/
deno check supabase/functions/_shared/pipeline.ts
deno check supabase/functions/process-consultation/index.ts
deno check supabase/functions/check-job-status/index.ts
deno lint supabase/functions/
deno fmt --check supabase/functions/
```

### Migration validation

```bash
bash scripts/ci/check_migrations.sh
```

Checks that every `.sql` file under `supabase/migrations/` follows the naming convention
`YYYYMMDDHHmmss_description.sql`, is non-empty, and warns on destructive statements.

### Hardcoded key scan

```bash
bash scripts/ci/check_no_hardcoded_keys.sh
```

Scans all `.ts` files under `supabase/functions/` for literal API keys. Lines that call
`Deno.env.get(...)` or contain only env var NAME strings are excluded automatically.

### Prompt drift check

```bash
bash scripts/ci/check_prompt_drift.sh
```

Hashes the `PLAIN_INSTRUCTION` and `DIARIZED_INSTRUCTION` constants in `pipeline.ts` and
compares them against the stored hashes in `scripts/ci/prompt_hashes.txt`.

- **First run (no `prompt_hashes.txt` yet):** the script writes the file and exits 0.
  Commit `scripts/ci/prompt_hashes.txt` to lock the prompts in.
- **Subsequent runs:** fails if either prompt changed without the hash file being updated.

## How to update prompts intentionally

1. Edit `PLAIN_INSTRUCTION` or `DIARIZED_INSTRUCTION` in `pipeline.ts`.
2. Regenerate the hash file:
   ```bash
   bash scripts/ci/update_prompt_hashes.sh
   ```
3. Commit **both** `pipeline.ts` and `scripts/ci/prompt_hashes.txt` in the same PR.

The PR description checklist will remind reviewers that the hash was updated deliberately.

## Files

```
scripts/ci/
├── check_migrations.sh       Validates SQL migration filenames and content
├── check_no_hardcoded_keys.sh  Scans Edge Functions for literal API keys
├── check_prompt_drift.sh     Compares Gemini prompt hashes against locked baseline
├── update_prompt_hashes.sh   Regenerates prompt_hashes.txt (run after intentional edits)
└── prompt_hashes.txt         Locked SHA-256 hashes of the Gemini prompts (committed)

.github/workflows/
└── supabase-ci.yml           GitHub Actions workflow — triggers on supabase/** PRs
```
