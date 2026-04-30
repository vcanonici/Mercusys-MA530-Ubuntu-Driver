#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

KVER="${KVER:-$(uname -r)}"
BTUSB_SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
MA530_USE_DKMS="${MA530_USE_DKMS:-0}"
export KVER BTUSB_SRC_DIR

echo "== MA530 agent install =="
echo "kernel=${KVER}"
echo "btusb_source=${BTUSB_SRC_DIR}"
echo "use_dkms=${MA530_USE_DKMS}"

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
  packages=(
    build-essential
    "linux-headers-${KVER}"
    bluez
    usbutils
    ripgrep
    patch
  )
  if [[ "${MA530_USE_DKMS}" == "1" ]]; then
    packages+=(dkms)
  fi
  "${sudo_cmd[@]}" apt-get install -y --no-upgrade "${packages[@]}"
else
  echo "apt-get not found. Install build tools, kernel headers, bluez, usbutils, ripgrep, and patch."
  exit 1
fi

echo "== Secure Boot =="
if command -v mokutil >/dev/null 2>&1; then
  mokutil --sb-state || true
  if mokutil --sb-state 2>/dev/null | grep -qi enabled; then
    echo "Secure Boot appears to be enabled. Unsigned kernel modules may fail to load."
    echo "Check dmesg for module signature errors."
    "${sudo_cmd[@]}" dmesg | rg -i 'module verification|signature|key rejected|Required key not available' || true
  fi
else
  echo "mokutil not found; skipping Secure Boot state detection."
fi

echo "== Adapter =="
if ! lsusb | rg -i '2c4e:0115|mercusys'; then
  echo "MA530 adapter was not detected as 2c4e:0115."
  echo "Continuing driver build/install anyway; plug the adapter before final verification."
fi

echo "== Source bootstrap =="
./scripts/bootstrap_source.sh "${BTUSB_SRC_DIR}"
./scripts/prepare_source.sh "${BTUSB_SRC_DIR}"

if [[ "${MA530_USE_DKMS}" == "1" ]]; then
  echo "== DKMS install =="
  ./scripts/dkms_install.sh
else
  echo "== Build =="
  ./scripts/build_driver.sh "${KVER}"

  echo "== Install =="
  ./scripts/install_driver.sh "${KVER}"

  echo "== Load =="
  ./scripts/load_driver.sh "${KVER}"
fi

echo "== Verify =="
verify_rc=0
./scripts/verify_driver.sh "${KVER}" || verify_rc=$?

echo "== Optional pairing =="
if [[ "${verify_rc}" -eq 0 && -n "${TARGET_BT_MAC:-}" ]]; then
  ./scripts/pair_device.sh "${TARGET_BT_MAC}"
  bluetoothctl info "${TARGET_BT_MAC}"
  "${sudo_cmd[@]}" ./scripts/install_system_integration.sh "${TARGET_BT_MAC}"
  ./scripts/disable_autosuspend.sh
elif [[ -n "${TARGET_BT_MAC:-}" ]]; then
  echo "Skipping pairing because driver/controller verification failed with code ${verify_rc}."
else
  echo "TARGET_BT_MAC not set; skipping pairing."
fi

echo "MA530 agent install finished with verify_rc=${verify_rc}."
exit "${verify_rc}"
