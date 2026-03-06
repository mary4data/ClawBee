#!/bin/bash
# Initialize pantry.db tables for fridge-scanner
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS last_scan (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  ingredients TEXT,
  plan TEXT,
  scanned_at TEXT DEFAULT (datetime('now'))
);
"
echo "DB ready: $DB"
