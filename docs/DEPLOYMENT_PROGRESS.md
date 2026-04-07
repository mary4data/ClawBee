# ClawBee Deployment Progress

## Goal

Recreate the current Telegram-first ClawBee runtime on a Raspberry Pi, then use
that as the stable backend baseline for the new web app hosted separately.

## Current Baseline

- Current production model: Railway-hosted OpenClaw + ClawBee skills
- Current main user channel: Telegram
- Current persistence: SQLite (`pantry.db`)
- New frontend direction: separate web app, not routed through Telegram

## Raspberry Pi Phase 1

Status: in progress

### Completed

- Added Pi-specific environment template:
  [deploy/pi/.env.example](/Users/marty/claude-projects/ClawBee/deploy/pi/.env.example)
- Added ClawBee-specific OpenClaw config template:
  [deploy/pi/openclaw.pi.json.template](/Users/marty/claude-projects/ClawBee/deploy/pi/openclaw.pi.json.template)
- Added Pi setup script:
  [deploy/pi/setup-clawbee-pi.sh](/Users/marty/claude-projects/ClawBee/deploy/pi/setup-clawbee-pi.sh)
- Added migration notes:
  [docs/pi-migration.md](/Users/marty/claude-projects/ClawBee/docs/pi-migration.md)
- Preserved existing ClawBee skill path assumptions with `/data/workspace`
- Integrated ClawBee `CLAUDE.md` operating guide into the Pi runtime flow
- Integrated ClawBee SQLite init scripts into the Pi setup flow
- Switched the generic Pi setup pattern to Featherless/OpenAI-compatible config

### Pending

- Run the Pi setup script on the actual Raspberry Pi
- Verify OpenClaw service starts cleanly on the Pi
- Verify Telegram bot works from the Pi runtime
- Verify `fridge-scanner` Python dependency install works on-device
- Decide whether to keep Tailscale-only OpenClaw UI or expose backend via tunnel
- Add frontend-to-backend API layer for the new web app

## Definition Of Done For Phase 1

Phase 1 is done when all of the following are true:

- ClawBee runs on Raspberry Pi under systemd
- Telegram commands work against the Pi runtime
- `pantry.db` persists locally on the Pi
- the ClawBee skills are loaded from the Pi workspace
- the setup can be repeated from documented files in this repo

## Next Phase

After Phase 1:

- keep Telegram as a companion channel
- add a proper backend API for the web app
- host the frontend on Vercel or Netlify
- connect the frontend directly to ClawBee backend services
