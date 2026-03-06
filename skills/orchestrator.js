/**
 * OpenClaw Skill: Meal Planning Orchestrator
 * Coordinates all sub-agents: fridge check → price search → meal plan → shopping list → Telegram send
 * Commands: /plan weekly [budget] | /plan status | /plan auto
 */

export const skill = {
  name: "orchestrator",
  description: "Orchestrate the full family meal planning pipeline.",
  commands: [
    {
      name: "plan",
      description: "Run the full meal planning pipeline",
      async run({ args, reply, agent }) {
        const [action, ...rest] = args;

        if (!action || action === "weekly") {
          const budget = parseFloat(rest[0]) || 100;

          await reply(`🚀 **Starting Family Meal Planning Pipeline**\nBudget: €${budget}\n`);

          // Step 1: Check fridge
          await reply("**Step 1/4** 🧊 Checking fridge contents...");
          const fridgeResult = await agent.run("fridge list");
          await reply(fridgeResult || "Fridge check complete.");

          // Step 2: Search prices for common staples
          await reply("**Step 2/4** 💰 Fetching current prices...");
          const staples = ["pasta", "chicken breast", "tomatoes", "rice", "lentils", "salmon", "potatoes"];
          for (const item of staples) {
            await agent.run(`prices search ${item}`);
          }
          await reply("✅ Price data updated.");

          // Step 3: Generate meal plan
          await reply("**Step 3/4** 📅 Generating weekly meal plan...");
          const planResult = await agent.run(`meals plan ${budget}`);
          await reply(planResult || "Meal plan generated.");

          // Step 4: Send shopping list to Telegram
          await reply("**Step 4/4** 📱 Sending shopping list to Telegram...");
          const sendResult = await agent.run("shopping send");
          await reply(sendResult || "Shopping list sent.");

          await reply([
            "",
            "✅ **Pipeline complete!**",
            `• Meal plan saved for this week`,
            `• Shopping list sent to Telegram`,
            `• Run \`/shopping optimize ${budget}\` to check budget`,
            `• Post your meal plan to Discord with \`/plan post\``,
          ].join("\n"));

          return;
        }

        if (action === "status") {
          const lines = [
            "📊 **Meal Planner Status**",
            "",
            "Run these to check each component:",
            "• `/fridge list` — current inventory",
            "• `/meals show` — this week's plan",
            "• `/prices list` — known prices",
            "• `/shopping list` — full shopping list",
          ];
          return reply(lines.join("\n"));
        }

        if (action === "post") {
          // Post summary to Discord channel (via OpenClaw's channel message)
          const mealSummary = await agent.run("meals show");
          const shoppingSummary = await agent.run("shopping list");
          return reply([
            "📢 **This Week's Family Meal Plan**",
            "",
            mealSummary,
            "",
            shoppingSummary,
            "",
            "_React with ✅ if you approve the plan!_"
          ].join("\n"));
        }

        if (action === "help") {
          return reply([
            "🦞 **Family Meal Planner — Commands**",
            "",
            "**Orchestrator**",
            "• `/plan weekly [budget]` — run full pipeline",
            "• `/plan status` — check all components",
            "• `/plan post` — post plan to Discord",
            "",
            "**Fridge Tracker**",
            "• `/fridge list` — show contents",
            "• `/fridge add <item> <qty>` — add item",
            "• `/fridge remove <item>` — remove item",
            "",
            "**Prices**",
            "• `/prices search <item>` — find prices online",
            "• `/prices best <item>` — cheapest known price",
            "• `/prices list` — all tracked prices",
            "",
            "**Meal Planning**",
            "• `/meals plan [budget]` — generate weekly plan",
            "• `/meals show` — show current plan",
            "• `/meals pref <key> <value>` — set preferences",
            "",
            "**Shopping**",
            "• `/shopping list` — view optimized list",
            "• `/shopping send` — send to Telegram",
            "• `/shopping optimize [budget]` — budget check",
          ].join("\n"));
        }

        return reply("Usage: `/plan weekly [budget]` | `/plan status` | `/plan post` | `/plan help`");
      }
    }
  ]
};
