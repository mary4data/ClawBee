---
name: fridge-scanner
description: "Scan a fridge or food photo to detect ingredients, look up Berlin supermarket prices, generate a 3-day family meal plan, and send the shopping list to Telegram. Triggers on: /scan, /scan demo, /scan plan, /scan shop, or when a user attaches a fridge/food photo and asks for meal ideas or a shopping list."
license: Complete terms in LICENSE.txt
---

# Fridge Scanner

Photo → ingredients → prices → 3-day meal plan → Telegram shopping list.

## Commands

| Command | Description |
|---------|-------------|
| `/scan` + photo | Full pipeline with image |
| `/scan demo` | Pipeline with sample ingredients (no photo) |
| `/scan plan` | Show last saved plan |
| `/scan shop` | Send last shopping list to Telegram |

## Pipeline (`/scan` or `/scan demo`)

Run these steps in sequence. Announce each step as you go.

### Step 1 — Init DB
```bash
bash skills/fridge-scanner/scripts/init-db.sh
```

### Step 2 — Detect Ingredients
- **With photo**: Analyze the image — list every visible food item as a JSON array (max 15 items)
- **Demo mode**: Use `["eggs","milk","tomatoes","onions","pasta","olive oil","carrots","cheese","garlic","potatoes"]`

### Step 3 — Search Prices
Web search: `"[ingredient] price Rewe Lidl Aldi Berlin 2025"` for the top 8 ingredients.
See `references/berlin-prices.md` for typical price ranges.

### Step 4 — Generate 3-Day Plan
Create a practical dinner plan for a family of 4. See `references/pipeline.md` for output format.

### Step 5 — Save & Display
```bash
bash skills/fridge-scanner/scripts/save-plan.sh '[ingredients_json]' '[plan_json]'
```
Display plan and shopping list, then: "Run `/scan shop` to send to Telegram."

## `/scan plan`
```bash
bash skills/fridge-scanner/scripts/load-plan.sh
```

## `/scan shop`
Send via the message tool:
```json
{"action":"send","channel":"telegram","to":"$TELEGRAM_CHAT_ID","message":"*Shopping List*\n\n[items]\n\n*Total: €[amount]*\n\n_OpenClaw Meal Planner_"}
```
