/**
 * OpenClaw Skill: Price Hunter
 * Searches online for ingredient prices and stores best offers in SQLite.
 * Commands: /prices search <ingredient> | /prices list | /prices best <ingredient>
 */

import Database from "better-sqlite3";
import path from "path";

const DB_PATH = path.join(process.env.OPENCLAW_WORKSPACE_DIR || "/data/workspace", "pantry.db");

function getDb() {
  const db = new Database(DB_PATH);
  db.exec(`
    CREATE TABLE IF NOT EXISTS prices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item TEXT NOT NULL,
      store TEXT,
      price REAL,
      unit TEXT,
      url TEXT,
      fetched_at TEXT DEFAULT (datetime('now'))
    );
    CREATE INDEX IF NOT EXISTS idx_prices_item ON prices(item);
  `);
  return db;
}

async function searchPricesOnline(item) {
  // Uses OpenClaw's built-in web search capability
  // Returns mock structure — replace with actual web search integration
  const results = await globalThis.__openclaw?.webSearch?.(`${item} price supermarket Berlin Germany`);
  if (!results) {
    // Fallback mock data for demo
    return [
      { store: "Rewe", price: (Math.random() * 3 + 0.5).toFixed(2), unit: "per kg" },
      { store: "Lidl", price: (Math.random() * 2.5 + 0.4).toFixed(2), unit: "per kg" },
      { store: "Aldi", price: (Math.random() * 2 + 0.3).toFixed(2), unit: "per kg" },
    ];
  }
  return results;
}

export const skill = {
  name: "price-hunter",
  description: "Search and track ingredient prices from online supermarkets.",
  commands: [
    {
      name: "prices",
      description: "Search and track grocery prices",
      async run({ args, reply, agent }) {
        const db = getDb();
        const [action, ...rest] = args;

        if (action === "search") {
          const item = rest.join(" ");
          if (!item) return reply("Usage: `/prices search <ingredient>`");

          await reply(`🔍 Searching prices for **${item}**...`);

          const results = await searchPricesOnline(item);

          // Store results
          const insert = db.prepare(`
            INSERT INTO prices (item, store, price, unit) VALUES (?, ?, ?, ?)
          `);
          for (const r of results) {
            insert.run(item.toLowerCase(), r.store, parseFloat(r.price), r.unit || "per unit");
          }

          const lines = results
            .sort((a, b) => parseFloat(a.price) - parseFloat(b.price))
            .map(r => `• **${r.store}**: €${parseFloat(r.price).toFixed(2)} ${r.unit || ""}`);

          return reply(`💰 **Prices for ${item}:**\n\n${lines.join("\n")}\n\n_Cheapest: ${results.sort((a,b) => a.price-b.price)[0]?.store}_`);
        }

        if (action === "best") {
          const item = rest.join(" ");
          if (!item) return reply("Usage: `/prices best <ingredient>`");
          const row = db.prepare(`
            SELECT store, price, unit, fetched_at FROM prices 
            WHERE item = ? ORDER BY price ASC LIMIT 1
          `).get(item.toLowerCase());
          if (!row) return reply(`No price data for **${item}**. Run \`/prices search ${item}\` first.`);
          return reply(`🏆 Best price for **${item}**: €${row.price.toFixed(2)} ${row.unit} at **${row.store}** _(${row.fetched_at})_`);
        }

        if (action === "list") {
          const rows = db.prepare(`
            SELECT item, store, MIN(price) as price, unit 
            FROM prices GROUP BY item ORDER BY item
          `).all();
          if (rows.length === 0) return reply("No price data yet. Use `/prices search <item>` to start.");
          const lines = rows.map(r => `• **${r.item}**: €${r.price.toFixed(2)} ${r.unit} @ ${r.store}`);
          return reply(`📊 **Best Known Prices:**\n\n${lines.join("\n")}`);
        }

        return reply("Usage: `/prices search <item>` | `/prices best <item>` | `/prices list`");
      }
    }
  ]
};
