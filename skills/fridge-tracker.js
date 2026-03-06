/**
 * OpenClaw Skill: Fridge Tracker
 * Tracks current fridge/pantry inventory in SQLite.
 * Commands: /fridge list | /fridge add <item> <qty> | /fridge remove <item> | /fridge clear
 */

import Database from "better-sqlite3";
import path from "path";

const DB_PATH = path.join(process.env.OPENCLAW_WORKSPACE_DIR || "/data/workspace", "pantry.db");

function getDb() {
  const db = new Database(DB_PATH);
  db.exec(`
    CREATE TABLE IF NOT EXISTS fridge (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item TEXT NOT NULL UNIQUE,
      quantity TEXT,
      updated_at TEXT DEFAULT (datetime('now'))
    );
  `);
  return db;
}

export const skill = {
  name: "fridge-tracker",
  description: "Track what's currently in your fridge and pantry.",
  commands: [
    {
      name: "fridge",
      description: "Manage fridge inventory",
      async run({ args, reply }) {
        const db = getDb();
        const [action, ...rest] = args;

        if (!action || action === "list") {
          const rows = db.prepare("SELECT item, quantity, updated_at FROM fridge ORDER BY item").all();
          if (rows.length === 0) {
            return reply("🧊 Fridge is empty. Add items with `/fridge add <item> <quantity>`");
          }
          const lines = rows.map(r => `• **${r.item}** — ${r.quantity || "some"} _(updated ${r.updated_at})_`);
          return reply(`🧊 **Current Fridge Contents:**\n\n${lines.join("\n")}`);
        }

        if (action === "add") {
          const [item, ...qtyParts] = rest;
          const quantity = qtyParts.join(" ") || "1";
          if (!item) return reply("Usage: `/fridge add <item> <quantity>`");
          db.prepare(`
            INSERT INTO fridge (item, quantity) VALUES (?, ?)
            ON CONFLICT(item) DO UPDATE SET quantity=excluded.quantity, updated_at=datetime('now')
          `).run(item.toLowerCase(), quantity);
          return reply(`✅ Added **${item}** (${quantity}) to fridge.`);
        }

        if (action === "remove") {
          const item = rest.join(" ");
          if (!item) return reply("Usage: `/fridge remove <item>`");
          const result = db.prepare("DELETE FROM fridge WHERE item = ?").run(item.toLowerCase());
          return reply(result.changes > 0
            ? `🗑️ Removed **${item}** from fridge.`
            : `❌ Item **${item}** not found.`);
        }

        if (action === "clear") {
          db.prepare("DELETE FROM fridge").run();
          return reply("🧹 Fridge cleared.");
        }

        return reply("Unknown command. Use: `list`, `add <item> <qty>`, `remove <item>`, `clear`");
      }
    }
  ]
};
