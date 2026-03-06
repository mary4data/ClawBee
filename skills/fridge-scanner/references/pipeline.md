# Fridge Scanner — Pipeline Output Format

## 3-Day Meal Plan Display

```
Day 1: Pasta Bolognese (30 min)
  Uses: pasta, tomatoes, garlic, onions
  Buy: ground beef 500g — €4.99 @ Rewe

Day 2: Vegetable Soup (25 min)
  Uses: carrots, potatoes, onions, garlic
  Buy: vegetable broth — €0.89 @ Aldi

Day 3: Omelette & Salad (20 min)
  Uses: eggs, cheese, milk
  Buy: salad mix — €1.49 @ Lidl
```

## Shopping List Display

```
Shopping List:
• ground beef 500g — €4.99 @ Rewe
• vegetable broth — €0.89 @ Aldi
• salad mix — €1.49 @ Lidl

Estimated total: €7.37

Run /scan shop to send this list to Telegram
```

## Telegram Message Format (Markdown)

```
*3-Day Shopping List*

• ground beef 500g — €4.99 @ Rewe
• vegetable broth — €0.89 @ Aldi
• salad mix — €1.49 @ Lidl

*Estimated total: €7.37*

_Sent by your OpenClaw Meal Planner_
```

## Progress Messages

Announce each step:
- "Step 1/4: Scanning image for ingredients..."
- "Found N ingredients: [list]"
- "Step 2/4: Searching Berlin supermarket prices..."
- "Step 3/4: Generating 3-day meal plan..."
- "Step 4/4: Saving plan..."
