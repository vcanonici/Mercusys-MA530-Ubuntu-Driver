#!/usr/bin/env bash
set -euo pipefail

modinfo -n btusb || true
lsmod | rg -n '^btusb' || lsmod | grep -n '^btusb' || true

if [[ -d /sys/module/btusb ]]; then
  echo "btusb module is loaded"
else
  echo "btusb module is NOT loaded"
fi
