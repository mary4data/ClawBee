#!/bin/bash
# Usage: save-plan.sh '<ingredients_json>' '<plan_json>'
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
INGREDIENTS="$1"
PLAN="$2"

sqlite3 "$DB" \
  "INSERT OR REPLACE INTO last_scan (id, ingredients, plan, scanned_at) VALUES (1, ?, ?, datetime('now'));" \
  "$INGREDIENTS" "$PLAN" \
  && echo "Plan saved." \
  || { echo "Error: failed to save scan plan" >&2; exit 1; }
