# ClawBee — Project Status

_Last updated: 2026-03-12_

---

## What ClawBee Is

A Telegram-based AI assistant running on Railway, powered by OpenClaw gateway + Featherless AI models. Users interact via Telegram DMs (and group chat) to manage their kitchen: scan fridges, plan meals, track prices, and generate shopping lists.

---

## Infrastructure

| Component | Status | Details |
|-----------|--------|---------|
| Railway service | ✅ Running | `clawdbot-railway-template` |
| OpenClaw gateway | ✅ Running | v2026.3.8, PID 74 |
| Featherless AI | ✅ Connected | `FEATHERLESS_API_KEY` set |
| Telegram bot | ✅ Active | `@DmkClawBot` |
| OpenClaw Web UI | ✅ Accessible | Railway URL + Basic Auth (password: `ClawBee555`) |
| Persistent volume | ✅ Mounted | `/data` — survives redeploys |

---

## AI Model Setup

| Role | Model | Notes |
|------|-------|-------|
| Main agent | `featherless/Qwen/Qwen3-32B` | Primary chat/reasoning model |
| Image analysis | `featherless/Qwen/Qwen3-VL-30B-A3B-Instruct` | Used for fridge scan photos |
| Fallback | `featherless/MiniMaxAI/MiniMax-M2.5` | Also configured |

**Model compatibility rule**: Qwen, MiniMax, Mistral = JSON tool calls = compatible with OpenClaw. Llama models use XML tool call format and will break the agent.

**Context limit**: Qwen3-32B on Featherless is capped at ~28,672 tokens. Long conversations auto-compact.

---

## Skills

All 6 skills are installed at `/data/workspace/clawbee/skills/` on the container.

| Skill | Trigger | Status | Notes |
|-------|---------|--------|-------|
| `fridge-scanner` | `/scan`, photo upload | ✅ Working | Uses Featherless vision (Qwen3-VL); syncs to pantry.db |
| `meal-planner` | `/meals plan` | ✅ Working | Reads from pantry.db |
| `fridge-tracker` | `/fridge` | ✅ Working | Direct DB queries |
| `price-hunter` | `/prices` | ✅ Working | DB lookups only (no web search) |
| `shopping-agent` | `/shop` | ✅ Working | Generates list from pantry.db |
| `orchestrator` | `/plan` | ✅ Working | Routes between skills |

**Simplified in this session**: Removed web searches, missing file references, and Discord integration from all skills to prevent crashes during long-running tasks.

---

## Telegram Access Control

```json
"channels": {
  "telegram": {
    "dmPolicy": "allowlist",
    "allowFrom": ["6699915402"],
    "groupPolicy": "allowlist",
    "groupAllowFrom": [-1003816444094]
  }
}
```

| Chat | ID | Status |
|------|----|--------|
| Owner DM | `6699915402` | ✅ Working |
| Group "ClawBee" | `-1003816444094` | ⚠️ See below |

---

## Outstanding Issue: Group Chat

**Problem**: The group `ClawBee` was upgraded to a Telegram supergroup, changing its ID from `-5284692231` to `-1003816444094`. The config has been updated with the new ID in `groupAllowFrom`, but OpenClaw is logging:

```
[telegram] Invalid allowFrom entry: "-1003816444094" — allowFrom/groupAllowFrom authorization requires numeric Telegram sender IDs only.
```

**Root cause**: OpenClaw requires group IDs as JSON **integers**, not strings. The config file on the persistent volume `/data/.clawdbot/openclaw.json` has had the integer version written, but the gateway needs a clean restart to pick it up without the wrapper overwriting it from an older cached env variable.

**Current state of `openclaw.json`** (verified):
```json
"groupAllowFrom": [-1003816444094]
```
Integer format is correct.

**What's needed to fix**:
1. The gateway must restart and read the integer version from disk (not from old env var)
2. Options:
   - Trigger a Railway redeploy with the updated `OPENCLAW_JSON_B64` variable (already set correctly)
   - Or: SSH in and start the gateway after the file is confirmed correct

**Workaround**: The bot responds normally in DMs. Group chat just needs this one restart to work.

---

## Key Files

### On Railway Container (`/data/`)
```
/data/.clawdbot/openclaw.json          — Main gateway config (EDIT WITH CARE)
/data/workspace/pantry.db             — SQLite: fridge, meal_plans, prices tables
/data/workspace/clawbee/skills/        — All 6 skill directories
/data/workspace/fridge_scan_*.json     — Scan output files
```

### In This Repo
```
skills/fridge-scanner/scripts/scan_fridge.py   — Featherless AI vision script
skills/fridge-scanner/SKILL.md                 — Skill instructions for OpenClaw
deploy/railway-setup.sh                        — One-time setup script (run via SSH)
```

---

## Railway Variables (required)

| Variable | Purpose |
|----------|---------|
| `TELEGRAM_BOT_TOKEN` | Bot auth token from BotFather |
| `TELEGRAM_CHAT_ID` | Owner's Telegram user ID |
| `FEATHERLESS_API_KEY` | Featherless AI API key |
| `FEATHERLESS_MODEL` | Model ID (used as fallback reference) |
| `OPENCLAW_MODEL` | Active model e.g. `featherless/Qwen/Qwen3-32B` |
| `OPENCLAW_JSON_B64` | Base64-encoded full `openclaw.json` (written at container start if no file exists) |
| `OPENAI_API_KEY` | Same as `FEATHERLESS_API_KEY` (used by scan_fridge.py) |
| `OPENAI_BASE_URL` | `https://api.featherless.ai/v1` |

---

## How to Progress

### Short Term
- [ ] **Fix group chat**: Confirm the gateway restarts with integer `groupAllowFrom`; test by sending a message to the ClawBee Telegram group
- [ ] **Push skill updates to GitHub**: `fridge-scanner` SKILL.md and scan_fridge.py have been updated locally but not committed/pushed

### Medium Term
- [ ] **Improve meal planner**: Currently uses generic meal templates; could be improved with actual recipe data
- [ ] **Price tracking**: `price-hunter` currently only reads from DB; add a way to populate prices (manual entry or periodic script)
- [ ] **Fridge tracker UI**: Could show a clean formatted table of current fridge contents

### Considerations
- **Context overflow**: Qwen3-32B hits the 28K token limit on long meal planning sessions. If the bot goes silent mid-task, the session was auto-reset. Keep task instructions short.
- **Bot stability**: Long-running subagent tasks (>60s) can cause Telegram polling to stall. Skills are now simplified to avoid this.
- **Model switching**: Do NOT switch to Llama-family models — they use XML tool calls incompatible with OpenClaw. Stick to Qwen, MiniMax, or Mistral.

---

## Quick Commands Reference

```bash
# Check Railway logs
railway logs --service clawdbot-railway-template

# SSH into container
railway ssh --service clawdbot-railway-template

# Update Railway variable
railway variables set KEY=VALUE --service clawdbot-railway-template

# Trigger redeploy
railway redeploy --service clawdbot-railway-template --yes

# Hot-reload gateway config (from inside container)
kill -USR1 <gateway-pid>

# Check gateway config on container
grep -A3 "groupAllowFrom" /data/.clawdbot/openclaw.json
```
