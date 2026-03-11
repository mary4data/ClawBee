#!/bin/bash
# ClawBee Setup for OpenClaw on Railway
#
# Run from your Mac (recommended — saves tokens to Railway Variables):
#   curl -fsSL https://raw.githubusercontent.com/mary4data/ClawBee/main/deploy/install.sh -o /tmp/cb.sh && bash /tmp/cb.sh
#
# Or from Railway shell (reads tokens already saved as Railway Variables):
#   curl -fsSL https://raw.githubusercontent.com/mary4data/ClawBee/main/deploy/install.sh -o /tmp/cb.sh && bash /tmp/cb.sh

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

# ── Helpers ────────────────────────────────────────────────────────────────────

prompt_secret() {
  local var="$1" label="$2" current="${!1:-}"
  if [ -n "$current" ]; then
    echo "  $label : [already set — press Enter to keep, or type new value]"
    printf "  > "
  else
    printf "  %s : " "$label"
  fi
  local val
  read -rs val </dev/tty
  echo ""
  [ -n "$val" ] && eval "$var=\$val"
}

prompt_plain() {
  local var="$1" label="$2" current="${!1:-}"
  if [ -n "$current" ]; then
    printf "  %s [%s]: " "$label" "$current"
  else
    printf "  %s : " "$label"
  fi
  local val
  read -r val </dev/tty
  echo ""
  [ -n "$val" ] && eval "$var=\$val"
}

# ── Read existing values from Railway env vars (if inside container) ───────────

# These will be pre-populated if Railway Variables are already set
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID:-}"
FEATHERLESS_API_KEY="${FEATHERLESS_API_KEY:-}"
FEATHERLESS_MODEL="${FEATHERLESS_MODEL:-meta-llama/Meta-Llama-3.1-70B-Instruct}"

# Skip prompts if all required vars already set (e.g. running inside Railway)
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  echo -e "${GREEN}  Railway Variables detected — using existing values.${NC}"
  echo ""
else
  echo "Enter your values (tokens hidden while typing)"
  echo ""

  prompt_secret TELEGRAM_BOT_TOKEN "Telegram bot token"
  prompt_plain  TELEGRAM_CHAT_ID   "Telegram chat ID"
  prompt_plain  DISCORD_CHANNEL_ID "Discord channel ID (blank to skip)"
  if [ -n "$DISCORD_CHANNEL_ID" ]; then
    prompt_secret DISCORD_BOT_TOKEN "Discord bot token"
  fi
  echo ""
  prompt_secret FEATHERLESS_API_KEY "Featherless API key (blank to skip LLM)"
  if [ -n "$FEATHERLESS_API_KEY" ]; then
    prompt_plain  FEATHERLESS_MODEL  "Featherless model ID"
  fi

  echo ""
fi

# ── Validate ───────────────────────────────────────────────────────────────────

ERRORS=0

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo -e "${RED}  ✗ Telegram bot token is required${NC}"; ERRORS=1
elif ! echo "$TELEGRAM_BOT_TOKEN" | grep -qE '^[0-9]+:[A-Za-z0-9_-]{20,}$'; then
  echo -e "${RED}  ✗ Token format looks wrong. Get correct one from @BotFather.${NC}"; ERRORS=1
fi

if [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo -e "${RED}  ✗ Telegram chat ID is required (get from @RawDataBot)${NC}"; ERRORS=1
elif ! echo "$TELEGRAM_CHAT_ID" | grep -qE '^-?[0-9]+$'; then
  echo -e "${RED}  ✗ Chat ID must be a number${NC}"; ERRORS=1
fi

[ "$ERRORS" -eq 1 ] && exit 1

# ── Verify bot token live with Telegram ────────────────────────────────────────

echo -e "${CYAN}Verifying Telegram bot token...${NC}"
TG_CHECK=$(curl -sf "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" 2>/dev/null || true)
if echo "$TG_CHECK" | grep -q '"ok":true'; then
  BOT_NAME=$(echo "$TG_CHECK" | python3 -c \
    "import sys,json; print(json.load(sys.stdin)['result']['username'])" 2>/dev/null || echo "?")
  echo -e "${GREEN}  ✓ Bot verified: @${BOT_NAME}${NC}"
else
  echo -e "${RED}  ✗ Telegram rejected this token. Rotate via @BotFather and re-run.${NC}"
  exit 1
fi

# ── Save to Railway Variables (if railway CLI available — running from Mac) ────

if command -v railway &>/dev/null; then
  echo ""
  echo -e "${CYAN}Saving tokens to Railway Variables...${NC}"
  RAIL_VARS="TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID"
  [ -n "$DISCORD_BOT_TOKEN" ]   && RAIL_VARS="$RAIL_VARS DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN"
  [ -n "$DISCORD_CHANNEL_ID" ]  && RAIL_VARS="$RAIL_VARS DISCORD_CHANNEL_ID=$DISCORD_CHANNEL_ID"
  [ -n "$FEATHERLESS_API_KEY" ] && RAIL_VARS="$RAIL_VARS FEATHERLESS_API_KEY=$FEATHERLESS_API_KEY"
  [ -n "$FEATHERLESS_MODEL" ]   && RAIL_VARS="$RAIL_VARS FEATHERLESS_MODEL=$FEATHERLESS_MODEL"

  # shellcheck disable=SC2086
  railway variables set $RAIL_VARS --service clawdbot-railway-template 2>/dev/null && \
    echo -e "${GREEN}  ✓ Tokens saved to Railway Variables (secure, persistent)${NC}" || \
    echo -e "${YELLOW}  ⚠ Could not save to Railway — set manually in Railway dashboard${NC}"
fi

# ── Paths ──────────────────────────────────────────────────────────────────────

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.clawdbot}"
WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
DB="$WORKSPACE/pantry.db"
SKILLS_DIR="$WORKSPACE/clawbee/skills"

