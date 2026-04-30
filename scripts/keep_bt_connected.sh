#!/usr/bin/env bash
set -euo pipefail

MAC="${1:-}"
if [[ -z "${MAC}" ]]; then
  echo "Usage: $0 <MAC>"
  exit 1
fi

# Ensure adapter is powered and device is trusted.
bluetoothctl power on >/dev/null 2>&1 || true
bluetoothctl trust "${MAC}" >/dev/null 2>&1 || true

while true; do
  if bluetoothctl info "${MAC}" 2>/dev/null | grep -q "Connected: yes"; then
    sleep 15
    continue
  fi

  bluetoothctl connect "${MAC}" >/dev/null 2>&1 || true
  sleep 5
done
