#!/usr/bin/env bash
set -euo pipefail

MAC="${1:-}"
if [[ -z "${MAC}" ]]; then
  echo "Usage: $0 <MAC>"
  echo "Example: $0 AA:BB:CC:DD:EE:FF"
  exit 1
fi

UNIT_DIR="${HOME}/.config/systemd/user"
UNIT_PATH="${UNIT_DIR}/bt-auto-connect@.service"

mkdir -p "${UNIT_DIR}"

cat >"${UNIT_PATH}" <<'UNIT'
[Unit]
Description=Auto-connect Bluetooth device %I (user session)
After=default.target

[Service]
Type=simple
ExecStart=/bin/bash -lc 'for i in $(seq 1 120); do bluetoothctl connect %I && exit 0; sleep 2; done; exit 1'
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
UNIT

systemctl --user daemon-reload
systemctl --user enable --now "bt-auto-connect@${MAC}.service"

echo "Enabled user autoconnect for ${MAC}"