mkdir -p "$STATE_DIR" "$WORKSPACE"

# ── sqlite3 ────────────────────────────────────────────────────────────────────

if ! command -v sqlite3 &>/dev/null; then
  echo -e "${CYAN}Installing sqlite3...${NC}"
  if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq sqlite3
  elif command -v apk &>/dev/null; then
    apk add --quiet sqlite
  elif command -v yum &>/dev/null; then
    yum install -y -q sqlite
  else
    echo -e "${YELLOW}  ⚠ sqlite3 not found — DB init skipped${NC}"
    SKIP_DB=1
  fi
fi

# ── Step 1: Write openclaw.json ────────────────────────────────────────────────

echo ""
echo -e "${CYAN}Step 1/3 — Writing openclaw.json...${NC}"

python3 - <<PYEOF
import json, os, re

state_dir  = "$STATE_DIR"
skills_dir = "$SKILLS_DIR"
port       = int(os.environ.get("PORT", "8080"))
tg_token   = "$TELEGRAM_BOT_TOKEN"
tg_chat_id = "$TELEGRAM_CHAT_ID"
dc_token   = "$DISCORD_BOT_TOKEN"
dc_channel = "$DISCORD_CHANNEL_ID"

config = {
    "channels": {
        "telegram": {
            "enabled":   True,
            "botToken":  tg_token,
            "dmPolicy":  "allowlist",
            "allowFrom": [tg_chat_id]
        }
    },
    "skills": {"load": {"extraDirs": [skills_dir]}},
    "gateway": {"mode": "local", "port": port}
}

if dc_token and dc_channel:
    config["channels"]["discord"] = {
        "enabled":   True,
        "token":     dc_token,
        "dmPolicy":  "allowlist",
        "allowFrom": ["channel:" + dc_channel]
    }

out = os.path.join(state_dir, "openclaw.json")
with open(out, "w") as f:
    json.dump(config, f, indent=2)

def mask(obj):
    if isinstance(obj, dict):
        return {k: (re.sub(r'.', '*', str(v)[:-4]) + str(v)[-4:]
                    if k in ("apiKey","botToken","token") else mask(v))
                for k, v in obj.items()}
    if isinstance(obj, list):
        return [mask(i) for i in obj]
    return obj

print(json.dumps(mask(config), indent=2))
PYEOF

echo -e "${GREEN}  ✓ openclaw.json written${NC}"

# Enable Telegram channel directly
if command -v openclaw &>/dev/null; then
  openclaw config set gateway.mode local              2>/dev/null || true
  openclaw config set channels.telegram.enabled true  2>/dev/null || true
  echo -e "${GREEN}  ✓ Telegram enabled via openclaw config${NC}"
fi

# ── Step 2: Skills ─────────────────────────────────────────────────────────────

echo -e "${CYAN}Step 2/3 — Installing ClawBee skills...${NC}"

if [ -d "$WORKSPACE/clawbee/.git" ]; then
  git -C "$WORKSPACE/clawbee" pull --quiet
  echo -e "${GREEN}  ✓ Skills updated${NC}"
else
  git clone --quiet https://github.com/mary4data/ClawBee.git "$WORKSPACE/clawbee"
  echo -e "${GREEN}  ✓ Skills installed${NC}"
fi

# ── Step 3: Database ───────────────────────────────────────────────────────────

echo -e "${CYAN}Step 3/3 — Initialising database...${NC}"

if [ "${SKIP_DB}" != "1" ] && command -v sqlite3 &>/dev/null; then
  sqlite3 "$DB" "
CREATE TABLE IF NOT EXISTS fridge      (item TEXT NOT NULL UNIQUE, quantity TEXT, updated_at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS meal_plans  (week TEXT PRIMARY KEY, plan_json TEXT NOT NULL, budget REAL, created_at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS family_prefs(key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE IF NOT EXISTS prices      (item TEXT NOT NULL, store TEXT, price REAL, unit TEXT, fetched_at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS last_scan   (id INTEGER PRIMARY KEY CHECK (id=1), ingredients TEXT, plan TEXT, scanned_at TEXT DEFAULT (datetime('now')));
CREATE INDEX IF NOT EXISTS idx_prices_item ON prices(item);
"
  echo -e "${GREEN}  ✓ Database ready at $DB${NC}"
else
  echo -e "${YELLOW}  ⚠ Skipped — tables created on first use${NC}"
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
