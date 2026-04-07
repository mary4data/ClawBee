# ClawBee Pi Setup Notes

This project now includes a ClawBee-specific Raspberry Pi setup based on the
generic `openclaw-pi-setup` pattern.

## What Was Reused

- systemd-based OpenClaw service
- dedicated `openclaw` system user
- `/etc/openclaw/secrets.env` secret storage
- local workspace under `/home/openclaw/workspace`
- Tailscale-friendly local gateway binding

## What Was Added For ClawBee

- Featherless/OpenAI-compatible model configuration
- ClawBee repo checkout into `/home/openclaw/workspace/clawbee`
- skills loaded from `/data/workspace/clawbee/skills`
- `CLAUDE.md` copied into the runtime checkout to preserve ClawBee's operating guide
- database initialization for fridge, meals, prices, and scan state
- Python dependency install for `fridge-scanner`
- `/data/workspace` compatibility symlink so existing absolute paths in skill
  instructions keep working unchanged on Raspberry Pi

## Paths On The Pi

- Repo: `/home/openclaw/workspace/clawbee`
- Compatibility path: `/data/workspace -> /home/openclaw/workspace`
- Gateway config: `/home/openclaw/.openclaw/openclaw.json`
- Secrets: `/etc/openclaw/secrets.env`
- Database: `/data/workspace/pantry.db`

## Phase 1 Scope

This Pi setup is intentionally for the current Telegram-first ClawBee runtime.
It reproduces the existing ClawBee behavior on Raspberry Pi before introducing a
new web backend/API layer for the Vercel frontend.
