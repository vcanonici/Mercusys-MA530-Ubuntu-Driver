#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

KVER="${KVER:-$(uname -r)}"
BTUSB_SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
export KVER BTUSB_SRC_DIR

echo "== MA530 agent install =="
echo "kernel=${KVER}"
echo "btusb_source=${BTUSB_SRC_DIR}"

if ! command -v sudo >/dev/null 2>&1 && [[ "${EUID}" -ne 0 ]]; then
  echo "sudo is required when not running as root."
  exit 1
fi

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

echo "== Dependencies =="
if command -v apt-get >/dev/null 2>&1; then
  "${sudo_cmd[@]}" apt-get update
  "${sudo_cmd[@]}" apt-get install -y \
    build-essential \
    "linux-headers-${KVER}" \
    linux-firmware \
    linux-source \
    bluez \
    usbutils \
    ripgrep \
    patch
else
  echo "apt-get not found. Install build tools, kernel headers, linux-source, bluez, usbutils, ripgrep, and patch."
  exit 1
fi

echo "== Adapter =="
if ! lsusb | rg -i '2c4e:0115|mercusys'; then
  echo "MA530 adapter was not detected as 2c4e:0115."
  echo "Continuing driver build/install anyway; plug the adapter before final verification."
fi

echo "== Source bootstrap =="
./scripts/bootstrap_source.sh "${BTUSB_SRC_DIR}"
./scripts/prepare_source.sh "${BTUSB_SRC_DIR}"

echo "== Build =="
./scripts/build_driver.sh "${KVER}"

echo "== Install =="
./scripts/install_driver.sh "${KVER}"

echo "== Load =="
./scripts/load_driver.sh "${KVER}"

echo "== Verify driver =="
modinfo -n btusb
modinfo "/lib/modules/${KVER}/updates/btusb.ko" | rg -n 'srcversion|vermagic|version'
lsmod | rg -n '^btusb|^btrtl|^bluetooth'
"${sudo_cmd[@]}" dmesg | rg -i 'MA530|RTL|btusb' | tail -n 80 || true

echo "== Verify controller =="
hciconfig -a || true
bluetoothctl show || true

echo "== Optional pairing =="
if [[ -n "${TARGET_BT_MAC:-}" ]]; then
  ./scripts/pair_device.sh "${TARGET_BT_MAC}"
  bluetoothctl info "${TARGET_BT_MAC}"
  "${sudo_cmd[@]}" ./scripts/install_system_integration.sh "${TARGET_BT_MAC}"
  ./scripts/disable_autosuspend.sh
else
  echo "TARGET_BT_MAC not set; skipping pairing."
fi

echo "MA530 agent install finished."
