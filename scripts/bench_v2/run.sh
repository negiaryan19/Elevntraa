#!/usr/bin/env bash
# Single-command entrypoint for the RxVarta eval harness (bench_v2).
#
#   ./run.sh              # full live run  (needs SARVAM_API_KEY + GEMINI_API_KEY)
#   ./run.sh --dry-run    # grader/report demo, no API calls or keys
#   ./run.sh --only script_01 --runs 1
#
# Any arguments are forwarded to bin/bench_v2.ts.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v deno >/dev/null 2>&1; then
  echo "ERROR: deno is not installed. Install from https://deno.land (the repo's"
  echo "       Supabase Edge Functions already require it)." >&2
  exit 1
fi

exec deno run \
  --allow-read --allow-write --allow-net --allow-env \
  bin/bench_v2.ts "$@"
