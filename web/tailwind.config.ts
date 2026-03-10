import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          orange: '#E8642A',
          red:    '#C0392B',
          dark:   '#1a1a2e',
          card:   '#16213e',
          border: '#0f3460',
        },
      },
    },
  },
  plugins: [],
}

export default config
