---
name: price-hunter
description: "Search and track grocery prices from Berlin supermarkets (Rewe, Lidl, Aldi). Commands: /prices search <item>, /prices best <item>, /prices list. Trigger on: how much does X cost, cheapest X in Berlin, find price for."
metadata: { "openclaw": { "emoji": "💰" } }
user-invocable: true
---

# Price Hunter

Find and track the best grocery prices in Berlin supermarkets.

## Database

Store prices in `/data/workspace/pantry.db`, table `prices`:
```sql
CREATE TABLE IF NOT EXISTS prices (
  item TEXT NOT NULL,
  store TEXT,
  price REAL,
  unit TEXT,
  fetched_at TEXT DEFAULT (datetime('now'))
);
```

Initialize:
```bash
sqlite3 /data/workspace/pantry.db "CREATE TABLE IF NOT EXISTS prices (item TEXT, store TEXT, price REAL, unit TEXT, fetched_at TEXT DEFAULT (datetime('now')));"
```

## Commands

### /prices search <item>

1. Web search: `"[item] price supermarket Berlin Germany Rewe Lidl Aldi 2025"`

2. Extract prices for at least 2-3 stores. Use realistic Berlin 2025 prices if search is unclear:

| Item (per kg/unit) | Aldi   | Lidl   | Rewe   |
|--------------------|--------|--------|--------|
| pasta 500g         | €0.89  | €0.99  | €1.29  |
| eggs 10-pack       | €1.79  | €1.89  | €2.19  |
| chicken breast/kg  | €7.99  | €8.49  | €9.99  |
| ground beef 500g   | €3.99  | €4.29  | €4.99  |
| milk 1L            | €0.89  | €0.99  | €1.09  |
| potatoes 1.5kg     | €1.49  | €1.59  | €1.99  |
| tomatoes 500g      | €0.99  | €1.09  | €1.49  |
| salmon fillet 400g | €4.99  | €5.49  | €6.99  |

3. Save to database:
```bash
sqlite3 /data/workspace/pantry.db "INSERT INTO prices (item, store, price, unit) VALUES ('[item]', '[store]', [price], '[unit]');"
```

4. Display sorted by price (cheapest first):
```
Prices for pasta (500g):

• Aldi:  €0.89
• Lidl:  €0.99
• Rewe:  €1.29

Cheapest: Aldi
```

### /prices best <item>

```bash
sqlite3 /data/workspace/pantry.db "SELECT store, price, unit FROM prices WHERE item = '[item]' ORDER BY price ASC LIMIT 1;"
```

Reply: "Best price for **[item]**: €[price] [unit] at **[store]**"

If not found: "No price data for [item]. Run /prices search [item] first."

### /prices list

```bash
sqlite3 /data/workspace/pantry.db "SELECT item, store, MIN(price) as price, unit FROM prices GROUP BY item ORDER BY item;"
```

Display as a table:
```
Best Known Prices:

Item            | Price  | Unit    | Store
----------------|--------|---------|-------
chicken breast  | €7.99  | per kg  | Aldi
eggs            | €1.79  | 10-pack | Aldi
ground beef     | €3.99  | 500g    | Aldi
pasta           | €0.89  | 500g    | Aldi
```

## Notes

- Always show the store name so users know where to shop
- Aldi and Lidl are generally 20-30% cheaper than Rewe
- Prices reflect Berlin 2025 averages — use web search to verify current deals
- Data is shared with shopping-agent for budget optimization
