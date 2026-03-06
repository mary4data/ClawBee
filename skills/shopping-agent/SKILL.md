---
name: shopping-agent
description: "Generate an optimized shopping list from the current meal plan, grouped by store, and send it to Telegram and Discord. Triggers on: /shopping list, /shopping send, /shopping optimize [budget], 'send shopping list', 'what do I need to buy', 'shopping for the week', or after meal planning is complete."
license: Complete terms in LICENSE.txt
---

# Shopping Agent

Optimized shopping list from meal plan → Telegram + Discord delivery.

## `/shopping list`
1. Load meal plan:
   ```bash
   sqlite3 /data/workspace/pantry.db "SELECT plan_json FROM meal_plans ORDER BY created_at DESC LIMIT 1;" 2>/dev/null
   ```
2. Load fridge (to exclude already-owned items):
   ```bash
   sqlite3 /data/workspace/pantry.db "SELECT item FROM fridge;" 2>/dev/null
   ```
3. Load best prices:
   ```bash
   sqlite3 /data/workspace/pantry.db "SELECT item, store, MIN(price) as price, unit FROM prices GROUP BY item;" 2>/dev/null
   ```
4. Display grouped by store, cheapest first. See `references/display-format.md` for output format.

If no plan: "No meal plan found. Run `/meals plan` or `/plan weekly` first."

## `/shopping send`
Build Telegram message and send:
```json
{"action":"send","channel":"telegram","to":"$TELEGRAM_CHAT_ID","message":"*Shopping List*\n\n*Aldi*\n• pasta 500g — €0.89\n\n*Lidl*\n• chicken — €5.09\n\n*Estimated total: €[amount]*\n\n_OpenClaw Meal Planner_"}
```

Also notify Discord:
```json
{"action":"send","channel":"discord","to":"channel:$DISCORD_CHANNEL_ID","message":"Shopping list sent to Telegram! Check your phone."}
```

Fallback if Telegram fails: display full list in chat with error message.

## `/shopping optimize [budget]`
Default budget: €80.
- Calculate total from price data
- If within budget: "Fits within €[budget]. Estimated: €[total]."
- If over: suggest cheaper substitutions (e.g., canned tuna instead of salmon)

See `references/display-format.md` for substitution suggestions.
