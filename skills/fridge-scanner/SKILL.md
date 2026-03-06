---
name: fridge-scanner
description: "Scan a fridge photo to detect ingredients, search Berlin supermarket prices (Rewe/Lidl/Aldi), generate a 3-day meal plan, and send shopping list to Telegram. Trigger on: /scan, /scan demo, /scan plan, /scan shop, or when user sends a fridge/food photo."
metadata: { "openclaw": { "emoji": "📸", "requires": { "env": ["TELEGRAM_BOT_TOKEN", "TELEGRAM_CHAT_ID"] } } }
user-invocable: true
---

# Fridge Scanner

Scan a fridge photo → detect ingredients → search prices → 3-day meal plan → Telegram shopping list.

## Commands

- `/scan` + attached photo — full pipeline
- `/scan demo` — run pipeline with sample ingredients (no photo needed)
- `/scan plan` — show the last saved meal plan
- `/scan shop` — send last shopping list to Telegram

## Pipeline: /scan (with photo) or /scan demo

### Step 1 — Detect Ingredients

If the user attached a photo, analyze it visually:

> "Look at this fridge/food photo and list every visible ingredient. Return a JSON array of strings, max 15 items. Example: ["eggs","milk","tomatoes"]"

For `/scan demo` use this fixed list:
```
["eggs", "milk", "tomatoes", "onions", "pasta", "olive oil", "carrots", "cheese", "garlic", "potatoes"]
```

Report: `Found N ingredients: [list]`

### Step 2 — Search Prices

Use web search to find current Berlin supermarket prices (Rewe, Lidl, Aldi) for the top 8 ingredients. Search query format:
```
"[ingredient] price Rewe Lidl Aldi Berlin 2025"
```

Format results as a table:
```
Item          | Price  | Unit    | Store
pasta         | €1.29  | 500g    | Lidl
eggs          | €1.99  | 12 pack | Aldi
```

### Step 3 — Generate 3-Day Meal Plan

Create a practical 3-day dinner plan for a family of 4 using the detected ingredients. For each day include:
- Meal name
- Ingredients used (from fridge)
- Extra items to buy (with price from Step 2)
- Cook time

Format:
```
Day 1: Pasta Bolognese (30 min)
  Uses: pasta, tomatoes, garlic, onions
  Buy: ground beef 500g €4.99 @ Rewe

Day 2: Vegetable Soup (25 min)
  Uses: carrots, potatoes, onions, garlic
  Buy: vegetable broth €0.89 @ Aldi

Day 3: Omelette & Salad (20 min)
  Uses: eggs, cheese, milk
  Buy: salad mix €1.49 @ Lidl
```

End with:
```
Shopping List:
• ground beef 500g — €4.99 @ Rewe
• vegetable broth — €0.89 @ Aldi
• salad mix — €1.49 @ Lidl

Estimated total: €7.37

Run /scan shop to send this list to Telegram
```

Save the plan summary in a scratch note or session memory so /scan plan and /scan shop can retrieve it.

## Command: /scan plan

Recall the last generated meal plan from session memory and display it. If no plan exists, say: "No scan found. Run /scan or /scan demo first."

## Command: /scan shop

Send the shopping list to Telegram using the message tool:

```json
{
  "action": "send",
  "channel": "telegram",
  "to": "$TELEGRAM_CHAT_ID",
  "message": "Your formatted shopping list here"
}
```

Telegram message format (Markdown):
```
*3-Day Shopping List*

• ground beef 500g — €4.99 @ Rewe
• vegetable broth — €0.89 @ Aldi
• salad mix — €1.49 @ Lidl

*Estimated total: €7.37*

_Sent by your OpenClaw Meal Planner_
```

Confirm: "Shopping list sent to Telegram!" or report the error if the message tool fails.

## Notes

- Always be encouraging and practical
- If image analysis fails, suggest /scan demo
- Keep meal suggestions simple and family-friendly
- Berlin supermarket prices: Aldi/Lidl are cheapest, Rewe slightly more expensive
