#!/usr/bin/env bash
set -euo pipefail

dev_paths=(/sys/bus/usb/drivers/btusb/*:*.*)
if [[ "${dev_paths[0]}" == "/sys/bus/usb/drivers/btusb/*:*.*" ]]; then
  echo "No btusb devices are currently bound."
  exit 1
fi

echo "Unbinding btusb devices..."
for p in "${dev_paths[@]}"; do
  dev="$(basename "${p}")"
  printf "%s" "${dev}" | sudo tee /sys/bus/usb/drivers/btusb/unbind >/dev/null || true
  echo "  - ${dev}"
done

sleep 1

echo "Binding btusb devices..."
for p in "${dev_paths[@]}"; do
  dev="$(basename "${p}")"
  printf "%s" "${dev}" | sudo tee /sys/bus/usb/drivers/btusb/bind >/dev/null || true
  echo "  - ${dev}"
done

echo "Done."
