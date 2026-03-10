import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'ClawBee — Smart Meal Planner',
  description: 'Photo your fridge → get a meal plan → receive your shopping list.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-brand-dark text-slate-100 antialiased">
        {children}
      </body>
    </html>
  )
}
