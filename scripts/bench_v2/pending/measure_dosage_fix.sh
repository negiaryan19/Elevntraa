#!/usr/bin/env bash
# Measures the parked dosage prompt against the saved baseline.
#
#   scripts/bench_v2/pending/measure_dosage_fix.sh
#
# Costs 18 Gemini requests: 12 (rxvarta_answer_key.json) + 6 (the held-out
# key). The free tier allows 20 a day and resets at midnight Pacific, which is
# 12:30 pm IST, so run this once, after that, and nothing else that day.
#
# The patch is applied for the run and ALWAYS taken out again on exit, pass or
# fail: `supabase functions deploy` ships the working tree, and a prompt that
# has not been accepted must never be sitting in it.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(git rev-parse --show-toplevel)"
PATCH="scripts/bench_v2/pending/dosage_prompt_2026-09-22.patch"
BASELINE="results/baseline_2026-09-22_pre-dosage-fix.json"
STAMP="$(date +%Y-%m-%d_%H%M)"
MAIN="results/dosage-fix_${STAMP}_main"
HOLDOUT="results/dosage-fix_${STAMP}_holdout"

if [ ! -f "$BASELINE" ]; then
  echo "ERROR: $BASELINE is missing; there is nothing to compare with." >&2
  exit 1
fi
if ! git -C "$ROOT" apply --check "$PATCH"; then
  echo "ERROR: the patch does not apply (already applied, or the prompt moved)." >&2
  exit 1
fi

git -C "$ROOT" apply "$PATCH"
trap 'git -C "$ROOT" apply -R "$PATCH" && echo "patch taken out of the working tree again"' EXIT

echo "== 1/2  main key, 12 scripts =="
./run.sh --runs 1
cp results/results.json "$MAIN.json"
cp results/report.md "$MAIN.md"

echo "== 2/2  held-out key, 6 scripts =="
./run.sh --answer-key holdout_answer_key.json --runs 1
cp results/results.json "$HOLDOUT.json"
cp results/report.md "$HOLDOUT.md"

echo
echo "== baseline vs fix, main key (same grader for both) =="
deno run --allow-read bin/regrade.ts "$BASELINE" "$MAIN.json"
echo
echo "== every miss that is left, main key =="
deno run --allow-read bin/regrade.ts --misses "$MAIN.json"
echo
echo "== held-out key =="
deno run --allow-read bin/regrade.ts --answer-key holdout_answer_key.json --misses "$HOLDOUT.json"

cat <<'EOF'

Accept the patch only if ALL of these hold:
  * dosage is up on the main key AND good on the held-out key;
  * a dosage nobody spoke is still empty: script_04 Betadine, script_07 Candid,
    holdout_04 (both medicines);
  * both trap scripts pass;
  * no other field is below the baseline.
One pass is not proof (the failure is stochastic): repeat on later days before
deploying. Saved runs: results/dosage-fix_*  (git-ignored).
EOF
