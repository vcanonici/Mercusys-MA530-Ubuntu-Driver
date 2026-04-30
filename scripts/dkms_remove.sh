#!/usr/bin/env bash
set -euo pipefail

PACKAGE_NAME="${MA530_DKMS_NAME:-ma530-btusb}"
PACKAGE_VERSION="${MA530_DKMS_VERSION:-0.1.0}"
DKMS_DIR="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

"${sudo_cmd[@]}" dkms remove -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" --all || true
"${sudo_cmd[@]}" rm -rf "${DKMS_DIR}"
"${sudo_cmd[@]}" depmod -a
