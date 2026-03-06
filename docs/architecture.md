# ClawBee Architecture

> AI-powered family meal planning — photo your fridge, get a plan, receive your shopping list on Telegram.

```mermaid
%%{init: {"theme": "dark", "themeVariables": {"primaryColor": "#1e293b", "primaryTextColor": "#f1f5f9", "primaryBorderColor": "#334155", "lineColor": "#64748b", "secondaryColor": "#0f172a", "tertiaryColor": "#0f172a", "background": "#020617", "mainBkg": "#1e293b", "nodeBorder": "#334155", "clusterBkg": "#0f172a", "titleColor": "#f1f5f9", "edgeLabelBackground": "#1e293b", "fontFamily": "ui-monospace, monospace"}}}%%

flowchart TB

    %% ── User ──────────────────────────────────────────────────────
    USER(["👤  Martin\nfamily"])

    %% ── Input channels ────────────────────────────────────────────
    subgraph INPUT ["  📲  Input Channels  "]
        direction LR
        TG_IN["📸  Send fridge photo\n💬  Type /scan or /plan"]
    end

    %% ── Output channels ───────────────────────────────────────────
    subgraph OUTPUT ["  📤  Output Channels  "]
        direction LR
        TG_OUT["📱  Telegram\n🛒  Shopping list"]
        DC_OUT["🎮  Discord\n📅  Weekly meal plan"]
    end

    %% ── Railway ───────────────────────────────────────────────────
    subgraph RAILWAY ["  🚂  Railway Cloud — europe-west4  "]

        subgraph GATEWAY ["  🦞  OpenClaw Gateway  "]

            ORCH(["🚀  Orchestrator\n──────────────\n/plan weekly\n/plan post\n/plan status"])

            subgraph AGENTS ["  Agent Skills  ·  skills.sh/mary4data/ClawBee  "]
                direction LR
                FS(["📸  Fridge\nScanner\n──────\n/scan\n/scan demo\n/scan shop"])
                FT(["🧊  Fridge\nTracker\n──────\n/fridge list\n/fridge add\n/fridge remove"])
                MP(["📅  Meal\nPlanner\n──────\n/meals plan\n/meals show\n/meals pref"])
                PH(["💰  Price\nHunter\n──────\n/prices search\n/prices best\n/prices list"])
                SA(["🛒  Shopping\nAgent\n──────\n/shopping list\n/shopping send\n/shopping optimize"])
            end

            ORCH -->|coordinates| FS & FT & MP & PH & SA
        end

        DB[("🗄️  SQLite\npantry.db\n─────────\nfridge\nmeal_plans\nprices\nlast_scan")]
    end

    %% ── External services ─────────────────────────────────────────
    subgraph EXTERNAL ["  External Services  "]
        direction LR
        AI["🤖  Featherless AI\n─────────────────\nLlama 3.1 405B\nImage analysis\nMeal generation"]
        WEB["🌐  Web Search\n─────────────────\nRewe · Lidl · Aldi\nBerlin 2025 prices"]
    end

    %% ── User flows ────────────────────────────────────────────────
    USER -->|"photo + command"| INPUT
    INPUT --> GATEWAY
    GATEWAY -->|"shopping list"| TG_OUT
    GATEWAY -->|"meal plan post"| DC_OUT
    TG_OUT & DC_OUT --> USER

    %% ── Data flows ────────────────────────────────────────────────
    FS & FT & MP & PH & SA <-->|"read / write"| DB
    FS & MP -->|"inference"| AI
    PH -->|"price search"| WEB
    SA -->|"send list"| TG_OUT
    SA -->|"notify"| DC_OUT

    %% ── Styles ────────────────────────────────────────────────────
    classDef user     fill:#166534,color:#bbf7d0,stroke:#15803d,rx:50
    classDef channel  fill:#1e3a5f,color:#93c5fd,stroke:#1d4ed8
    classDef agent    fill:#1e1b4b,color:#a5b4fc,stroke:#4338ca
    classDef orch     fill:#4c1d95,color:#e9d5ff,stroke:#7c3aed
    classDef external fill:#1c1917,color:#a8a29e,stroke:#44403c
    classDef db       fill:#431407,color:#fed7aa,stroke:#9a3412

    class USER user
    class TG_IN,TG_OUT,DC_OUT channel
    class FS,FT,MP,PH,SA agent
    class ORCH orch
    class AI,WEB external
    class DB db
```

---

## Full Pipeline: `/plan weekly 80`

```mermaid
%%{init: {"theme": "dark"}}%%
sequenceDiagram
    actor User
    participant TG as 📱 Telegram
    participant OC as 🦞 OpenClaw
    participant FT as 🧊 Fridge Tracker
    participant PH as 💰 Price Hunter
    participant MP as 📅 Meal Planner
    participant SA as 🛒 Shopping Agent
    participant AI as 🤖 Featherless AI
    participant DB as 🗄️ pantry.db

    User->>TG: /plan weekly 80
    TG->>OC: inbound message

    OC->>FT: check fridge contents
    FT->>DB: SELECT item FROM fridge
    DB-->>FT: eggs, milk, pasta, onions
    FT-->>OC: 4 items available

    OC->>PH: search Berlin prices
    PH->>PH: web search Rewe/Lidl/Aldi
    PH->>DB: INSERT prices
    PH-->>OC: price table ready

    OC->>MP: generate 7-day plan (€80)
    MP->>AI: plan meals using fridge + prices
    AI-->>MP: Mon:Pasta, Tue:Chicken...
    MP->>DB: INSERT meal_plans
    MP-->>OC: plan + shopping list

    OC->>SA: send shopping list
    SA->>DB: SELECT best prices
    SA->>TG: 🛒 Shopping List (Telegram message)
    TG-->>User: receives list on phone
```

---

## Fridge Scan Flow: `/scan` + photo

```mermaid
%%{init: {"theme": "dark"}}%%
sequenceDiagram
    actor User
    participant TG as 📱 Telegram
    participant FS as 📸 Fridge Scanner
    participant AI as 🤖 Featherless AI
    participant DB as 🗄️ pantry.db

    User->>TG: 📸 photo + /scan
    TG->>FS: image attachment

    FS->>AI: analyze photo → list ingredients
    AI-->>FS: ["eggs","milk","tomatoes","pasta"]

    FS->>AI: search Berlin prices for ingredients
    AI-->>FS: price table

    FS->>AI: generate 3-day meal plan
    AI-->>FS: Day1:Pasta, Day2:Soup, Day3:Omelette

    FS->>DB: save plan + ingredients
    FS->>TG: show 3-day plan + shopping list

    User->>TG: /scan shop
    FS->>TG: 📱 send list to Telegram
```
