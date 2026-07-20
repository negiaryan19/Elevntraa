#!/usr/bin/env bash
set -euo pipefail

# Sync-guard: the drug dictionary is bundled once per platform — the Flutter
# asset and the Supabase Edge Function each need their own copy, and medi.json
# at the repo root is the working/editing copy — but all three copies MUST stay
# byte-identical. This check fails when any pair drifts, so a change to one is
# never shipped without the others.
#
# Single source of truth: all three files are one CI-enforced source. Edit any
# one, then mirror the exact bytes to the other two before committing.

FLUTTER_DICT="assets/data/drug_dictionary.json"
SUPABASE_DICT="supabase/functions/_shared/drug_dictionary.json"
ROOT_DICT="medi.json"

DICTS=("$FLUTTER_DICT" "$SUPABASE_DICT" "$ROOT_DICT")

for f in "${DICTS[@]}"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f not found (run from repo root)."
    exit 1
  fi
done

# Three-way comparison: fail if ANY pair differs.
mismatch=0
for ((i = 0; i < ${#DICTS[@]}; i++)); do
  for ((j = i + 1; j < ${#DICTS[@]}; j++)); do
    a="${DICTS[$i]}"
    b="${DICTS[$j]}"
    if ! cmp -s "$a" "$b"; then
      if [ "$mismatch" -eq 0 ]; then
        echo "ERROR: drug dictionaries differ — all three must be byte-identical:"
      fi
      mismatch=1
      echo ""
      echo "  DIFF: $a"
      echo "        $b"
      diff -u "$a" "$b" | head -40 || true
    fi
  done
done

if [ "$mismatch" -ne 0 ]; then
  echo ""
  echo "All three files are one CI-enforced source of truth:"
  echo "  $FLUTTER_DICT"
  echo "  $SUPABASE_DICT"
  echo "  $ROOT_DICT"
  echo "Mirror the exact bytes across all three so the Flutter asset, the"
  echo "Supabase Edge Function, and the repo-root working copy stay in sync."
  exit 1
fi

echo "Drug dictionaries in sync (all three byte-identical)"
exit 0
