#!/bin/bash
# ClawBee Auto-Setup for OpenClaw on Railway
# Run once from the Railway shell: bash <(curl -s https://raw.githubusercontent.com/mary4data/ClawBee/main/deploy/setup.sh)
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║   ClawBee Auto-Setup for OpenClaw ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${NC}"

# ── Paths ─────────────────────────────────────────────────────────────────────
STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
CONFIG="$STATE_DIR/openclaw.json"
SKILLS_DIR="$WORKSPACE/clawbee/skills"

mkdir -p "$STATE_DIR" "$WORKSPACE"

# ── Check required env vars ───────────────────────────────────────────────────
MISSING=()
[ -z "$TELEGRAM_BOT_TOKEN" ]  && MISSING+=("TELEGRAM_BOT_TOKEN")
[ -z "$TELEGRAM_CHAT_ID" ]    && MISSING+=("TELEGRAM_CHAT_ID")
[ -z "$FEATHERLESS_API_KEY" ] && MISSING+=("FEATHERLESS_API_KEY")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${RED}Missing required env vars: ${MISSING[*]}${NC}"
  echo "Set them in Railway → your service → Variables, then re-run."
  exit 1
fi

# ── Step 0: Install sqlite3 if missing ───────────────────────────────────────
if ! command -v sqlite3 &>/dev/null; then
  echo -e "${CYAN}Step 0/3 — Installing sqlite3...${NC}"
  if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq sqlite3
  elif command -v apk &>/dev/null; then
    apk add --quiet sqlite
  elif command -v yum &>/dev/null; then
    yum install -y -q sqlite
  else
    echo -e "${RED}  Cannot install sqlite3 — package manager not found.${NC}"
    echo "  DB init skipped; tables will be created on first skill use."
    SKIP_DB=1
  fi
  command -v sqlite3 &>/dev/null && echo -e "${GREEN}  ✓ sqlite3 installed${NC}"
fi

# ── Step 1: Write openclaw.json ───────────────────────────────────────────────
echo -e "${CYAN}Step 1/3 — Writing openclaw.json config...${NC}"

DISCORD_SECTION=""
if [ -n "$DISCORD_BOT_TOKEN" ] && [ -n "$DISCORD_CHANNEL_ID" ]; then
  DISCORD_SECTION=',
    "discord": {
      "enabled": true,
      "token": "'"$DISCORD_BOT_TOKEN"'",
      "dmPolicy": "open"
    }'
fi

cat > "$CONFIG" << EOF
{
  "models": [
    {
      "provider": "openai",
      "baseURL": "https://api.featherless.ai/v1",
      "apiKey": "$FEATHERLESS_API_KEY",
      "model": "meta-llama/Meta-Llama-3.1-405B-Instruct",
      "label": "Featherless AI"
    }
  ],
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_BOT_TOKEN",
      "dmPolicy": "open",
      "allowFrom": ["$TELEGRAM_CHAT_ID"]
    }$DISCORD_SECTION
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
EOF

echo -e "${GREEN}  ✓ Config written to $CONFIG${NC}"

# ── Step 2: Install ClawBee skills ───────────────────────────────────────────
echo -e "${CYAN}Step 2/3 — Installing ClawBee skills...${NC}"

if [ -d "$WORKSPACE/clawbee/.git" ]; then
  echo "  Updating existing clone..."
  git -C "$WORKSPACE/clawbee" pull --quiet
else
  echo "  Cloning mary4data/ClawBee..."
  git clone --quiet https://github.com/mary4data/ClawBee.git "$WORKSPACE/clawbee"
fi

echo -e "${GREEN}  ✓ Skills installed at $SKILLS_DIR${NC}"

# ── Step 3: Init databases ────────────────────────────────────────────────────
echo -e "${CYAN}Step 3/3 — Initialising skill databases...${NC}"

DB="$WORKSPACE/pantry.db"

if [ "${SKIP_DB}" != "1" ] && command -v sqlite3 &>/dev/null; then
  sqlite3 "$DB" "
    CREATE TABLE IF NOT EXISTS fridge (item TEXT NOT NULL UNIQUE, quantity TEXT, updated_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS meal_plans (week TEXT PRIMARY KEY, plan_json TEXT NOT NULL, budget REAL, created_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS family_prefs (key TEXT PRIMARY KEY, value TEXT);
    CREATE TABLE IF NOT EXISTS prices (item TEXT NOT NULL, store TEXT, price REAL, unit TEXT, fetched_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS last_scan (id INTEGER PRIMARY KEY CHECK (id = 1), ingredients TEXT, plan TEXT, scanned_at TEXT DEFAULT (datetime('now')));
    CREATE INDEX IF NOT EXISTS idx_prices_item ON prices(item);
  "
  echo -e "${GREEN}  ✓ Database ready at $DB${NC}"
else
  echo -e "${YELLOW}  ⚠ sqlite3 not available — skipping DB init (tables created on first use)${NC}"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗"
echo -e "║  Setup complete! Restart OpenClaw gateway.   ║"
echo -e "╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Restart your Railway service, then send to your bot:${NC}"
echo -e "  /plan help          → show all commands"
echo -e "  /scan demo          → demo meal plan (no photo)"
echo -e "  /plan weekly 80     → full pipeline, €80 budget"
echo ""
