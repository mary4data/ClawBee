---
name: fridge-tracker
description: "Track what's in your fridge and pantry. Add, list, remove items. Use when: user says /fridge, asks what's in the fridge, wants to add/remove pantry items."
metadata: { "openclaw": { "emoji": "🧊" } }
user-invocable: true
---

# Fridge Tracker

Maintain a persistent fridge and pantry inventory using a local SQLite database.

## Database

Store inventory in `/data/workspace/pantry.db`, table `fridge`:
```sql
CREATE TABLE IF NOT EXISTS fridge (
  item TEXT NOT NULL UNIQUE,
  quantity TEXT,
  updated_at TEXT DEFAULT (datetime('now'))
);
```

Use `bash` with `sqlite3 /data/workspace/pantry.db` for all database operations.

## Commands

### /fridge list (default)

```bash
sqlite3 /data/workspace/pantry.db "SELECT item, quantity, updated_at FROM fridge ORDER BY item;"
```

Display as:
```
Current Fridge Contents:

• eggs — 12 pack (updated 2025-03-06)
• milk — 2L (updated 2025-03-06)
• tomatoes — 500g (updated 2025-03-06)
```

If empty: "Fridge is empty. Add items with /fridge add <item> <quantity>"

### /fridge add <item> [quantity]

```bash
sqlite3 /data/workspace/pantry.db "INSERT OR REPLACE INTO fridge (item, quantity, updated_at) VALUES ('<item>', '<quantity>', datetime('now'));"
```

Reply: "Added **[item]** ([quantity]) to fridge."

### /fridge remove <item>

```bash
sqlite3 /data/workspace/pantry.db "DELETE FROM fridge WHERE item = '<item>';"
```

Reply: "Removed **[item]** from fridge." or "Item **[item]** not found."

### /fridge clear

```bash
sqlite3 /data/workspace/pantry.db "DELETE FROM fridge;"
```

Reply: "Fridge cleared."

## Tips

- Always lowercase item names when storing
- If sqlite3 is not available, maintain inventory in session memory as a fallback
- The fridge data is shared with the meal-planner and shopping-agent skills
