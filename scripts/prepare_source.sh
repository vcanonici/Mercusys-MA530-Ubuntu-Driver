#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${1:-${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}}"
MINIMAL_PATCH="${REPO_ROOT}/patches/btusb-ma530-minimal.patch"
FALLBACK_PATCH="${REPO_ROOT}/patches/btusb-ma530.patch"

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

if rg -q 'MA530|0x2c4e.*0x0115|USB_DEVICE\s*\(\s*0x2c4e\s*,\s*0x0115\s*\)' "${SRC_DIR}/btusb.c"; then
  echo "MA530 changes already appear to be present in ${SRC_DIR}/btusb.c"
  exit 0
fi

try_patch() {
  local patch_file="$1"

  if [[ ! -f "${patch_file}" ]]; then
    echo "Patch file not found: ${patch_file}"
    return 1
  fi

  if patch --dry-run -d "${SRC_DIR}" -p1 < "${patch_file}" >/dev/null 2>&1; then
    patch -d "${SRC_DIR}" -p1 < "${patch_file}"
    echo "Applied ${patch_file} to ${SRC_DIR}"
    return 0
  fi

  return 1
}

if try_patch "${MINIMAL_PATCH}"; then
  exit 0
fi

echo "Minimal patch did not apply cleanly; trying compatibility fallback."
if try_patch "${FALLBACK_PATCH}"; then
  exit 0
fi

cat >&2 <<EOF
Could not apply the MA530 btusb patch to ${SRC_DIR}.

Insert the MA530 entry manually in btusb.c near other Realtek 8761BU/8761BUV devices:

  { USB_DEVICE(0x2c4e, 0x0115), .driver_info = BTUSB_REALTEK |
                                       BTUSB_WIDEBAND_SPEECH },

Then rerun this script.
EOF
exit 1
