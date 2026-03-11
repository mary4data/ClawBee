#!/bin/bash
# Run inside Railway shell — reads tokens from Railway Variables, no prompts
set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}ClawBee Railway Setup${NC}"

[ -z "$TELEGRAM_BOT_TOKEN" ] && { echo -e "${RED}Missing TELEGRAM_BOT_TOKEN${NC}"; exit 1; }
[ -z "$TELEGRAM_CHAT_ID" ]   && { echo -e "${RED}Missing TELEGRAM_CHAT_ID${NC}"; exit 1; }

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.clawdbot}"
WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
mkdir -p "$STATE_DIR" "$WORKSPACE"

python3 - <<PYEOF
import json, os

cfg = {
  "channels": {
    "telegram": {
      "enabled": True,
      "botToken": os.environ["TELEGRAM_BOT_TOKEN"],
      "dmPolicy": "allowlist",
      "allowFrom": [os.environ["TELEGRAM_CHAT_ID"]]
    }
  },
  "skills": {"load": {"extraDirs": ["/data/workspace/clawbee/skills"]}},
  "gateway": {"mode": "local", "port": int(os.environ.get("PORT", "8080"))}
}

if os.environ.get("FEATHERLESS_API_KEY"):
  cfg["models"] = [{
    "provider": "openai",
    "baseURL": "https://api.featherless.ai/v1",
    "apiKey": os.environ["FEATHERLESS_API_KEY"],
    "model": os.environ.get("FEATHERLESS_MODEL", "meta-llama/Meta-Llama-3.1-70B-Instruct"),
    "label": "Featherless AI"
  }]

if os.environ.get("DISCORD_BOT_TOKEN") and os.environ.get("DISCORD_CHANNEL_ID"):
  cfg["channels"]["discord"] = {
    "enabled": True,
    "token": os.environ["DISCORD_BOT_TOKEN"],
    "dmPolicy": "allowlist",
    "allowFrom": ["channel:" + os.environ["DISCORD_CHANNEL_ID"]]
  }

out = os.path.join("$STATE_DIR", "openclaw.json")
with open(out, "w") as f:
  json.dump(cfg, f, indent=2)
print("  openclaw.json written to", out)
PYEOF

echo -e "${GREEN}  ✓ Config written${NC}"

if [ -d "$WORKSPACE/clawbee/.git" ]; then
  git -C "$WORKSPACE/clawbee" pull --quiet
else
  git clone --quiet https://github.com/mary4data/ClawBee.git "$WORKSPACE/clawbee"
fi
echo -e "${GREEN}  ✓ Skills ready${NC}"

if command -v sqlite3 &>/dev/null; then
  sqlite3 "$WORKSPACE/pantry.db" "
    CREATE TABLE IF NOT EXISTS fridge (item TEXT NOT NULL UNIQUE, quantity TEXT, updated_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS meal_plans (week TEXT PRIMARY KEY, plan_json TEXT NOT NULL, budget REAL, created_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS family_prefs (key TEXT PRIMARY KEY, value TEXT);
    CREATE TABLE IF NOT EXISTS prices (item TEXT NOT NULL, store TEXT, price REAL, unit TEXT, fetched_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS last_scan (id INTEGER PRIMARY KEY CHECK (id=1), ingredients TEXT, plan TEXT, scanned_at TEXT DEFAULT (datetime('now')));
    CREATE INDEX IF NOT EXISTS idx_prices_item ON prices(item);
  "
  echo -e "${GREEN}  ✓ Database ready${NC}"
fi

echo -e "${GREEN}Done! Restart your Railway service, then send /plan help to your bot.${NC}"
