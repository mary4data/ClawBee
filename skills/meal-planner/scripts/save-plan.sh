#!/bin/bash
# Usage: save-plan.sh '<week>' '<plan_json>' <budget>
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
WEEK="$1"
PLAN="$2"
BUDGET="${3:-100}"
sqlite3 "$DB" "
INSERT OR REPLACE INTO meal_plans (week, plan_json, budget, created_at)
VALUES ('$WEEK', '$PLAN', $BUDGET, datetime('now'));
"
echo "Plan saved for week: $WEEK"
