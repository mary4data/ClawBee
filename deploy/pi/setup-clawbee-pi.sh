#!/usr/bin/env bash
# setup-clawbee-pi.sh — ClawBee on Raspberry Pi via OpenClaw + systemd

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log()     { echo -e "${GREEN}[+]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
die()     { echo -e "${RED}[x] FATAL:${RESET} $*" >&2; exit 1; }
section() { echo -e "\n${BLUE}${BOLD}━━━ $* ━━━${RESET}"; }

if [[ "$EUID" -eq 0 ]]; then
  die "Do not run this script as root. Run it as your normal Pi user."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

section "Load .env"

if [[ ! -f "$ENV_FILE" ]]; then
  die ".env not found. Copy deploy/pi/.env.example to deploy/pi/.env and fill it in."
fi

ENV_PERMS=$(stat -c "%a" "$ENV_FILE")
if [[ "$ENV_PERMS" != "600" ]]; then
  warn ".env permissions are ${ENV_PERMS}; tightening to 600."
  chmod 600 "$ENV_FILE"
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

MISSING=()
[[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] && MISSING+=("TELEGRAM_BOT_TOKEN")
[[ -z "${TELEGRAM_CHAT_ID:-}" ]] && MISSING+=("TELEGRAM_CHAT_ID")
[[ -z "${FEATHERLESS_API_KEY:-}" ]] && MISSING+=("FEATHERLESS_API_KEY")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  die "Missing required variables in deploy/pi/.env: ${MISSING[*]}"
fi

OPENCLAW_MODEL="${OPENCLAW_MODEL:-featherless/Qwen/Qwen3-32B}"
OPENCLAW_VISION_MODEL="${OPENCLAW_VISION_MODEL:-featherless/Qwen/Qwen3-VL-30B-A3B-Instruct}"
CLAWBEE_REPO_URL="${CLAWBEE_REPO_URL:-https://github.com/mary4data/ClawBee.git}"
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-}"

section "Pre-flight"

if command -v tailscale >/dev/null 2>&1; then
  if tailscale status >/dev/null 2>&1; then
    log "Tailscale is connected."
  else
    warn "Tailscale is installed but not connected."
  fi
else
  warn "Tailscale not installed. The private web UI step will be skipped."
fi

section "Install packages"

sudo apt-get update
sudo apt-get install -y git sqlite3 python3 python3-pip curl gettext-base

CURRENT_NODE_MAJOR=0
if command -v node >/dev/null 2>&1; then
  CURRENT_NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
fi

if [[ "$CURRENT_NODE_MAJOR" -lt 24 ]]; then
  log "Installing Node.js 24..."
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

section "Create openclaw user"

if ! id -u openclaw >/dev/null 2>&1; then
  sudo useradd --system --create-home --home-dir /home/openclaw --shell /usr/sbin/nologin openclaw
else
  warn "User 'openclaw' already exists."
fi

as_openclaw() {
  sudo -u openclaw env HOME=/home/openclaw \
    PATH="/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin" \
    /bin/bash -c "cd /home/openclaw && $1"
}

section "Install OpenClaw"

log "Temporarily enabling bash shell for openclaw..."
sudo usermod --shell /bin/bash openclaw
sudo mkdir -p /home/openclaw/.local/bin /home/openclaw/.local/lib
sudo chown -R openclaw:openclaw /home/openclaw/.local
as_openclaw 'npm config set prefix ~/.local'
as_openclaw 'git config --global url."https://github.com/".insteadOf ssh://git@github.com/'

if as_openclaw 'command -v openclaw >/dev/null 2>&1'; then
  warn "OpenClaw already installed."
else
  as_openclaw 'env SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest'
fi

OPENCLAW_BIN=$(as_openclaw 'command -v openclaw 2>/dev/null || true')
if [[ -z "$OPENCLAW_BIN" ]]; then
  die "OpenClaw install failed; binary not found."
fi

sudo usermod --shell /usr/sbin/nologin openclaw
log "OpenClaw binary: ${OPENCLAW_BIN}"

section "Workspace layout"

sudo mkdir -p /home/openclaw/.openclaw /home/openclaw/workspace
sudo chown -R openclaw:openclaw /home/openclaw/.openclaw /home/openclaw/workspace
sudo loginctl enable-linger openclaw || true

# Preserve ClawBee's current /data/workspace path assumptions so the existing
# skill instructions and helper scripts continue to work unchanged on the Pi.
sudo mkdir -p /data
if [[ ! -e /data/workspace ]]; then
  sudo ln -s /home/openclaw/workspace /data/workspace
fi

if [[ -d /home/openclaw/workspace/clawbee/.git ]]; then
  log "Updating existing ClawBee checkout..."
  sudo -u openclaw git -C /home/openclaw/workspace/clawbee pull --ff-only
else
  log "Cloning ClawBee..."
  sudo -u openclaw git clone "$CLAWBEE_REPO_URL" /home/openclaw/workspace/clawbee
fi

sudo cp "${REPO_DIR}/CLAUDE.md" /home/openclaw/workspace/clawbee/CLAUDE.md
sudo chown openclaw:openclaw /home/openclaw/workspace/clawbee/CLAUDE.md

section "Secrets"

sudo mkdir -p /etc/openclaw
sudo tee /etc/openclaw/secrets.env >/dev/null <<EOF
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
FEATHERLESS_API_KEY=${FEATHERLESS_API_KEY}
OPENAI_API_KEY=${FEATHERLESS_API_KEY}
OPENAI_BASE_URL=https://api.featherless.ai/v1
OPENCLAW_MODEL=${OPENCLAW_MODEL}
OPENCLAW_VISION_MODEL=${OPENCLAW_VISION_MODEL}
EOF
sudo chmod 600 /etc/openclaw/secrets.env
sudo chown root:root /etc/openclaw/secrets.env

section "Config"

CONFIG_OUT=/home/openclaw/.openclaw/openclaw.json
TEMPLATE="${SCRIPT_DIR}/openclaw.pi.json.template"
GROUP_POLICY_JSON=""
if [[ -n "${TELEGRAM_GROUP_ID:-}" ]]; then
  GROUP_POLICY_JSON=$(printf ',\n      "groupAllowFrom": [%s]' "${TELEGRAM_GROUP_ID}")
fi

sudo bash -c "OPENCLAW_MODEL='${OPENCLAW_MODEL}' OPENCLAW_VISION_MODEL='${OPENCLAW_VISION_MODEL}' TELEGRAM_CHAT_ID='${TELEGRAM_CHAT_ID}' envsubst < '${TEMPLATE}' | sed 's#\"groupPolicy\": \"open\"#\"groupPolicy\": \"open\"${GROUP_POLICY_JSON}#' > '${CONFIG_OUT}'"
sudo chown openclaw:openclaw "${CONFIG_OUT}"

section "Initialize ClawBee runtime"

sudo -u openclaw bash /home/openclaw/workspace/clawbee/skills/fridge-tracker/scripts/init-db.sh
sudo -u openclaw bash /home/openclaw/workspace/clawbee/skills/meal-planner/scripts/init-db.sh
sudo -u openclaw bash /home/openclaw/workspace/clawbee/skills/price-hunter/scripts/init-db.sh
sudo -u openclaw bash /home/openclaw/workspace/clawbee/skills/fridge-scanner/scripts/init-db.sh

python3 -m pip install --break-system-packages -r /home/openclaw/workspace/clawbee/skills/fridge-scanner/requirements.txt

section "Helpers and service"

sudo tee /usr/local/bin/as-openclaw >/dev/null <<'EOF'
#!/usr/bin/env bash
exec sudo -u openclaw env HOME=/home/openclaw PATH="/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin" /bin/bash -c "cd /home/openclaw && $*"
EOF
sudo chmod 755 /usr/local/bin/as-openclaw

sudo tee /etc/systemd/system/openclaw-gateway.service >/dev/null <<EOF
[Unit]
Description=ClawBee OpenClaw Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=openclaw
WorkingDirectory=/home/openclaw/workspace/clawbee
EnvironmentFile=/etc/openclaw/secrets.env
Environment=OPENCLAW_CONFIG_PATH=/home/openclaw/.openclaw/openclaw.json
Environment=OPENCLAW_WORKSPACE_DIR=/data/workspace
Environment=OPENCLAW_STATE_DIR=/home/openclaw/.openclaw
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
ExecStart=${OPENCLAW_BIN} gateway
Restart=always
RestartSec=10
TimeoutStartSec=90
StandardOutput=journal
StandardError=journal
PrivateDevices=yes
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/home/openclaw /var/tmp/openclaw-compile-cache /tmp /data

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p /var/tmp/openclaw-compile-cache
sudo chown openclaw:openclaw /var/tmp/openclaw-compile-cache

section "Enable service"

sudo systemctl daemon-reload
sudo systemctl enable openclaw-gateway
sudo systemctl restart openclaw-gateway
sudo systemctl status openclaw-gateway --no-pager -l || true

section "Summary"

echo ""
echo -e "${GREEN}${BOLD}ClawBee Pi setup complete${RESET}"
echo "Repo:       /home/openclaw/workspace/clawbee"
echo "Workspace:  /data/workspace -> /home/openclaw/workspace"
echo "Config:     /home/openclaw/.openclaw/openclaw.json"
echo "Secrets:    /etc/openclaw/secrets.env"
echo "DB:         /data/workspace/pantry.db"
echo "Service:    sudo systemctl status openclaw-gateway"
if [[ -n "$TAILSCALE_HOSTNAME" ]]; then
  echo "Web UI:     https://${TAILSCALE_HOSTNAME}"
fi
