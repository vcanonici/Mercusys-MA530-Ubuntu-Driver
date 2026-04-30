#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${1:-${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}}"
PATCH_FILE="${REPO_ROOT}/patches/btusb-ma530.patch"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "Missing source directory: ${SRC_DIR}"
  echo "Set BTUSB_SRC_DIR or pass the btusb source directory as the first argument."
  exit 1
fi

for required in Makefile btusb.c ath3k.c; do
  if [[ ! -f "${SRC_DIR}/${required}" ]]; then
    echo "Missing ${SRC_DIR}/${required}"
    echo "This must be an out-of-tree btusb source directory."
    exit 1
  fi
done

if rg -q 'MA530_USB_VENDOR|0x2c4e.*0x0115|2c4e.*0115' "${SRC_DIR}/btusb.c"; then
  echo "MA530 changes already appear to be present in ${SRC_DIR}/btusb.c"
  exit 0
fi

patch -d "${SRC_DIR}" -p1 < "${PATCH_FILE}"
echo "Applied ${PATCH_FILE} to ${SRC_DIR}"
