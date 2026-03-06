#!/bin/bash
# Initialize pantry.db fridge table
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS fridge (
  item TEXT NOT NULL UNIQUE,
  quantity TEXT,
  updated_at TEXT DEFAULT (datetime('now'))
);
"
echo "DB ready: $DB"
