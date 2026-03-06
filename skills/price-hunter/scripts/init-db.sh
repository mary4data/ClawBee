#!/bin/bash
# Initialize pantry.db prices table
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS prices (
  item TEXT NOT NULL,
  store TEXT,
  price REAL,
  unit TEXT,
  fetched_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_prices_item ON prices(item);
"
echo "DB ready: $DB"
