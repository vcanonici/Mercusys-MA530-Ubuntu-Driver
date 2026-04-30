#!/usr/bin/env bash
set -euo pipefail

KVER="${1:-$(uname -r)}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${REPO_ROOT}/driver/build/${KVER}"
DEST_DIR="/lib/modules/${KVER}/updates"
sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

if [[ ! -f "${SRC_DIR}/btusb.ko" ]]; then
  echo "Missing ${SRC_DIR}/btusb.ko - run scripts/build_driver.sh first."
  exit 1
fi

"${sudo_cmd[@]}" mkdir -p "${DEST_DIR}"
"${sudo_cmd[@]}" cp -f "${SRC_DIR}/btusb.ko" "${DEST_DIR}/btusb.ko"

if [[ -f "${SRC_DIR}/ath3k.ko" ]]; then
  "${sudo_cmd[@]}" cp -f "${SRC_DIR}/ath3k.ko" "${DEST_DIR}/ath3k.ko"
fi

"${sudo_cmd[@]}" depmod -a "${KVER}"

echo "Installed to ${DEST_DIR}"
