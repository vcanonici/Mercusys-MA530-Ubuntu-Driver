#!/usr/bin/env bash
set -euo pipefail

KVER="${1:-$(uname -r)}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
OUT_DIR="${REPO_ROOT}/driver/build/${KVER}"
LOG_FILE="${OUT_DIR}/build.log"

mkdir -p "${OUT_DIR}"

{
  echo "# build btusb for ${KVER}"
  echo "# src: ${SRC_DIR}"
  echo
  make -C "${SRC_DIR}" KVER="${KVER}" clean
  make -C "${SRC_DIR}" KVER="${KVER}" all
} | tee "${LOG_FILE}"

cp -f "${SRC_DIR}/btusb.ko" "${OUT_DIR}/"
cp -f "${SRC_DIR}/ath3k.ko" "${OUT_DIR}/" || true

sha256sum "${OUT_DIR}/btusb.ko" | tee "${OUT_DIR}/btusb.sha256"

echo "Built: ${OUT_DIR}/btusb.ko"
