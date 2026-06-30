#!/usr/bin/env bash
set -euo pipefail

PIPELINE_FILE="supabase/functions/_shared/pipeline.ts"
HASH_FILE="scripts/ci/prompt_hashes.txt"

if [ ! -f "$PIPELINE_FILE" ]; then
  echo "ERROR: $PIPELINE_FILE not found"
  echo "Run this script from the repo root on a branch that includes the Supabase feature branch."
  exit 1
fi

extract_constant() {
  local name="$1"
  awk "/^export const ${name} =/{found=1} found{print} found && /^;/{found=0}" "$PIPELINE_FILE"
}

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

plain_hash=$(printf '%s' "$plain_value" | sha256sum | awk '{print $1}')
diarized_hash=$(printf '%s' "$diarized_value" | sha256sum | awk '{print $1}')

printf 'PLAIN_INSTRUCTION %s\nDIARIZED_INSTRUCTION %s\n' "$plain_hash" "$diarized_hash" > "$HASH_FILE"
echo "Updated prompt hashes. Commit scripts/ci/prompt_hashes.txt to lock in the new prompts."
