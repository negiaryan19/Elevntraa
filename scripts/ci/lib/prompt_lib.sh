#!/usr/bin/env bash
# Shared helpers sourced by check_prompt_drift.sh and update_prompt_hashes.sh.
# Do not execute directly.

PIPELINE_FILE="${PIPELINE_FILE:-supabase/functions/_shared/pipeline.ts}"

# Portable SHA-256: sha256sum (Linux/CI) or shasum -a 256 (macOS).
portable_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

# Extract a TypeScript export const declaration from PIPELINE_FILE.
# Captures from the "export const NAME =" line through the line immediately before
# the next "export const" declaration (or EOF). This is more reliable than a
# closing-delimiter heuristic: TypeScript template literals close with "`;" on the
# same line as the backtick, not a bare ";" on its own line, so any semicolon-based
# terminator never fires and the extraction silently runs to EOF.
extract_constant() {
  local name="$1"
  awk -v name="$name" '
    found && /^export const / { exit }
    $0 ~ ("^export const " name " =") { found=1 }
    found { print }
  ' "$PIPELINE_FILE"
}
