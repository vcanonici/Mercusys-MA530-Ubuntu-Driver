#!/usr/bin/env bash
set -euo pipefail

MAC="${1:-}"
if [[ -z "${MAC}" ]]; then
  echo "Usage: $0 <MAC>"
  exit 1
fi

UNIT_PATH="/etc/systemd/system/bt-auto-connect@.service"

if [[ ! -f "${UNIT_PATH}" ]]; then
  sudo tee "${UNIT_PATH}" >/dev/null <<'UNIT'
[Unit]
Description=Auto-connect Bluetooth device %I
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/bin/bluetoothctl connect %I
ExecStartPost=/usr/bin/bluetoothctl trust %I
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
fi

# Ensure device is trusted and paired (pairing may prompt for PIN)
bluetoothctl <<EOF2
power on
agent on
default-agent
trust ${MAC}
connect ${MAC}
EOF2

ESCAPED=$(systemd-escape "${MAC}")

sudo systemctl daemon-reload
sudo systemctl enable --now "bt-auto-connect@${ESCAPED}.service"

echo "Enabled autoconnect for ${MAC}"
