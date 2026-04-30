#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="${1:-${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}}"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

is_btusb_source() {
  local dir="$1"
  [[ -f "${dir}/Makefile" && -f "${dir}/btusb.c" && -f "${dir}/ath3k.c" ]]
}

if is_btusb_source "${DEST_DIR}"; then
  echo "${DEST_DIR}"
  exit 0
fi

find_extracted_kernel_source() {
  find /usr/src -maxdepth 5 -path '*/drivers/bluetooth/btusb.c' -type f 2>/dev/null |
    sort -V |
    tail -n 1 |
    sed 's#/drivers/bluetooth/btusb.c$##'
}

find_linux_source_tarball() {
  find /usr/src -maxdepth 1 -type f \( \
    -name 'linux-source-*.tar.xz' -o \
    -name 'linux-source-*.tar.bz2' -o \
    -name 'linux-source-*.tar.gz' \
  \) 2>/dev/null | sort -V | tail -n 1
}

src_root="$(find_extracted_kernel_source || true)"

if [[ -z "${src_root}" ]]; then
  tarball="$(find_linux_source_tarball || true)"

  if [[ -z "${tarball}" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      "${sudo_cmd[@]}" apt-get update
      "${sudo_cmd[@]}" apt-get install -y linux-source
      tarball="$(find_linux_source_tarball || true)"
    fi
  fi

  if [[ -n "${tarball}" ]]; then
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT
    tar -xf "${tarball}" -C "${tmp_dir}"
    src_root="$(find "${tmp_dir}" -maxdepth 2 -path '*/drivers/bluetooth/btusb.c' -type f |
      sort -V |
      tail -n 1 |
      sed 's#/drivers/bluetooth/btusb.c$##')"
  fi
fi

if [[ -z "${src_root}" || ! -f "${src_root}/drivers/bluetooth/btusb.c" ]]; then
  echo "Could not find Linux source with drivers/bluetooth/btusb.c."
  echo "Install linux-source or provide BTUSB_SRC_DIR with a prepared btusb source tree."
  exit 1
fi

staging="$(mktemp -d)"
trap 'rm -rf "${staging}"' EXIT

cp "${src_root}/drivers/bluetooth/btusb.c" "${staging}/"
cp "${src_root}/drivers/bluetooth/ath3k.c" "${staging}/"

for header in btintel.h btbcm.h btrtl.h btmtk.h; do
  if [[ -f "${src_root}/drivers/bluetooth/${header}" ]]; then
    cp "${src_root}/drivers/bluetooth/${header}" "${staging}/"
  fi
done

cat > "${staging}/Makefile" <<'MAKEFILE'
obj-m += btusb.o
obj-m += ath3k.o

all:
	make -C /lib/modules/$(KVER)/build M=$(CURDIR) modules

clean:
	make -C /lib/modules/$(KVER)/build M=$(CURDIR) clean
MAKEFILE

"${sudo_cmd[@]}" mkdir -p "${DEST_DIR}"
"${sudo_cmd[@]}" cp -f "${staging}"/* "${DEST_DIR}/"
"${sudo_cmd[@]}" chown -R "$(id -u):$(id -g)" "${DEST_DIR}" 2>/dev/null || true

echo "${DEST_DIR}"
