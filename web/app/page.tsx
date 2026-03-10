'use client'

import Image from 'next/image'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LandingPage() {
  const router = useRouter()
  const [form, setForm] = useState({ name: '', budget: '80', city: 'Berlin' })
  const [step, setStep] = useState<'hero' | 'register'>('hero')

  function handleStart() {
    const stored = localStorage.getItem('clawbee_user')
    if (stored) {
      router.push('/dashboard')
    } else {
      setStep('register')
    }
  }

  function handleRegister(e: React.FormEvent) {
    e.preventDefault()
    localStorage.setItem('clawbee_user', JSON.stringify(form))
    router.push('/dashboard')
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-4">
      {step === 'hero' && (
        <div className="flex flex-col items-center gap-8 animate-fadeIn text-center">
          <Image src="/logo.png" alt="ClawBee" width={160} height={160} priority />
          <div>
            <h1 className="text-4xl font-bold text-white mb-2">ClawBee</h1>
            <p className="text-slate-400 text-lg max-w-md">
              Photo your fridge → AI builds your weekly meal plan → shopping list lands on Telegram.
            </p>
          </div>

          <div className="flex flex-col gap-3 w-full max-w-xs">
            <button
              onClick={handleStart}
              className="w-full py-3 rounded-xl bg-brand-orange hover:bg-orange-500 text-white font-semibold text-lg transition-colors"
            >
              Get started free
            </button>
          </div>

          <div className="flex gap-8 text-slate-500 text-sm mt-4">
            <span>📸 Fridge scan</span>
            <span>📅 7-day plans</span>
            <span>🛒 Telegram list</span>
          </div>
        </div>
      )}

      {step === 'register' && (
        <div className="w-full max-w-sm animate-fadeIn">
          <div className="flex items-center gap-3 mb-8">
            <Image src="/logo.png" alt="ClawBee" width={48} height={48} />
            <h2 className="text-2xl font-bold text-white">Quick setup</h2>
          </div>

          <form onSubmit={handleRegister} className="flex flex-col gap-4">
            <div>
              <label className="block text-sm text-slate-400 mb-1">Your name</label>
              <input
                required
                type="text"
                placeholder="Maria"
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                className="w-full px-4 py-3 rounded-xl bg-brand-card border border-brand-border text-white placeholder-slate-600 focus:outline-none focus:border-brand-orange"
              />
            </div>

            <div>
              <label className="block text-sm text-slate-400 mb-1">Weekly grocery budget (€)</label>
              <input
                required
                type="number"
                min="20"
                max="300"
                value={form.budget}
                onChange={e => setForm(f => ({ ...f, budget: e.target.value }))}
                className="w-full px-4 py-3 rounded-xl bg-brand-card border border-brand-border text-white focus:outline-none focus:border-brand-orange"
              />
            </div>

            <div>
              <label className="block text-sm text-slate-400 mb-1">City</label>
              <input
                type="text"
                value={form.city}
                onChange={e => setForm(f => ({ ...f, city: e.target.value }))}
                className="w-full px-4 py-3 rounded-xl bg-brand-card border border-brand-border text-white focus:outline-none focus:border-brand-orange"
              />
            </div>

            <button
              type="submit"
              className="mt-2 w-full py-3 rounded-xl bg-brand-orange hover:bg-orange-500 text-white font-semibold text-lg transition-colors"
            >
              Start planning →
            </button>
          </form>
        </div>
      )}
    </main>
  )
}
