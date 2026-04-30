#!/usr/bin/env bash
set -euo pipefail

MAC="${1:-}"
if [[ -z "${MAC}" ]]; then
  echo "Usage: $0 <MAC>"
  echo "Example: $0 AA:BB:CC:DD:EE:FF"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must be run as root:"
  echo "  sudo $0 ${MAC}"
  exit 1
fi

RULE_PATH="/etc/udev/rules.d/99-btusb-ma530.rules"
UNIT_PATH="/etc/systemd/system/bt-auto-connect@.service"

cat >"${RULE_PATH}" <<'RULE'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2c4e", ATTR{idProduct}=="0115", TEST=="power/control", ATTR{power/control}="on"
RULE

cat >"${UNIT_PATH}" <<'UNIT'
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

systemctl daemon-reload
systemctl enable --now bluetooth.service

ESCAPED="$(systemd-escape "${MAC}")"
systemctl enable --now "bt-auto-connect@${ESCAPED}.service"

udevadm control --reload
udevadm trigger -s usb

echo "Installed:"
echo "  - ${RULE_PATH}"
echo "  - ${UNIT_PATH}"
echo "Enabled:"
echo "  - bt-auto-connect@${MAC}.service"
