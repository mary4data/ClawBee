/**
 * OpenClaw Skill: Meal Planner
 * Plans weekly family meals based on preferences, fridge contents, and budget.
 * Commands: /meals plan | /meals suggest <cuisine> | /meals save <name>
 */

import Database from "better-sqlite3";
import path from "path";

const DB_PATH = path.join(process.env.OPENCLAW_WORKSPACE_DIR || "/data/workspace", "pantry.db");

function getDb() {
  const db = new Database(DB_PATH);
  db.exec(`
    CREATE TABLE IF NOT EXISTS meal_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      week TEXT NOT NULL,
      plan_json TEXT NOT NULL,
      budget REAL,
      created_at TEXT DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS family_prefs (
      key TEXT PRIMARY KEY,
      value TEXT
    );
  `);
  return db;
}

function getCurrentWeek() {
  const now = new Date();
  const start = new Date(now);
  start.setDate(now.getDate() - now.getDay() + 1);
  return start.toISOString().split("T")[0];
}

function getFridgeContents(db) {
  try {
    return db.prepare("SELECT item, quantity FROM fridge").all();
  } catch {
    return [];
  }
}

const MEAL_TEMPLATES = {
  monday:    { dinner: "Pasta Bolognese",    ingredients: ["pasta", "ground beef", "tomatoes", "onion", "garlic"] },
  tuesday:   { dinner: "Chicken Stir Fry",   ingredients: ["chicken breast", "bell pepper", "broccoli", "soy sauce", "rice"] },
  wednesday: { dinner: "Lentil Soup",        ingredients: ["lentils", "carrots", "celery", "onion", "vegetable broth"] },
  thursday:  { dinner: "Salmon & Potatoes",  ingredients: ["salmon", "potatoes", "lemon", "dill", "butter"] },
  friday:    { dinner: "Homemade Pizza",     ingredients: ["pizza dough", "tomato sauce", "mozzarella", "toppings"] },
  saturday:  { dinner: "BBQ Chicken",        ingredients: ["chicken", "bbq sauce", "corn", "coleslaw"] },
  sunday:    { dinner: "Roast Vegetables",   ingredients: ["zucchini", "eggplant", "bell pepper", "olive oil", "feta"] },
};

export const skill = {
  name: "meal-planner",
  description: "Plan weekly family meals considering fridge contents and budget.",
  commands: [
    {
      name: "meals",
      description: "Family meal planning",
      async run({ args, reply, agent }) {
        const db = getDb();
        const [action, ...rest] = args;

        if (!action || action === "plan") {
          const budget = parseFloat(rest[0]) || 100;
          const fridge = getFridgeContents(db);
          const fridgeItems = fridge.map(f => f.item);
          const week = getCurrentWeek();

          const lines = ["📅 **Weekly Meal Plan**\n"];
          const allIngredients = new Set();
          const shoppingList = [];

          for (const [day, meal] of Object.entries(MEAL_TEMPLATES)) {
            lines.push(`**${day.charAt(0).toUpperCase() + day.slice(1)}**: ${meal.dinner}`);
            for (const ing of meal.ingredients) {
              allIngredients.add(ing);
              if (!fridgeItems.includes(ing.toLowerCase())) {
                shoppingList.push(ing);
              }
            }
          }

          const plan = { week, meals: MEAL_TEMPLATES, budget, shoppingList };
          db.prepare(`
            INSERT OR REPLACE INTO meal_plans (week, plan_json, budget) VALUES (?, ?, ?)
          `).run(week, JSON.stringify(plan), budget);

          lines.push(`\n💰 Budget: **€${budget}**`);
          lines.push(`\n🛒 **Shopping needed** (${shoppingList.length} items):`);
          lines.push(shoppingList.map(i => `• ${i}`).join("\n"));

          if (fridgeItems.length > 0) {
            lines.push(`\n✅ **Already have**: ${fridgeItems.join(", ")}`);
          }

          lines.push(`\n_Run \`/shopping send\` to send list to Telegram_`);

          return reply(lines.join("\n"));
        }

        if (action === "pref") {
          // Set family preferences: /meals pref people 4
          const [key, ...valParts] = rest;
          const value = valParts.join(" ");
          if (!key || !value) return reply("Usage: `/meals pref <key> <value>` e.g. `/meals pref people 4`");
          db.prepare("INSERT OR REPLACE INTO family_prefs (key, value) VALUES (?, ?)").run(key, value);
          return reply(`✅ Preference set: **${key}** = ${value}`);
        }

        if (action === "show") {
          const week = getCurrentWeek();
          const row = db.prepare("SELECT * FROM meal_plans WHERE week = ?").get(week);
          if (!row) return reply("No plan for this week. Run `/meals plan` first.");
          const plan = JSON.parse(row.plan_json);
          const lines = Object.entries(plan.meals).map(
            ([day, m]) => `**${day}**: ${m.dinner}`
          );
          return reply(`📅 **This Week's Plan:**\n\n${lines.join("\n")}`);
        }

        return reply("Usage: `/meals plan [budget]` | `/meals show` | `/meals pref <key> <value>`");
      }
    }
  ]
};
