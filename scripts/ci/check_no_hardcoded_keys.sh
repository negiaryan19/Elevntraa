#!/usr/bin/env bash
set -euo pipefail

FUNCTIONS_DIR="supabase/functions"

if [ ! -d "$FUNCTIONS_DIR" ]; then
  echo "No Supabase functions directory found, skipping key check"
  exit 0
fi

found=0
ts_count=0

# Returns 0 if the line is on the allowlist (safe); 1 if it needs scrutiny.
is_safe_line() {
  local line="$1"
  # Env var read — safe
  echo "$line" | grep -q 'Deno\.env\.get(' && return 0
  # Comment line (// or block comment *)
  echo "$line" | grep -qE '^[0-9]+:[[:space:]]*(//|\*)' && return 0
  # Bare env var NAME strings (all-caps identifiers) — not values
  echo "$line" | grep -qE '"[A-Z][A-Z0-9_]{4,}"' && return 0
  return 1
}

report_hits() {
  local label="$1"
  local file="$2"
  local hits="$3"
  echo "FAIL [$label] $file:"
  echo "$hits" | head -5 | sed 's/^/  /'
  found=1
}

while IFS= read -r -d '' tsfile; do
  ts_count=$((ts_count + 1))

  # 1. Google / Gemini API key: "AIza" + 35 url-safe chars (39 chars total)
  raw=$(grep -nE 'AIza[A-Za-z0-9_-]{35}' "$tsfile" || true)
  if [ -n "$raw" ]; then
    hits=$(echo "$raw" | while IFS= read -r line; do
      is_safe_line "$line" || echo "$line"
    done)
    [ -n "$hits" ] && report_hits "gemini-api-key" "$tsfile" "$hits"
  fi

  # 2. Sarvam key: 32+ char alphanumeric literal in a sarvam*key variable assignment
  raw=$(grep -niE 'sarvam[a-z_]*key[[:space:]]*[=:][[:space:]]*['"'"'"][A-Za-z0-9_-]{32,}' "$tsfile" || true)
  if [ -n "$raw" ]; then
    hits=$(echo "$raw" | while IFS= read -r line; do
      is_safe_line "$line" || echo "$line"
    done)
    [ -n "$hits" ] && report_hits "sarvam-key" "$tsfile" "$hits"
  fi

  # 3. Generic: 40+ alphanum chars in a string literal assigned to a KEY/TOKEN/SECRET variable
  raw=$(grep -niE '(key|token|secret)[[:space:]]*[=:][[:space:]]*['"'"'"][A-Za-z0-9+/_-]{40,}['"'"'"]' "$tsfile" || true)
  if [ -n "$raw" ]; then
    hits=$(echo "$raw" | while IFS= read -r line; do
      is_safe_line "$line" || echo "$line"
    done)
    [ -n "$hits" ] && report_hits "generic-secret" "$tsfile" "$hits"
  fi

done < <(find "$FUNCTIONS_DIR" -name "*.ts" -print0 2>/dev/null)

if [ "$ts_count" -eq 0 ]; then
  echo "No TypeScript files found in $FUNCTIONS_DIR, skipping key check"
  exit 0
fi

if [ "$found" -gt 0 ]; then
  exit 1
fi

echo "No hardcoded keys detected"
