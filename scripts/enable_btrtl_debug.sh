#!/usr/bin/env bash
set -euo pipefail

ctrl="/sys/kernel/debug/dynamic_debug/control"
if [[ ! -e "${ctrl}" ]]; then
  echo "dynamic_debug not available at ${ctrl}"
  exit 1
fi

echo "Enabling dynamic debug for drivers/bluetooth/btrtl.c"
echo "file drivers/bluetooth/btrtl.c +p" | sudo tee "${ctrl}" >/dev/null

echo "Enabled."
