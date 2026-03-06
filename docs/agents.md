# How the ClawBee Agents Work Together

```
┌─────────────────────────────────────────────────────────────────┐
│                          YOU                                    │
│                                                                 │
│   📸 Send fridge photo          📋 Receive shopping list        │
│   💬 Type a command             📅 See weekly meal plan         │
└───────────────┬─────────────────────────────┬───────────────────┘
                │                             │
                ▼                             ▼
┌──────────────────────┐         ┌────────────────────────┐
│   📱 TELEGRAM BOT    │         │      🎮 DISCORD         │
│                      │         │                        │
│  Receives commands   │         │  Shows meal plan posts │
│  Sends shopping list │         │  Bot activity updates  │
└──────────┬───────────┘         └────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────────┐
│                    🦞 OPENCLAW GATEWAY  (Railway)                │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  🚀 ORCHESTRATOR                         │    │
│  │                  /plan weekly 80                         │    │
│  │                                                          │    │
│  │   Coordinates all agents in sequence:                    │    │
│  │   Step 1 → Step 2 → Step 3 → Step 4                     │    │
│  └──────┬──────────┬──────────┬──────────┬─────────────────┘    │
│         │          │          │          │                       │
│         ▼          ▼          ▼          ▼                       │
│  ┌──────────┐ ┌─────────┐ ┌────────┐ ┌──────────┐              │
│  │📸 FRIDGE │ │🧊 FRIDGE│ │📅 MEAL │ │💰 PRICE  │              │
│  │SCANNER   │ │TRACKER  │ │PLANNER │ │HUNTER    │              │
│  │          │ │         │ │        │ │          │              │
│  │/scan     │ │/fridge  │ │/meals  │ │/prices   │              │
│  │/scan demo│ │list     │ │plan    │ │search    │              │
│  │/scan shop│ │add      │ │show    │ │best      │              │
│  └────┬─────┘ └────┬────┘ └───┬────┘ └────┬─────┘              │
│       │            │          │            │                     │
│       └────────────┴──────────┴────────────┘                    │
│                              │                                   │
│                              ▼                                   │
│                    ┌──────────────────┐                          │
│                    │  🛒 SHOPPING     │                          │
│                    │  AGENT           │                          │
│                    │                  │                          │
│                    │  /shopping list  │                          │
│                    │  /shopping send  │                          │
│                    └────────┬─────────┘                          │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐
  │  🤖 FEATHERLESS│  │ 🗄️  SQLITE   │  │  🌐 WEB SEARCH   │
  │     AI         │  │  pantry.db   │  │                  │
  │                │  │              │  │  Rewe prices     │
  │  Understands   │  │  fridge      │  │  Lidl prices     │
  │  photos        │  │  meal_plans  │  │  Aldi prices     │
  │  Plans meals   │  │  prices      │  │  Berlin 2025     │
  │  Writes lists  │  │  last_scan   │  │                  │
  └────────────────┘  └──────────────┘  └──────────────────┘
```

---

## A Full Run: `/plan weekly 80`

```
You ──▶ Telegram ──▶ OpenClaw
                         │
                         ▼
              [Orchestrator starts]
                         │
              ┌──────────▼──────────┐
              │ 1. Fridge Tracker   │  "What's in the fridge?"
              │    reads pantry.db  │  eggs, milk, pasta, onions
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │ 2. Price Hunter     │  Searches web for Berlin
              │    web search       │  supermarket prices
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │ 3. Meal Planner     │  Generates 7-day plan
              │    Featherless AI   │  using fridge + prices
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │ 4. Shopping Agent   │  Builds optimised list
              │    sends Telegram   │  grouped by store
              └──────────┬──────────┘
                         │
                         ▼
              📱 You receive shopping list on Telegram
```

---

## Fridge Photo Flow: `/scan`

```
You send photo + /scan
         │
         ▼
  Fridge Scanner
         │
         ├──▶ Featherless AI  ──▶  detects ingredients
         │                         ["eggs","milk","tomatoes"]
         │
         ├──▶ Web Search      ──▶  Berlin prices per item
         │
         ├──▶ Featherless AI  ──▶  generates 3-day plan
         │
         ├──▶ pantry.db       ──▶  saves plan
         │
         └──▶ Telegram        ──▶  sends shopping list
```

---

## Agent Responsibilities

| Agent | Owns | Reads | Sends to |
|---|---|---|---|
| Orchestrator | Pipeline flow | nothing | all agents |
| Fridge Scanner | Photo analysis | image + pantry.db | Telegram |
| Fridge Tracker | Inventory | pantry.db | — |
| Meal Planner | Weekly plan | pantry.db + fridge | pantry.db |
| Price Hunter | Price data | web + pantry.db | pantry.db |
| Shopping Agent | List delivery | pantry.db | Telegram + Discord |
