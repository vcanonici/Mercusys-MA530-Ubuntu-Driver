#!/usr/bin/env bash
set -euo pipefail

KVER="${1:-$(uname -r)}"
DEST_DIR="/lib/modules/${KVER}/updates"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

"${sudo_cmd[@]}" modprobe -r btusb || true

"${sudo_cmd[@]}" rm -f "${DEST_DIR}/btusb.ko"
"${sudo_cmd[@]}" rm -f "${DEST_DIR}/ath3k.ko"

"${sudo_cmd[@]}" depmod -a "${KVER}"
"${sudo_cmd[@]}" modprobe btusb || true

modinfo -n btusb || true
