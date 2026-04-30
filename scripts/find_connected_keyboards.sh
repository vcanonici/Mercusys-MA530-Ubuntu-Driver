#!/usr/bin/env bash
set -euo pipefail

connected="$(bluetoothctl devices Connected | awk '{print $2}')"
if [[ -z "${connected}" ]]; then
  echo "No connected devices."
  exit 0
fi

found=0
while read -r mac; do
  [[ -z "${mac}" ]] && continue
  info="$(bluetoothctl info "${mac}" 2>/dev/null || true)"
  if echo "${info}" | grep -q "Icon: input-keyboard"; then
    echo "${mac}"
    echo "${info}"
    echo
    found=1
  fi
done <<<"${connected}"

if [[ "${found}" -eq 0 ]]; then
  echo "No connected keyboards found (Icon: input-keyboard)."
fi
