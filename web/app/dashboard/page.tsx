'use client'

import Image from 'next/image'
import { useEffect, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'

interface Message { role: 'user' | 'assistant'; content: string }
interface User { name: string; budget: string; city: string }

const QUICK_ACTIONS = [
  { label: '📸 Scan demo', cmd: 'scan demo' },
  { label: '📅 Plan week', cmd: 'plan weekly' },
  { label: '🛒 Shopping list', cmd: 'shopping list' },
  { label: '🧊 My fridge', cmd: "what's in my fridge" },
]

export default function Dashboard() {
  const router = useRouter()
  const [user, setUser] = useState<User | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const stored = localStorage.getItem('clawbee_user')
    if (!stored) { router.push('/'); return }
    const u = JSON.parse(stored) as User
    setUser(u)
    setMessages([{
      role: 'assistant',
      content: `Hi ${u.name}! I'm ClawBee 🐝 Your weekly budget is €${u.budget}.\n\nTry **scan demo** to see a meal plan, or ask me anything about meals and shopping.`,
    }])
  }, [router])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  async function send(text: string) {
    if (!text.trim() || loading) return
    const userMsg: Message = { role: 'user', content: text }
    const next = [...messages, userMsg]
    setMessages(next)
    setInput('')
    setLoading(true)

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: next, user }),
      })
      const { text: reply } = await res.json()
      setMessages(m => [...m, { role: 'assistant', content: reply }])
    } catch {
      setMessages(m => [...m, { role: 'assistant', content: 'Something went wrong. Please try again.' }])
    } finally {
      setLoading(false)
    }
  }

  function logout() {
    localStorage.removeItem('clawbee_user')
    router.push('/')
  }

  return (
    <div className="flex flex-col h-screen bg-brand-dark">
      {/* Header */}
      <header className="flex items-center justify-between px-4 py-3 border-b border-brand-border bg-brand-card">
        <div className="flex items-center gap-2">
          <Image src="/logo.png" alt="ClawBee" width={36} height={36} />
          <span className="font-bold text-white text-lg">ClawBee</span>
        </div>
        {user && (
          <div className="flex items-center gap-3 text-sm text-slate-400">
            <span>👤 {user.name}</span>
            <span>💶 €{user.budget}/week</span>
            <span>📍 {user.city}</span>
            <button onClick={logout} className="text-slate-500 hover:text-slate-300 transition-colors ml-2">
              Sign out
            </button>
          </div>
        )}
      </header>

      {/* Chat area */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {messages.map((m, i) => (
          <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'} animate-fadeIn`}>
            <div
              className={`max-w-[75%] px-4 py-3 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap ${
                m.role === 'user'
                  ? 'bg-brand-orange text-white rounded-br-md'
                  : 'bg-brand-card border border-brand-border text-slate-100 rounded-bl-md'
              }`}
            >
              {m.content}
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex justify-start animate-fadeIn">
            <div className="bg-brand-card border border-brand-border px-4 py-3 rounded-2xl rounded-bl-md text-slate-400 text-sm">
              ClawBee is thinking…
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      {/* Quick actions */}
      <div className="flex gap-2 px-4 py-2 overflow-x-auto">
        {QUICK_ACTIONS.map(a => (
          <button
            key={a.cmd}
            onClick={() => send(a.cmd)}
            className="flex-shrink-0 px-3 py-1.5 rounded-full bg-brand-card border border-brand-border text-sm text-slate-300 hover:border-brand-orange hover:text-white transition-colors"
          >
            {a.label}
          </button>
        ))}
      </div>

      {/* Input */}
      <div className="px-4 pb-4">
        <form
          onSubmit={e => { e.preventDefault(); send(input) }}
          className="flex gap-2"
        >
          <input
            value={input}
            onChange={e => setInput(e.target.value)}
            placeholder="Ask about meals, shopping, prices…"
            className="flex-1 px-4 py-3 rounded-xl bg-brand-card border border-brand-border text-white placeholder-slate-600 focus:outline-none focus:border-brand-orange"
          />
          <button
            type="submit"
            disabled={loading || !input.trim()}
            className="px-5 py-3 rounded-xl bg-brand-orange hover:bg-orange-500 disabled:opacity-40 text-white font-semibold transition-colors"
          >
            Send
          </button>
        </form>
      </div>
    </div>
  )
}
