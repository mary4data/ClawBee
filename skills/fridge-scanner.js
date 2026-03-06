/**
 * OpenClaw Skill: Fridge Scanner MVP
 * Upload a fridge/food photo → detect ingredients → search prices → 3-day meal plan
 * 
 * Commands:
 *   /scan          — upload a fridge photo to detect ingredients
 *   /scan demo     — run with a demo ingredient list (no image needed)
 *   /scan plan     — generate 3-day plan from last scan
 *   /scan shop     — send shopping list to Telegram
 */

import Database from "better-sqlite3";
import path from "path";

const DB_PATH = path.join(process.env.OPENCLAW_WORKSPACE_DIR || "/data/workspace", "pantry.db");
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;

// ─── DB Setup ────────────────────────────────────────────────────────────────

function getDb() {
  const db = new Database(DB_PATH);
  db.exec(`
    CREATE TABLE IF NOT EXISTS last_scan (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      ingredients TEXT,
      prices TEXT,
      plan TEXT,
      scanned_at TEXT DEFAULT (datetime('now'))
    );
  `);
  return db;
}

// ─── Telegram ────────────────────────────────────────────────────────────────

async function sendTelegram(text) {
  if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) return null;
  const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text, parse_mode: "Markdown" })
  });
  return res.json();
}

// ─── AI Helpers (uses OpenClaw's built-in agent.ai) ──────────────────────────

async function detectIngredientsFromImage(agent, imageUrl) {
  return agent.ai({
    role: "You are a kitchen assistant. Look at this fridge or food photo and list every visible ingredient or food item. Return ONLY a JSON array of strings, max 15 items. Example: [\"eggs\", \"milk\", \"tomatoes\"]",
    image: imageUrl
  });
}

async function searchPricesForIngredients(agent, ingredients) {
  const list = ingredients.slice(0, 8).join(", ");
  return agent.ai({
    role: "You are a grocery price researcher in Berlin, Germany.",
    prompt: `Search current supermarket prices (Rewe, Lidl, Aldi) in Berlin for these ingredients: ${list}.
Return ONLY a JSON array like:
[
  {"item": "eggs", "price": 1.99, "unit": "12 pack", "store": "Lidl"},
  {"item": "milk", "price": 0.89, "unit": "1L", "store": "Aldi"}
]
Only include items from the list. Use realistic Berlin 2025 prices.`,
    tools: ["web_search"]
  });
}

async function generateMealPlan(agent, ingredients, prices) {
  const ingList = ingredients.join(", ");
  const priceMap = prices.map(p => `${p.item} €${p.price} (${p.store})`).join(", ");

  return agent.ai({
    role: "You are a family meal planner. Create simple, practical meals.",
    prompt: `Available ingredients: ${ingList}
Known prices: ${priceMap}

Create a 3-day dinner plan for a family of 4.
- Use the available ingredients as much as possible
- List extra items to buy with estimated cost
- Keep total shopping cost under €30

Return ONLY this JSON structure:
{
  "days": [
    {
      "day": "Day 1",
      "meal": "Pasta Bolognese",
      "uses": ["pasta", "tomatoes", "ground beef"],
      "buy": [{"item": "ground beef", "price": 4.99, "store": "Rewe"}],
      "time": "30 min"
    }
  ],
  "total_cost": 18.50,
  "shopping_list": ["ground beef 500g - €4.99 @ Rewe", "cheese - €2.49 @ Lidl"]
}`
  });
}

// ─── Parsers ─────────────────────────────────────────────────────────────────

function safeParseJSON(text, fallback) {
  try {
    const match = text.match(/(\[[\s\S]*\]|\{[\s\S]*\})/);
    if (match) return JSON.parse(match[0]);
  } catch {}
  return fallback;
}

