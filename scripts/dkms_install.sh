#!/usr/bin/env bash
set -euo pipefail

KVER="${KVER:-$(uname -r)}"
PACKAGE_NAME="${MA530_DKMS_NAME:-ma530-btusb}"
PACKAGE_VERSION="${MA530_DKMS_VERSION:-0.1.0}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

if command -v mokutil >/dev/null 2>&1; then
  mokutil --sb-state || true
fi

if ! command -v dkms >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    "${sudo_cmd[@]}" apt-get update
    "${sudo_cmd[@]}" apt-get install -y dkms
  else
    echo "dkms is not installed and apt-get is not available."
    exit 1
  fi
fi

"${REPO_ROOT}/scripts/dkms_prepare.sh"

"${sudo_cmd[@]}" dkms add -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" || true
"${sudo_cmd[@]}" dkms build -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KVER}"
"${sudo_cmd[@]}" dkms install -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KVER}"
"${sudo_cmd[@]}" depmod -a "${KVER}"
"${sudo_cmd[@]}" modprobe -r btusb || true
"${sudo_cmd[@]}" modprobe btusb

if command -v mokutil >/dev/null 2>&1 && mokutil --sb-state 2>/dev/null | grep -qi enabled; then
  echo "Secure Boot appears to be enabled. Unsigned kernel modules may fail to load."
  echo "Check dmesg for module signature errors."
  "${sudo_cmd[@]}" dmesg | rg -i 'module verification|signature|key rejected|Required key not available' || true
fi

"${REPO_ROOT}/scripts/verify_driver.sh" "${KVER}"
