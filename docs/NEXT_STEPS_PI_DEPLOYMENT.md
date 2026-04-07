# Next Steps: Raspberry Pi Deployment

## Objective

Bring ClawBee to a working Phase 1 Raspberry Pi baseline that reproduces the
current Telegram-first behavior outside Railway.

## Immediate Next Steps

1. Prepare the Raspberry Pi
- Install Raspberry Pi OS
- Ensure SSH access works
- Install Tailscale if private remote access is desired
- Confirm `sudo`, `git`, and internet access work

2. Pull the latest ClawBee repo on the Pi
- Clone or pull the latest `main`
- Confirm the Pi has the new `deploy/pi/` files

3. Create the Pi environment file
- Copy `deploy/pi/.env.example` to `deploy/pi/.env`
- Fill in:
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID`
  - `FEATHERLESS_API_KEY`
  - optional `TELEGRAM_GROUP_ID`
  - optional `TAILSCALE_HOSTNAME`

4. Run the Pi setup
- Execute `bash deploy/pi/setup-clawbee-pi.sh`
- Confirm the script completes without fatal errors

5. Verify the service
- Check `sudo systemctl status openclaw-gateway`
- Check logs with `sudo journalctl -u openclaw-gateway -n 100 --no-pager`
- Confirm `pantry.db` exists at `/data/workspace/pantry.db`

6. Verify Telegram behavior
- Send `/plan help`
- Send `/fridge list`
- Send `/scan demo`
- Confirm the bot replies from the Pi runtime

7. Validate skill loading
- Confirm ClawBee skills exist under `/data/workspace/clawbee/skills`
- Confirm the gateway is loading that directory
- Confirm DB init scripts created the expected tables

## After Phase 1 Is Stable

1. Keep Telegram as a companion channel
2. Design the backend API for the new web app
3. Host the frontend on Vercel or Netlify
4. Connect the frontend directly to the ClawBee backend
5. Add user auth, household state, and Telegram account linking

## Phase 1 Exit Criteria

- ClawBee runs on Raspberry Pi under systemd
- Telegram commands work reliably
- SQLite persists locally on the Pi
- The documented Pi setup is reproducible
- Railway is no longer required for the old baseline behavior
