#!/bin/bash
# Usage: save-price.sh '<item>' '<store>' <price> '<unit>'
DB="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}/pantry.db"
sqlite3 "$DB" "INSERT INTO prices (item, store, price, unit) VALUES (lower('$1'), '$2', $3, '$4');"
echo "Saved: $1 €$3 @ $2"
