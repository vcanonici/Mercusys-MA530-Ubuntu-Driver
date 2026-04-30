#!/usr/bin/env bash
set -euo pipefail

KVER="${KVER:-$(uname -r)}"
BTUSB_SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
PACKAGE_NAME="${MA530_DKMS_NAME:-ma530-btusb}"
PACKAGE_VERSION="${MA530_DKMS_VERSION:-0.1.0}"
DKMS_DIR="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

export KVER BTUSB_SRC_DIR

"${REPO_ROOT}/scripts/bootstrap_source.sh" "${BTUSB_SRC_DIR}"
"${REPO_ROOT}/scripts/prepare_source.sh" "${BTUSB_SRC_DIR}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

cp "${BTUSB_SRC_DIR}/Makefile" "${tmp_dir}/"
cp "${BTUSB_SRC_DIR}/btusb.c" "${tmp_dir}/"
cp "${BTUSB_SRC_DIR}/ath3k.c" "${tmp_dir}/"

for header in btintel.h btbcm.h btrtl.h btmtk.h; do
  if [[ -f "${BTUSB_SRC_DIR}/${header}" ]]; then
    cp "${BTUSB_SRC_DIR}/${header}" "${tmp_dir}/"
  fi
done

cat >"${tmp_dir}/dkms.conf" <<EOF
PACKAGE_NAME="${PACKAGE_NAME}"
PACKAGE_VERSION="${PACKAGE_VERSION}"
BUILT_MODULE_NAME[0]="btusb"
BUILT_MODULE_LOCATION[0]="."
DEST_MODULE_LOCATION[0]="/updates"
AUTOINSTALL="yes"
MAKE[0]="make KVER=\${kernelver}"
CLEAN="make KVER=\${kernelver} clean"
EOF

"${sudo_cmd[@]}" rm -rf "${DKMS_DIR}"
"${sudo_cmd[@]}" mkdir -p "${DKMS_DIR}"
"${sudo_cmd[@]}" cp -f "${tmp_dir}"/* "${DKMS_DIR}/"

echo "${DKMS_DIR}"
