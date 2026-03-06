#!/bin/bash
# Load last scan plan from DB
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
sqlite3 "$DB" "SELECT ingredients, plan, scanned_at FROM last_scan WHERE id=1;" 2>/dev/null