function formatPlanTable(days) {
  const lines = [
    "```",
    "┌─────────┬──────────────────────┬──────────┬──────────────┐",
    "│ Day     │ Meal                 │ Cook Time│ Extra Cost   │",
    "├─────────┼──────────────────────┼──────────┼──────────────┤",
  ];
  for (const d of days) {
    const day = d.day.padEnd(7);
    const meal = d.meal.substring(0, 20).padEnd(20);
    const time = (d.time || "30 min").padEnd(8);
    const cost = d.buy?.length
      ? `€${d.buy.reduce((s, b) => s + (b.price || 0), 0).toFixed(2)}`.padEnd(12)
      : "€0.00".padEnd(12);
    lines.push(`│ ${day} │ ${meal} │ ${time} │ ${cost} │`);
  }
  lines.push("└─────────┴──────────────────────┴──────────┴──────────────┘");
  lines.push("```");
  return lines.join("\n");
}

function formatPriceTable(prices) {
  if (!prices?.length) return "_No price data_";
  const lines = [
    "```",
    "┌────────────────────┬────────┬───────────┬─────────┐",
    "│ Item               │ Price  │ Unit      │ Store   │",
    "├────────────────────┼────────┼───────────┼─────────┤",
  ];
  for (const p of prices.slice(0, 8)) {
    const item = (p.item || "").substring(0, 18).padEnd(18);
    const price = `€${parseFloat(p.price || 0).toFixed(2)}`.padEnd(6);
    const unit = (p.unit || "").substring(0, 9).padEnd(9);
    const store = (p.store || "").substring(0, 7).padEnd(7);
    lines.push(`│ ${item} │ ${price} │ ${unit} │ ${store} │`);
  }
  lines.push("└────────────────────┴────────┴───────────┴─────────┘");
  lines.push("```");
  return lines.join("\n");
}

// ─── Main Skill ──────────────────────────────────────────────────────────────

export const skill = {
  name: "fridge-scanner",
  description: "Scan a fridge photo, find prices, generate a 3-day meal plan.",

  commands: [
    {
      name: "scan",
      description: "Scan fridge image and generate 3-day meal plan",

      async run({ args, reply, agent, message }) {
        const db = getDb();
        const [action] = args;

        // ── /scan shop ──────────────────────────────────────────────────────
        if (action === "shop") {
          const row = db.prepare("SELECT plan FROM last_scan WHERE id = 1").get();
          if (!row) return reply("❌ No scan found. Run `/scan` or `/scan demo` first.");

          const plan = safeParseJSON(row.plan, null);
          if (!plan) return reply("❌ Could not read plan. Please re-run `/scan`.");

          const tgLines = [
            "🛒 *3-Day Shopping List*",
            "",
            ...(plan.shopping_list || []).map(i => `• ${i}`),
            "",
            `💰 *Estimated total: €${plan.total_cost?.toFixed(2) || "?"}*`,
            "",
            "_Sent by your OpenClaw Meal Planner 🦞_"
          ];

          const result = await sendTelegram(tgLines.join("\n"));
          if (result?.ok) {
            return reply("✅ Shopping list sent to Telegram!");
          } else {
            return reply([
              "❌ Telegram not configured.",
              "Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` in Railway env vars.",
              "",
              "**Shopping list:**",
              ...(plan.shopping_list || []).map(i => `• ${i}`),
              `\n💰 Total: €${plan.total_cost?.toFixed(2) || "?"}`
            ].join("\n"));
          }
        }

        // ── /scan plan ──────────────────────────────────────────────────────
        if (action === "plan") {
          const row = db.prepare("SELECT ingredients, prices, plan FROM last_scan WHERE id = 1").get();
          if (!row) return reply("❌ No scan found. Run `/scan` or `/scan demo` first.");

          const plan = safeParseJSON(row.plan, null);
          if (!plan?.days) return reply("❌ No plan data. Re-run `/scan`.");

          return reply([
            "📅 **3-Day Meal Plan**\n",
            formatPlanTable(plan.days),
            "",
            "🛒 **Shopping needed:**",
            ...(plan.shopping_list || []).map(i => `• ${i}`),
            "",
            `💰 **Estimated cost: €${plan.total_cost?.toFixed(2) || "?"}**`,
            "",
            "_Run `/scan shop` to send this to Telegram_"
          ].join("\n"));
        }

        // ── /scan demo ──────────────────────────────────────────────────────
        if (action === "demo") {
          await reply("🧪 **Demo mode** — using sample ingredients\n");
          const demoIngredients = ["eggs", "milk", "tomatoes", "onions", "pasta", "olive oil", "carrots", "cheese", "garlic", "potatoes"];
          return runPipeline(agent, reply, db, demoIngredients, null);
        }

        // ── /scan (with image) ───────────────────────────────────────────────
        const imageUrl = message?.attachments?.[0]?.url || message?.image?.url || null;

        if (!imageUrl) {
          return reply([
            "📸 **Fridge Scanner**",
            "",
            "Send a photo of your fridge or food table and I'll:",
            "1. 🔍 Detect all ingredients",
            "2. 💶 Search current prices (Rewe/Lidl/Aldi Berlin)",
            "3. 📅 Generate a 3-day meal plan",
            "4. 📱 Send shopping list to Telegram",
            "",
            "**Usage:**",
            "• Attach a photo + type `/scan`",
            "• `/scan demo` — try with sample data",
            "• `/scan plan` — show last plan",
            "• `/scan shop` — send list to Telegram",
          ].join("\n"));
        }

        await reply("📸 Photo received! Starting pipeline...\n");

        // Step 1: Detect ingredients from image
        await reply("**1/3** 🔍 Scanning image for ingredients...");
        let rawIngredients;
        try {
          rawIngredients = await detectIngredientsFromImage(agent, imageUrl);
        } catch (e) {
          return reply(`❌ Image scan failed: ${e.message}\n\nTry \`/scan demo\` instead.`);
        }

        const ingredients = safeParseJSON(rawIngredients, []);
        if (!ingredients.length) {
          return reply("❌ Could not detect ingredients from image. Try a clearer photo or use `/scan demo`.");
        }

        await reply(`✅ Found **${ingredients.length} ingredients**: ${ingredients.join(", ")}`);
        return runPipeline(agent, reply, db, ingredients, imageUrl);
      }
    }
  ]
};

