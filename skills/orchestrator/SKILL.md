---
name: orchestrator
description: "Run the full family meal planning pipeline in one command. Coordinates fridge check, price search, meal plan, and Telegram delivery. Commands: /plan weekly [budget], /plan status, /plan post, /plan help."
metadata: { "openclaw": { "emoji": "🚀" } }
user-invocable: true
---

# Meal Planning Orchestrator

Runs the full pipeline: fridge check → price search → meal plan → Telegram shopping list.

## Commands

### /plan weekly [budget]

Run the complete 4-step pipeline. Default budget: €100.

Announce each step as you go:

**Step 1/4 — Fridge Check**
Check current fridge contents:
```bash
sqlite3 /data/workspace/pantry.db "SELECT item, quantity FROM fridge;" 2>/dev/null
```
Report what's available.

**Step 2/4 — Price Search**
Use web search to find current Berlin prices for weekly staples:
- pasta, chicken breast, ground beef, salmon, lentils, rice, potatoes, tomatoes

Search: `"[item] price supermarket Berlin 2025 Rewe Lidl Aldi"`

Report the cheapest option found for each.

**Step 3/4 — Generate Meal Plan**
Create a 7-day dinner plan for a family of 4 within the €[budget] budget.
- Use fridge contents from Step 1
- Use prices from Step 2
- Follow the meal-planner skill format

Save to database.

**Step 4/4 — Send to Telegram**
Send the shopping list via the message tool:
```json
{
  "action": "send",
  "channel": "telegram",
  "to": "$TELEGRAM_CHAT_ID",
  "message": "*Weekly Shopping List*\n\n[items with prices]\n\n*Total: €[amount]*\n\n_Family Meal Planner_"
}
```

End with a summary:
```
Pipeline complete!
• Meal plan saved for this week
• Shopping list sent to Telegram ([N] items, ~€[total])
• Run /plan post to share plan to Discord
```

### /plan status

Quick status check — run each and summarize:
```bash
sqlite3 /data/workspace/pantry.db "SELECT COUNT(*) FROM fridge;" 2>/dev/null
sqlite3 /data/workspace/pantry.db "SELECT week, budget FROM meal_plans ORDER BY created_at DESC LIMIT 1;" 2>/dev/null
```

Display:
```
Meal Planner Status:
• Fridge: [N] items tracked
• Latest plan: week of [date], budget €[amount]
• Run /plan weekly [budget] to refresh
```

### /plan post

Post this week's meal plan to Discord using the message tool:

```json
{
  "action": "send",
  "channel": "discord",
  "to": "channel:$DISCORD_CHANNEL_ID",
  "message": "**This Week's Family Meal Plan**\n\n[7-day plan]\n\nReact with ✅ if you approve!"
}
```

### /plan help

Show all available commands across all ClawBee skills:

```
Family Meal Planner — Commands

/plan weekly [budget]   Full pipeline (fridge + prices + plan + Telegram)
/plan status            Check system status
/plan post              Post plan to Discord

/fridge list            Show fridge contents
/fridge add <item> [qty] Add item
/fridge remove <item>   Remove item

/scan [photo]           Scan fridge photo → instant plan
/scan demo              Demo mode (no photo needed)
/scan shop              Send scan's shopping list to Telegram

/meals plan [budget]    Generate weekly plan
/meals show             Show current plan

/prices search <item>   Find cheapest price in Berlin
/prices list            Show all tracked prices

/shopping list          View optimized shopping list
/shopping send          Send to Telegram
/shopping optimize [€]  Check against budget
```

## Notes

- The orchestrator is the main entry point for first-time users
- Always show progress indicators (Step 1/4, etc.) for pipeline commands
- If any step fails, continue with remaining steps and note the failure
