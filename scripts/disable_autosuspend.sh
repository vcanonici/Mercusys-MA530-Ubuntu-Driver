#!/usr/bin/env bash
set -euo pipefail

RULE_PATH="/etc/udev/rules.d/99-btusb-ma530.rules"

sudo tee "${RULE_PATH}" >/dev/null <<'RULE'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2c4e", ATTR{idProduct}=="0115", TEST=="power/control", ATTR{power/control}="on"
RULE

sudo udevadm control --reload
sudo udevadm trigger -s usb

echo "Disabled autosuspend for 2c4e:0115"