// ─── Shared pipeline (used by both image scan and demo) ──────────────────────

async function runPipeline(agent, reply, db, ingredients, imageUrl) {

  // Step 2: Search prices
  await reply("**2/3** 💶 Searching Berlin supermarket prices...");
  let prices = [];
  try {
    const rawPrices = await searchPricesForIngredients(agent, ingredients);
    prices = safeParseJSON(rawPrices, []);
  } catch (e) {
    await reply(`⚠️ Price search failed (${e.message}), continuing with estimates...`);
  }

  if (prices.length) {
    await reply(`✅ **Prices found:**\n\n${formatPriceTable(prices)}`);
  }

  // Step 3: Generate 3-day meal plan
  await reply("**3/3** 📅 Generating 3-day meal plan...");
  let plan = null;
  try {
    const rawPlan = await generateMealPlan(agent, ingredients, prices);
    plan = safeParseJSON(rawPlan, null);
  } catch (e) {
    return reply(`❌ Meal planning failed: ${e.message}`);
  }

  if (!plan?.days) {
    return reply("❌ Could not generate meal plan. Try again.");
  }

  // Save to DB
  db.prepare(`
    INSERT OR REPLACE INTO last_scan (id, ingredients, prices, plan, scanned_at)
    VALUES (1, ?, ?, ?, datetime('now'))
  `).run(JSON.stringify(ingredients), JSON.stringify(prices), JSON.stringify(plan));

  // Final output
  const lines = [
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "🍽️  **Your 3-Day Meal Plan**",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "",
    formatPlanTable(plan.days),
    "",
  ];

  for (const d of plan.days) {
    lines.push(`**${d.day}: ${d.meal}**`);
    lines.push(`Uses: ${(d.uses || []).join(", ")}`);
    if (d.buy?.length) {
      lines.push(`Buy extra: ${d.buy.map(b => `${b.item} €${b.price} @ ${b.store}`).join(", ")}`);
    }
    lines.push("");
  }

  lines.push("🛒 **Shopping List:**");
  (plan.shopping_list || []).forEach(i => lines.push(`• ${i}`));
  lines.push("");
  lines.push(`💰 **Total estimated cost: €${plan.total_cost?.toFixed(2) || "?"}**`);
  lines.push("");
  lines.push("_Run `/scan shop` to send this list to Telegram 📱_");

  return reply(lines.join("\n"));
}
