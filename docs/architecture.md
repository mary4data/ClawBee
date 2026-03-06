# ClawBee — How It Works

> Photo your fridge → AI plans your week → shopping list lands on Telegram.

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
        FS["📸 Fridge Scanner"]
        FT["🧊 Fridge Tracker"]
        MP["📅 Meal Planner"]
        PH["💰 Price Hunter"]
        SA["🛒 Shopping Agent"]
        DB[("🗄️ pantry.db")]
    end

    AI["🤖 Featherless AI"]
    WEB["🌐 Web Search"]

    USER -->|"photo / command"| TG
    TG -->|"message"| ORCH

    ORCH --> FS --> AI
    ORCH --> FT
    ORCH --> MP --> AI
    ORCH --> PH --> WEB
    ORCH --> SA

    FS & FT & MP & PH & SA --- DB

    SA -->|"shopping list"| TG
    SA -->|"meal plan"| DC
    TG & DC -->|"delivers"| USER

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

## Weekly Plan Flow

```mermaid
%%{init: {"theme": "dark"}}%%
flowchart TD
    A(["👤 /plan weekly 80"]) --> B["🧊 Check fridge\nwhat do we have?"]
    B --> C["💰 Search prices\nRewe · Lidl · Aldi"]
    C --> D["📅 Generate 7-day plan\nwithin €80 budget"]
    D --> E["🛒 Build shopping list\ngrouped by store"]
    E --> F(["📱 Telegram\n🛒 Shopping list delivered"])
    E --> G(["🎮 Discord\n📅 Meal plan posted"])

    style A fill:#166534,color:#bbf7d0,stroke:#15803d
    style B fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style C fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style D fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style E fill:#4c1d95,color:#e9d5ff,stroke:#7c3aed
    style F fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
    style G fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
```

---

## Fridge Scan Flow

```mermaid
%%{init: {"theme": "dark"}}%%
flowchart TD
    A(["📸 Send fridge photo\n+ /scan"]) --> B["🤖 AI detects ingredients\neggs · milk · pasta · tomatoes"]
    B --> C["💰 Look up Berlin prices\nfor each ingredient"]
    C --> D["🤖 AI creates 3-day plan\nusing what you have"]
    D --> E(["📱 /scan shop\nSend list to Telegram"])

    style A fill:#166534,color:#bbf7d0,stroke:#15803d
    style B fill:#1c1917,color:#d6d3d1,stroke:#57534e
    style C fill:#1e1b4b,color:#c4b5fd,stroke:#4338ca
    style D fill:#1c1917,color:#d6d3d1,stroke:#57534e
    style E fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
```

---

## Commands

| Command | What it does |
|---|---|
| `/plan weekly 80` | Full pipeline — fridge → prices → plan → Telegram |
| `/scan` + photo | Scan fridge photo → instant 3-day plan |
| `/scan demo` | Try without a photo |
| `/scan shop` | Send plan's shopping list to Telegram |
| `/fridge add eggs 12` | Track what's in your fridge |
| `/prices search chicken` | Find cheapest price in Berlin |
| `/shopping optimize 60` | Check list against budget |
