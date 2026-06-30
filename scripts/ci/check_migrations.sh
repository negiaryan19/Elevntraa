#!/usr/bin/env bash
set -euo pipefail

MIGRATION_DIR="supabase/migrations"

if [ ! -d "$MIGRATION_DIR" ]; then
  echo "No migrations directory found at $MIGRATION_DIR"
  exit 0
fi

count=0
failures=0

for file in "$MIGRATION_DIR"/*.sql; do
  # Handle no-glob-match case (set -f not set, so *.sql stays literal when empty)
  [ -e "$file" ] || { echo "No SQL migration files found in $MIGRATION_DIR"; exit 0; }

  filename=$(basename "$file")

  # Filename must be: 14-digit timestamp + underscore + lowercase alphanumeric/underscores + .sql
  if ! echo "$filename" | grep -qE '^[0-9]{14}_[a-z0-9_]+\.sql$'; then
    echo "FAIL: Migration filename does not match required format: $filename"
    echo "      Expected pattern: YYYYMMDDHHmmss_description_in_snake_case.sql"
    echo "      Example:          20240101120000_create_consultations_table.sql"
    failures=$((failures + 1))
  fi

  # File must not be empty
  if [ ! -s "$file" ]; then
    echo "FAIL: Migration file is empty: $filename"
    failures=$((failures + 1))
  fi

  # Warn (do not fail) on destructive SQL that needs manual review
  if grep -qiE '(DROP[[:space:]]+TABLE|DROP[[:space:]]+COLUMN|TRUNCATE)' "$file"; then
    echo "WARN: $filename contains destructive SQL (DROP TABLE / DROP COLUMN / TRUNCATE)"
    echo "      This needs manual review and a confirmed rollback plan before merging."
  fi

  count=$((count + 1))
done

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "FAIL: $failures migration file(s) failed validation. See errors above."
  exit 1
fi

echo "Validated $count migration file(s)"
