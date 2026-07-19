#!/usr/bin/env bash
set -euo pipefail

# Sync-guard: the drug dictionary is bundled once per platform — the Flutter
# asset and the Supabase Edge Function each need their own copy — but the two
# copies MUST stay byte-identical. This check fails when they drift, so a change
# to one is never shipped without the other.
#
# Single source of truth: edit medi.json (repo root) and regenerate both copies.

FLUTTER_DICT="assets/data/drug_dictionary.json"
SUPABASE_DICT="supabase/functions/_shared/drug_dictionary.json"

for f in "$FLUTTER_DICT" "$SUPABASE_DICT"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f not found (run from repo root)."
    exit 1
  fi
done

if cmp -s "$FLUTTER_DICT" "$SUPABASE_DICT"; then
  echo "Drug dictionaries in sync"
  exit 0
fi

echo "ERROR: drug dictionaries differ between platforms:"
echo "  $FLUTTER_DICT"
echo "  $SUPABASE_DICT"
echo ""
echo "They must be byte-identical. Regenerate both copies from medi.json so the"
echo "Flutter asset and the Supabase Edge Function share one source of truth."
echo ""
diff -u "$FLUTTER_DICT" "$SUPABASE_DICT" | head -40 || true
exit 1
