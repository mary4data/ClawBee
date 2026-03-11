#!/bin/bash
# ClawBee Interactive Setup
# Run inside Railway shell:
#   bash <(curl -fsSL https://raw.githubusercontent.com/mary4data/ClawBee/main/deploy/install.sh)

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔════════════════════════════════════╗"
echo "  ║    ClawBee Setup for OpenClaw      ║"
echo "  ╚════════════════════════════════════╝"
echo -e "${NC}"

# ── Collect values ─────────────────────────────────────────────────────────────

echo "Enter your values (tokens are hidden while you type)"
echo ""

read -rp "  Telegram bot token : " -s TELEGRAM_BOT_TOKEN
echo ""
read -rp "  Telegram chat ID   : " TELEGRAM_CHAT_ID
echo ""
read -rp "  Featherless API key (leave blank to skip LLM): " -s FEATHERLESS_API_KEY
echo ""
read -rp "  Discord bot token  (leave blank to skip): " -s DISCORD_BOT_TOKEN
echo ""
if [ -n "$DISCORD_BOT_TOKEN" ]; then
  read -rp "  Discord channel ID : " DISCORD_CHANNEL_ID
  echo ""
fi

# ── Validate required ──────────────────────────────────────────────────────────

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo -e "${RED}Telegram bot token and chat ID are required. Aborting.${NC}"
  exit 1
fi

# ── Paths ──────────────────────────────────────────────────────────────────────

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.clawdbot}"
WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
DB="$WORKSPACE/pantry.db"
SKILLS_DIR="$WORKSPACE/clawbee/skills"

mkdir -p "$STATE_DIR" "$WORKSPACE"

# ── Step 0: sqlite3 ────────────────────────────────────────────────────────────

if ! command -v sqlite3 &>/dev/null; then
  echo -e "${CYAN}Installing sqlite3...${NC}"
  if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq sqlite3
  elif command -v apk &>/dev/null; then
    apk add --quiet sqlite
  elif command -v yum &>/dev/null; then
    yum install -y -q sqlite
  else
    echo -e "${YELLOW}  sqlite3 not found — DB init will be skipped${NC}"
    SKIP_DB=1
  fi
fi

# ── Step 1: Write openclaw.json via Python (safe JSON, no escaping issues) ─────

echo ""
echo -e "${CYAN}Step 1/3 — Writing openclaw.json...${NC}"

python3 - <<PYEOF
import json, os

state_dir   = "$STATE_DIR"
skills_dir  = "$SKILLS_DIR"
port        = int(os.environ.get("PORT", "8080"))

tg_token    = "$TELEGRAM_BOT_TOKEN"
tg_chat_id  = "$TELEGRAM_CHAT_ID"
dc_token    = "$DISCORD_BOT_TOKEN"
dc_channel  = "$DISCORD_CHANNEL_ID"

config = {}

# Note: model is configured via Railway env vars, not in openclaw.json

config["channels"] = {
    "telegram": {
        "enabled":   True,
        "botToken":  tg_token,
        "dmPolicy":  "allowlist",
        "allowFrom": [tg_chat_id]
    }
}

if dc_token and dc_channel:
    config["channels"]["discord"] = {
        "enabled":   True,
        "token":     dc_token,
        "dmPolicy":  "allowlist",
        "allowFrom": ["channel:" + dc_channel]
    }

config["skills"] = {"load": {"extraDirs": [skills_dir]}}
config["gateway"] = {"mode": "local", "port": port}

out = os.path.join(state_dir, "openclaw.json")
with open(out, "w") as f:
    json.dump(config, f, indent=2)

print("  Config written to", out)

# Print config with sensitive values masked
import copy, re
def mask(obj):
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            if k in ("apiKey", "botToken", "token"):
                out[k] = re.sub(r'.', '*', str(v)[:-4]) + str(v)[-4:]
            else:
                out[k] = mask(v)
        return out
    if isinstance(obj, list):
        return [mask(i) for i in obj]
    return obj

with open(out) as f:
    loaded = json.load(f)
print(json.dumps(mask(loaded), indent=2))
PYEOF

echo -e "${GREEN}  ✓ openclaw.json ready${NC}"

# Apply doctor fixes (enables Telegram, sets gateway mode)
if command -v openclaw &>/dev/null; then
  openclaw config set gateway.mode local 2>/dev/null || true
  yes | openclaw doctor --fix 2>/dev/null && \
    echo -e "${GREEN}  ✓ openclaw doctor --fix applied${NC}" || true
fi

# ── Step 2: Clone skills ───────────────────────────────────────────────────────

echo -e "${CYAN}Step 2/3 — Installing ClawBee skills...${NC}"

if [ -d "$WORKSPACE/clawbee/.git" ]; then
  echo "  Updating existing clone..."
  git -C "$WORKSPACE/clawbee" pull --quiet
else
  echo "  Cloning mary4data/ClawBee..."
  git clone --quiet https://github.com/mary4data/ClawBee.git "$WORKSPACE/clawbee"
fi

echo -e "${GREEN}  ✓ Skills ready at $SKILLS_DIR${NC}"

# ── Step 3: Init DB ────────────────────────────────────────────────────────────

echo -e "${CYAN}Step 3/3 — Initialising database...${NC}"

if [ "${SKIP_DB}" != "1" ] && command -v sqlite3 &>/dev/null; then
  sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS fridge (
  item TEXT NOT NULL UNIQUE,
  quantity TEXT,
  updated_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS meal_plans (
  week TEXT PRIMARY KEY,
  plan_json TEXT NOT NULL,
  budget REAL,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS family_prefs (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE IF NOT EXISTS prices (
  item TEXT NOT NULL,
  store TEXT,
  price REAL,
  unit TEXT,
  fetched_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS last_scan (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  ingredients TEXT,
  plan TEXT,
  scanned_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_prices_item ON prices(item);
"
  echo -e "${GREEN}  ✓ Database ready at $DB${NC}"
else
  echo -e "${YELLOW}  ⚠ Skipped — tables will be created on first use${NC}"
fi

# ── Done ───────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗"
echo -e "║  Done! Now restart your Railway service.   ║"
echo -e "╚════════════════════════════════════════════╝${NC}"
echo ""
echo "  Then send to your Telegram bot:"
echo "    /scan demo        → demo meal plan"
echo "    /plan weekly 80   → full weekly plan"
echo "    /plan help        → all commands"
echo ""
