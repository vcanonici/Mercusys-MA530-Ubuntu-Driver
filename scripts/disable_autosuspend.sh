#!/usr/bin/env bash
set -euo pipefail

RULE_PATH="/etc/udev/rules.d/99-btusb-ma530.rules"
sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

if [[ "${EUID}" -eq 0 ]]; then
  cat > "${RULE_PATH}" <<'RULE'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2c4e", ATTR{idProduct}=="0115", TEST=="power/control", ATTR{power/control}="on"
RULE
else
  sudo tee "${RULE_PATH}" >/dev/null <<'RULE'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2c4e", ATTR{idProduct}=="0115", TEST=="power/control", ATTR{power/control}="on"
RULE
fi

"${sudo_cmd[@]}" udevadm control --reload
"${sudo_cmd[@]}" udevadm trigger -s usb

echo "Disabled autosuspend for 2c4e:0115"
