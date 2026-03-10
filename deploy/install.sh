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

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
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

# ── Step 1: Write openclaw.json ────────────────────────────────────────────────

echo ""
echo -e "${CYAN}Step 1/3 — Writing openclaw.json...${NC}"

# Build optional sections
MODEL_SECTION=""
if [ -n "$FEATHERLESS_API_KEY" ]; then
MODEL_SECTION='"models": [
    {
      "provider": "openai",
      "baseURL": "https://api.featherless.ai/v1",
      "apiKey": "'"$FEATHERLESS_API_KEY"'",
      "model": "meta-llama/Meta-Llama-3.1-405B-Instruct",
      "label": "Featherless AI"
    }
  ],'
fi

DISCORD_SECTION=""
if [ -n "$DISCORD_BOT_TOKEN" ] && [ -n "$DISCORD_CHANNEL_ID" ]; then
DISCORD_SECTION='    "discord": {
      "enabled": true,
      "token": "'"$DISCORD_BOT_TOKEN"'",
      "dmPolicy": "open",
      "allowFrom": ["channel:'"$DISCORD_CHANNEL_ID"'"]
    },'
fi

cat > "$STATE_DIR/openclaw.json" << ENDOFCONFIG
{
  $MODEL_SECTION
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_BOT_TOKEN",
      "dmPolicy": "open",
      "allowFrom": ["$TELEGRAM_CHAT_ID"]
    },
    $DISCORD_SECTION
    "web": { "enabled": false }
  },
  "skills": {
    "load": {
      "extraDirs": ["$SKILLS_DIR"]
    }
  },
  "gateway": {
    "port": ${PORT:-8080}
  }
}
ENDOFCONFIG

echo -e "${GREEN}  ✓ Config written to $STATE_DIR/openclaw.json${NC}"

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
CREATE TABLE IF NOT EXISTS family_prefs (
  key TEXT PRIMARY KEY,
  value TEXT
);
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
