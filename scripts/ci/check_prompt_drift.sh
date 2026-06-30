#!/usr/bin/env bash
set -euo pipefail

HASH_FILE="scripts/ci/prompt_hashes.txt"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/ci/lib/prompt_lib.sh
source "$SCRIPT_DIR/lib/prompt_lib.sh"

if [ ! -f "$PIPELINE_FILE" ]; then
  echo "ERROR: $PIPELINE_FILE not found"
  exit 1
fi

plain_value=$(extract_constant "PLAIN_INSTRUCTION")
diarized_value=$(extract_constant "DIARIZED_INSTRUCTION")

if [ -z "$plain_value" ]; then
  echo "ERROR: Could not extract PLAIN_INSTRUCTION from $PIPELINE_FILE"
  exit 1
fi
if [ -z "$diarized_value" ]; then
  echo "ERROR: Could not extract DIARIZED_INSTRUCTION from $PIPELINE_FILE"
  exit 1
fi

plain_hash=$(printf '%s' "$plain_value" | portable_sha256)
diarized_hash=$(printf '%s' "$diarized_value" | portable_sha256)

if [ ! -f "$HASH_FILE" ]; then
  # In CI, a missing hash file means the baseline was never committed — fail loudly
  # so the developer is forced to initialize it intentionally on the feature branch.
  if [ -n "${CI:-}" ]; then
    echo "ERROR: $HASH_FILE not found."
    echo "Run 'bash scripts/ci/update_prompt_hashes.sh' locally and commit scripts/ci/prompt_hashes.txt."
    exit 1
  fi
  printf 'PLAIN_INSTRUCTION %s\nDIARIZED_INSTRUCTION %s\n' "$plain_hash" "$diarized_hash" > "$HASH_FILE"
  echo "Initialized prompt hashes. Commit scripts/ci/prompt_hashes.txt to lock these in."
  exit 0
fi

# Use || true so grep's exit-1-on-no-match doesn't kill the script under set -e;
# the empty-string guards below produce a clear diagnostic instead.
stored_plain=$(grep '^PLAIN_INSTRUCTION ' "$HASH_FILE" | awk '{print $2}' || true)
stored_diarized=$(grep '^DIARIZED_INSTRUCTION ' "$HASH_FILE" | awk '{print $2}' || true)

if [ -z "$stored_plain" ] || [ -z "$stored_diarized" ]; then
  echo "ERROR: $HASH_FILE is malformed or missing required entries."
  echo "Run 'bash scripts/ci/update_prompt_hashes.sh' locally and commit the result."
  exit 1
fi

failed=0

if [ "$plain_hash" != "$stored_plain" ]; then
  echo "ERROR: Gemini prompt has changed (PLAIN_INSTRUCTION)."
  echo "  Expected: $stored_plain"
  echo "  Got:      $plain_hash"
  failed=1
fi

if [ "$diarized_hash" != "$stored_diarized" ]; then
  echo "ERROR: Gemini prompt has changed (DIARIZED_INSTRUCTION)."
  echo "  Expected: $stored_diarized"
  echo "  Got:      $diarized_hash"
  failed=1
fi

if [ "$failed" -eq 1 ]; then
  echo ""
  echo "If intentional, run: bash scripts/ci/update_prompt_hashes.sh"
  echo "Then commit scripts/ci/prompt_hashes.txt."
  echo "If unintentional, revert the prompt change."
  exit 1
fi

echo "Prompts unchanged"
