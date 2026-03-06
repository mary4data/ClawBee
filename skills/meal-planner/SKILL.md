---
name: meal-planner
description: "Plan weekly family meals based on fridge contents and budget. Commands: /meals plan [budget], /meals show, /meals pref <key> <value>. Trigger on: weekly meal planning, what should we eat, dinner ideas."
metadata: { "openclaw": { "emoji": "📅" } }
user-invocable: true
---

# Meal Planner

Generate a practical weekly dinner plan for a family of 4, using fridge contents and a budget.

## Default Weekly Template

Use these meals as a baseline (adapt based on fridge contents):

| Day       | Dinner               | Key Ingredients                          |
|-----------|----------------------|------------------------------------------|
| Monday    | Pasta Bolognese      | pasta, ground beef, tomatoes, garlic     |
| Tuesday   | Chicken Stir Fry     | chicken, bell pepper, broccoli, rice     |
| Wednesday | Lentil Soup          | lentils, carrots, celery, onion          |
| Thursday  | Salmon & Potatoes    | salmon, potatoes, lemon, dill            |
| Friday    | Homemade Pizza       | dough, tomato sauce, mozzarella          |
| Saturday  | BBQ Chicken          | chicken, bbq sauce, corn                 |
| Sunday    | Roast Vegetables     | zucchini, bell pepper, feta              |

## Commands

### /meals plan [budget]

1. Check fridge contents:
```bash
sqlite3 /data/workspace/pantry.db "SELECT item FROM fridge;" 2>/dev/null
```

2. Generate the week's plan. For each day:
   - Prefer meals that use what's already in the fridge
   - Mark ingredients as "have" (from fridge) or "buy" (missing)

3. Display:
```
Weekly Meal Plan — Budget: €[budget]

Monday:    Pasta Bolognese (30 min)
Tuesday:   Chicken Stir Fry (25 min)
Wednesday: Lentil Soup (20 min)
Thursday:  Salmon & Potatoes (35 min)
Friday:    Homemade Pizza (40 min)
Saturday:  BBQ Chicken (30 min)
Sunday:    Roast Vegetables (25 min)

Already have: [items from fridge]

Shopping needed ([N] items):
• ground beef 500g
• chicken breast 600g
• salmon fillet 400g
[...]

Run /shopping send to send list to Telegram
```

4. Save plan to database:
```bash
sqlite3 /data/workspace/pantry.db "
CREATE TABLE IF NOT EXISTS meal_plans (week TEXT PRIMARY KEY, plan_json TEXT, budget REAL, created_at TEXT DEFAULT (datetime('now')));
INSERT OR REPLACE INTO meal_plans (week, plan_json, budget) VALUES ('[WEEK_DATE]', '[ESCAPED_JSON]', [budget]);
"
```

### /meals show

```bash
sqlite3 /data/workspace/pantry.db "SELECT plan_json FROM meal_plans ORDER BY created_at DESC LIMIT 1;"
```

Display the saved plan in a readable format. If none exists: "No meal plan yet. Run /meals plan first."

### /meals pref <key> <value>

Store family preferences:
```bash
sqlite3 /data/workspace/pantry.db "
CREATE TABLE IF NOT EXISTS family_prefs (key TEXT PRIMARY KEY, value TEXT);
INSERT OR REPLACE INTO family_prefs VALUES ('<key>', '<value>');
"
```

Examples: `/meals pref people 4`, `/meals pref vegetarian yes`, `/meals pref budget 80`

Reply: "Preference set: **[key]** = [value]"

## Notes

- Default family size: 4 people
- Default budget: €100/week
- Prioritize simple, practical meals with <40 min prep time
- Always show what's already in the fridge vs. what to buy
- Berlin supermarket context: Aldi/Lidl for staples, Rewe for quality items
