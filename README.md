# ClawBee — Family Meal Planner Skills

> AI-powered meal planning for OpenClaw. Photo your fridge, get a weekly plan, receive the shopping list on Telegram.

[![skills.sh](https://img.shields.io/badge/skills.sh-mary4data%2FClawBee-blue)](https://skills.sh/mary4data/ClawBee)
[![License](https://img.shields.io/badge/license-Apache%202.0-green)](LICENSE.txt)

## Install

```bash
npx skills add mary4data/ClawBee
```

Or install individual skills:

```bash
npx skills add mary4data/ClawBee@orchestrator      # Full pipeline
npx skills add mary4data/ClawBee@fridge-scanner    # Photo scan
npx skills add mary4data/ClawBee@shopping-agent    # Telegram delivery
```

---

## Architecture

```mermaid
flowchart TD
    %% ── Users ──────────────────────────────────────────────
    User(["👤 User"])

    %% ── Channels ────────────────────────────────────────────
    TG["📱 Telegram\n─────────────\nSend fridge photos\nReceive shopping lists"]
    DC["🎮 Discord\n─────────────\nView meal plan posts\nBot-to-bot updates"]

    %% ── OpenClaw on Railway ─────────────────────────────────
    subgraph RAIL ["🚂 Railway Cloud"]
        subgraph OC ["🦞 OpenClaw Gateway"]
            direction TB

            ORCH["🚀 Orchestrator\n/plan weekly · /plan post"]

            subgraph SKILLS ["Agent Skills"]
                direction LR
                FS["📸 Fridge Scanner\n/scan · /scan demo\n/scan shop"]
                FT["🧊 Fridge Tracker\n/fridge list\n/fridge add · remove"]
                MP["📅 Meal Planner\n/meals plan\n/meals show"]
                PH["💰 Price Hunter\n/prices search\n/prices list"]
                SA["🛒 Shopping Agent\n/shopping list\n/shopping send"]
            end

            ORCH --> FS & FT & MP & PH & SA
        end

        DB[("🗄️ SQLite\npantry.db\n─────────\nfridge\nmeal_plans\nprices\nlast_scan")]
    end

    %% ── External Services ───────────────────────────────────
    FAI["🤖 Featherless AI\nLLM Backend\n(model inference)"]
    WEB["🌐 Web Search\nBerlin supermarket prices\nRewe · Lidl · Aldi"]

    %% ── Skill Distribution ──────────────────────────────────
    subgraph DIST ["Skill Distribution"]
        GH["📦 GitHub\nmary4data/ClawBee"]
        SKS["🔧 skills.sh\nPublic Registry"]
        GH -->|"indexed automatically"| SKS
    end

    %% ── User flows ──────────────────────────────────────────
    User -->|"fridge photo\n/scan command"| TG
    User -->|"views posts"| DC
    TG -->|"inbound message\n+ media"| OC
    OC -->|"shopping list\nMarkdown"| TG
    OC -->|"weekly plan post\n/plan post"| DC

    %% ── Skill → DB ──────────────────────────────────────────
    FS & FT & MP & PH & SA <-->|"read / write"| DB

    %% ── Skill → External ────────────────────────────────────
    FS -->|"image analysis\ningredient detection"| FAI
    MP -->|"meal generation"| FAI
    PH -->|"price search\nBerlin 2025"| WEB
    SA -->|"send shopping list"| TG
    SA -->|"notify"| DC

    %% ── Install path ────────────────────────────────────────
    SKS -->|"npx skills add\nmary4data/ClawBee"| OC

    %% ── Styles ──────────────────────────────────────────────
    classDef channel   fill:#5865F2,color:#fff,stroke:#4752C4,rx:8
    classDef skill     fill:#1e293b,color:#94a3b8,stroke:#334155,rx:6
    classDef external  fill:#0f172a,color:#64748b,stroke:#1e293b,rx:6
    classDef db        fill:#713f12,color:#fde68a,stroke:#92400e
    classDef user      fill:#166534,color:#bbf7d0,stroke:#15803d
    classDef orch      fill:#7c3aed,color:#ede9fe,stroke:#6d28d9,rx:8
    classDef dist      fill:#0c4a6e,color:#bae6fd,stroke:#075985

    class TG,DC channel
    class FS,FT,MP,PH,SA skill
    class FAI,WEB external
    class DB db
    class User user
    class ORCH orch
    class GH,SKS dist
```

---

## Skills

| Skill | Command | Description |
|---|---|---|
| **orchestrator** | `/plan weekly [budget]` | Full pipeline: fridge → prices → plan → Telegram |
| **fridge-scanner** | `/scan` + photo | Detect ingredients from photo, generate 3-day plan |
| **fridge-tracker** | `/fridge list/add/remove` | Manage pantry inventory |
| **meal-planner** | `/meals plan [budget]` | Weekly 7-day dinner plan |
| **price-hunter** | `/prices search <item>` | Find cheapest prices in Berlin |
| **shopping-agent** | `/shopping send` | Send optimized list to Telegram |

## Quick Start

```
/plan weekly 80          → full pipeline, €80 budget
/scan demo               → demo scan (no photo needed)
/fridge add eggs 12      → add to fridge
/prices search chicken   → find Berlin prices
/shopping send           → push list to Telegram
```

## Stack

- **Runtime**: [OpenClaw](https://openclaw.ai) on Railway
- **LLM**: Featherless AI
- **Channels**: Telegram (shopping lists) + Discord (plan display)
- **Storage**: SQLite (`pantry.db`)
- **Skills**: [skills.sh/mary4data/ClawBee](https://skills.sh/mary4data/ClawBee)

## License

Apache 2.0 — see [LICENSE.txt](LICENSE.txt)
