# ClawBee — How It Works

> Photo your fridge → AI agents collaborate → shopping list lands on Telegram.

---

## System Overview

```mermaid
%%{init: {"theme": "dark"}}%%
flowchart LR

    USER(["👤 You"])
    TG["📱 Telegram"]
    DC["🎮 Discord"]

    subgraph OC ["🦞 OpenClaw  ·  Railway"]
        ORCH["🚀 Orchestrator"]

        subgraph AGENTS ["  Agent Skills  "]
            FS["📸 Fridge\nScanner"]
            FT["🧊 Fridge\nTracker"]
            MP["📅 Meal\nPlanner"]
            PH["💰 Price\nHunter"]
            SA["🛒 Shopping\nAgent"]
        end

        DB[("🗄️ pantry.db")]
    end

    AI["🤖 Featherless AI"]
    WEB["🌐 Web Search"]

    USER -->|"photo / command"| TG
    TG --> ORCH
    ORCH -->|"triggers"| FS & FT & MP & PH & SA

    %% Agent-to-agent communication
    FS -->|"syncs ingredients"| FT
    FT -->|"shares inventory"| MP
    PH -->|"shares prices"| SA
    MP -->|"shares plan"| SA
    SA -->|"budget feedback"| MP

    FS & MP --> AI
    PH --> WEB
    FS & FT & MP & PH & SA <--> DB

    SA -->|"shopping list"| TG
    SA -->|"meal plan"| DC
    TG & DC --> USER

    classDef user    fill:#166534,color:#bbf7d0,stroke:#15803d
    classDef channel fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
    classDef skill   fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    classDef orch    fill:#4c1d95,color:#e9d5ff,stroke:#7c3aed
    classDef ext     fill:#1c1917,color:#d6d3d1,stroke:#57534e
    classDef db      fill:#431407,color:#fed7aa,stroke:#9a3412

    class USER user
    class TG,DC channel
    class FS,FT,MP,PH,SA skill
    class ORCH orch
    class AI,WEB ext
    class DB db
```

---

## Agent-to-Agent Communication

Agents share results directly — no need to route everything through the orchestrator.

```mermaid
%%{init: {"theme": "dark"}}%%
flowchart TD

    FS["📸 Fridge Scanner\ndetects ingredients from photo"]
    FT["🧊 Fridge Tracker\nmaintains live inventory"]
    PH["💰 Price Hunter\nfinds cheapest Berlin prices"]
    MP["📅 Meal Planner\ncreates weekly dinner plan"]
    SA["🛒 Shopping Agent\nbuilds & delivers list"]

    FS -->|"1 · auto-adds detected\ningredients to inventory"| FT
    FT -->|"2 · tells planner\nwhat we already have"| MP
    PH -->|"3 · sends price table\nto shopping agent"| SA
    MP -->|"4 · sends plan +\nshopping list"| SA
    SA -->|"5 · if over budget:\nask planner to adjust"| MP

    style FS fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style FT fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style PH fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style MP fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style SA fill:#4c1d95,color:#e9d5ff,stroke:#7c3aed
```

| From | To | What is shared |
|---|---|---|
| Fridge Scanner | Fridge Tracker | Detected ingredients → auto-added to inventory |
| Fridge Tracker | Meal Planner | Current stock → planner skips items already owned |
| Price Hunter | Shopping Agent | Best prices per store → used for cost estimates |
| Meal Planner | Shopping Agent | Weekly plan + missing ingredients list |
| Shopping Agent | Meal Planner | Over-budget signal → planner swaps expensive meals |

---

## Weekly Plan Flow

```mermaid
%%{init: {"theme": "dark"}}%%
flowchart TD
    A(["👤 /plan weekly 80"])
    B["🧊 Fridge Tracker\nwhat do we have?"]
    C["💰 Price Hunter\nRewe · Lidl · Aldi"]
    D["📅 Meal Planner\n7-day plan within €80"]
    E{"within budget?"}
    F["📅 Meal Planner\nadjusts — swaps meals"]
    G["🛒 Shopping Agent\ngrouped by store"]
    H(["📱 Telegram\n🛒 list delivered"])
    I(["🎮 Discord\n📅 plan posted"])

    A --> B --> C --> D --> E
    E -->|"yes"| G
    E -->|"no — feedback loop"| F --> G
    G --> H & I

    style A fill:#166534,color:#bbf7d0,stroke:#15803d
    style E fill:#78350f,color:#fde68a,stroke:#92400e
    style F fill:#4c1d95,color:#e9d5ff,stroke:#7c3aed
    style H fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
    style I fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
```

---

## Fridge Scan Flow

```mermaid
%%{init: {"theme": "dark"}}%%
flowchart TD
    A(["📸 photo + /scan"])
    B["🤖 AI detects ingredients\neggs · milk · pasta · tomatoes"]
    C["🧊 Fridge Tracker\nauto-syncs detected items\nto pantry inventory"]
    D["💰 Price Hunter\nlooks up Berlin prices"]
    E["🤖 AI creates 3-day plan\nusing what you already have"]
    F(["📱 /scan shop\nlist sent to Telegram"])

    A --> B -->|"agent handoff"| C --> D --> E --> F

    style A fill:#166534,color:#bbf7d0,stroke:#15803d
    style C fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style F fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
```
