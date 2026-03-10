import Anthropic from '@anthropic-ai/sdk'

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const SYSTEM_PROMPT = `You are ClawBee, a smart family meal planner assistant. You help families:
- Plan weekly dinners based on their budget and what's in the fridge
- Track fridge inventory
- Find the best supermarket prices (Rewe, Lidl, Aldi)
- Build optimized shopping lists grouped by store

You always reply in a friendly, practical tone. When the user gives a budget, plan meals that fit within it.
When listing shopping items, group them by store and show estimated prices.
Format meal plans clearly with day/meal structure.

Commands you understand:
- "scan demo" or "demo" → generate a sample 3-day meal plan using common ingredients
- "plan weekly [budget]" → create a 7-day dinner plan for a family of 4 within budget
- "shopping list" → show a shopping list for the current plan, grouped by store
- "what's in my fridge" → show current fridge inventory
- "add [item] to fridge" → add an item to fridge
- Any natural language meal planning question

Always end meal plan responses with the estimated total cost.`

export async function POST(req: Request) {
  const { messages, user } = await req.json()

  const systemWithContext = user
    ? `${SYSTEM_PROMPT}\n\nUser: ${user.name}, city: ${user.city}, weekly budget: €${user.budget}.`
    : SYSTEM_PROMPT

  const response = await client.messages.create({
    model: 'claude-opus-4-6',
    max_tokens: 1024,
    system: systemWithContext,
    messages,
  })

  const text = response.content[0].type === 'text' ? response.content[0].text : ''
  return Response.json({ text })
}
