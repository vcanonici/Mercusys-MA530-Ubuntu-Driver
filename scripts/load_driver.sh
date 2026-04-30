#!/usr/bin/env bash
set -euo pipefail

KVER="${1:-$(uname -r)}"
sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

echo "Unloading btusb..."
"${sudo_cmd[@]}" modprobe -r btusb || true

# Ensure dependencies are available
"${sudo_cmd[@]}" modprobe btrtl || true
"${sudo_cmd[@]}" modprobe btbcm || true
"${sudo_cmd[@]}" modprobe btintel || true
"${sudo_cmd[@]}" modprobe btmtk || true

# Load btusb (should pick /updates if installed)
"${sudo_cmd[@]}" modprobe btusb

modinfo -n btusb
