#!/usr/bin/env bash
set -euo pipefail

PIPELINE_FILE="supabase/functions/_shared/pipeline.ts"
HASH_FILE="scripts/ci/prompt_hashes.txt"

if [ ! -f "$PIPELINE_FILE" ]; then
  echo "ERROR: $PIPELINE_FILE not found"
  exit 1
fi

# Portable SHA-256: sha256sum (Linux/CI) or shasum -a 256 (macOS).
portable_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

# Extract each constant from the first matching line through the first line that
# is solely a semicolon (column-0 semicolon terminates the statement).
# Using ^;[[:space:]]*$ avoids premature truncation when prompt content itself
# contains a line that starts with ; but has more text after it.
extract_constant() {
  local name="$1"
  awk "/^export const ${name} =/{found=1} found{print} found && /^;[[:space:]]*$/{found=0}" "$PIPELINE_FILE"
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

plain_hash=$(printf '%s' "$plain_value" | portable_sha256)
diarized_hash=$(printf '%s' "$diarized_value" | portable_sha256)

if [ ! -f "$HASH_FILE" ]; then
  printf 'PLAIN_INSTRUCTION %s\nDIARIZED_INSTRUCTION %s\n' "$plain_hash" "$diarized_hash" > "$HASH_FILE"
  echo "Initialized prompt hashes. Commit scripts/ci/prompt_hashes.txt to lock these in."
  exit 0
fi

stored_plain=$(grep '^PLAIN_INSTRUCTION ' "$HASH_FILE" | awk '{print $2}')
stored_diarized=$(grep '^DIARIZED_INSTRUCTION ' "$HASH_FILE" | awk '{print $2}')

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
