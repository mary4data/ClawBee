# ClawBee — Family Meal Planner Skills for OpenClaw

> Photo your fridge → get a 3-day meal plan → receive the shopping list on Telegram.

[![skills.sh](https://img.shields.io/badge/skills.sh-mary4data%2FClawBee-blue)](https://skills.sh/mary4data/ClawBee)
[![License](https://img.shields.io/badge/license-Apache%202.0-green)](LICENSE.txt)

---

## Architecture

```mermaid
flowchart TD
    User(["👤 User"])

    TG["📱 Telegram Bot\n─────────────\nSend fridge photos\nReceive shopping lists"]
    DC["🎮 Discord\n─────────────\nView meal plan posts\nBot-to-bot updates"]

    subgraph RAIL ["🚂 Railway Cloud"]
        subgraph OC ["🦞 OpenClaw Gateway"]
            direction TB
            ORCH["🚀 Orchestrator\n/plan weekly · /plan post"]

            subgraph SKILLS ["Agent Skills  ·  npx skills add mary4data/ClawBee"]
                direction LR
                FS["📸 Fridge Scanner\n/scan · /scan demo"]
                FT["🧊 Fridge Tracker\n/fridge list · add"]
                MP["📅 Meal Planner\n/meals plan"]
                PH["💰 Price Hunter\n/prices search"]
                SA["🛒 Shopping Agent\n/shopping send"]
            end

            ORCH --> FS & FT & MP & PH & SA
        end

        DB[("🗄️ SQLite\npantry.db")]
    end

    FAI["🤖 Featherless AI\nLLM Backend"]
    WEB["🌐 Web Search\nRewe · Lidl · Aldi Berlin"]

    User -->|"fridge photo / command"| TG
    User -->|"views posts"| DC
    TG -->|"inbound message + media"| OC
    OC -->|"shopping list"| TG
    OC -->|"meal plan post"| DC

    FS & FT & MP & PH & SA <-->|"read / write"| DB
    FS & MP -->|"LLM inference"| FAI
    PH -->|"price search"| WEB
    SA -->|"send list"| TG
    SA -->|"notify"| DC

    classDef channel  fill:#5865F2,color:#fff,stroke:#4752C4
    classDef skill    fill:#1e293b,color:#94a3b8,stroke:#334155
    classDef external fill:#0f172a,color:#64748b,stroke:#1e293b
    classDef db       fill:#713f12,color:#fde68a,stroke:#92400e
    classDef user     fill:#166534,color:#bbf7d0,stroke:#15803d
    classDef orch     fill:#7c3aed,color:#ede9fe,stroke:#6d28d9

    class TG,DC channel
    class FS,FT,MP,PH,SA skill
    class FAI,WEB external
    class DB db
    class User user
    class ORCH orch
```

---

## Setup on Railway (5 min)

### Step 1 — Create a Telegram Bot

1. Open Telegram → search **@BotFather**
2. Send `/newbot` and follow the prompts
3. Copy the token: `123456789:ABCDEF...`
4. Get your Chat ID: message **@userinfobot** → copy the `Id` number

### Step 2 — Set Railway Environment Variables

In Railway → your OpenClaw service → **Variables**, add:

| Variable | Value |
|---|---|
| `TELEGRAM_BOT_TOKEN` | `123456789:ABCDEF...` |
| `TELEGRAM_CHAT_ID` | `123456789` |
| `FEATHERLESS_API_KEY` | your Featherless key |
| `DISCORD_BOT_TOKEN` | *(optional)* |
| `DISCORD_CHANNEL_ID` | *(optional)* |

### Step 3 — Run Auto-Setup

Open the Railway shell (**your service → Shell tab**) and run:

```bash
bash <(curl -s https://raw.githubusercontent.com/mary4data/ClawBee/main/deploy/setup.sh)
```

This single command:
- Writes `openclaw.json` with Telegram + Featherless AI config
- Clones ClawBee skills into `/data/workspace/clawbee/skills`
- Creates `pantry.db` with all tables
- Prints test commands when done

### Step 4 — Restart OpenClaw

In Railway → your service → **Restart** (or redeploy).

### Step 5 — Test

Send to your Telegram bot:
```
/plan help
```

---

## Install Skills Only

If OpenClaw is already configured, just install the skills:

```bash
npx skills add mary4data/ClawBee
```

Or individual skills:
```bash
npx skills add mary4data/ClawBee@orchestrator
npx skills add mary4data/ClawBee@fridge-scanner
```

---

## Commands

| Command | Description |
|---|---|
| `/plan weekly [budget]` | Full pipeline — fridge check, prices, meal plan, Telegram |
| `/plan post` | Post plan to Discord |
| `/scan` + photo | Scan fridge photo → 3-day plan |
| `/scan demo` | Demo scan (no photo needed) |
| `/scan shop` | Send scan's shopping list to Telegram |
| `/fridge list` | Show pantry contents |
| `/fridge add <item> [qty]` | Add item |
| `/meals plan [budget]` | 7-day dinner plan |
| `/prices search <item>` | Find cheapest price in Berlin |
| `/shopping send` | Send shopping list to Telegram |
| `/shopping optimize [€]` | Check against budget |

---

## Manual Config

See [`deploy/openclaw.json.example`](deploy/openclaw.json.example) for the full config file.
Place at `/data/.openclaw/openclaw.json` on your Railway instance.

---

## Stack

| Component | Technology |
|---|---|
| Gateway | [OpenClaw](https://openclaw.ai) on Railway |
| LLM | [Featherless AI](https://featherless.ai) |
| Messaging | Telegram Bot API + Discord |
| Storage | SQLite (`pantry.db`) |
| Skills | [skills.sh/mary4data/ClawBee](https://skills.sh/mary4data/ClawBee) |

---

## License

Apache 2.0 — see [LICENSE.txt](LICENSE.txt)
