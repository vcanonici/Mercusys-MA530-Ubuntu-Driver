#!/usr/bin/env bash
set -euo pipefail

KVER="${1:-${KVER:-$(uname -r)}}"
UPDATES_DIR="/lib/modules/${KVER}/updates"
UPDATES_MODULE="${UPDATES_DIR}/btusb.ko"
CONTROLLER_WAIT_SECONDS="${MA530_VERIFY_CONTROLLER_WAIT:-8}"

have_rg=0
if command -v rg >/dev/null 2>&1; then
  have_rg=1
fi

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
  sudo_cmd=(sudo)
fi

local_hostname="$(hostname 2>/dev/null || true)"

sanitize_stream() {
  local sed_expr=(
    -e 's/([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/XX:XX:XX:XX:XX:XX/g' \
    -e 's#/home/[^/[:space:]]+#/home/<user>#g' \
    -e 's/(SerialNumber=)[^[:space:]]+/\1<redacted>/g'
  )

  if [[ -n "${local_hostname}" ]]; then
    sed_expr+=(-e "s/\\b${local_hostname}\\b/<hostname>/g")
  fi

  sed -E "${sed_expr[@]}"
}

filter_bt() {
  if [[ "${have_rg}" -eq 1 ]]; then
    rg -i 'MA530|RTL|btusb|rtl8761bu'
  else
    grep -Ei 'MA530|RTL|btusb|rtl8761bu'
  fi
}

filter_modules() {
  if [[ "${have_rg}" -eq 1 ]]; then
    rg -n '^btusb|^btrtl|^bluetooth'
  else
    grep -En '^btusb|^btrtl|^bluetooth'
  fi
}

echo "== Environment =="
uname -r | sanitize_stream

echo "== Adapter =="
adapter_present=1
if command -v lsusb >/dev/null 2>&1; then
  if lsusb | grep -Ei '2c4e:0115|mercusys' | sanitize_stream; then
    adapter_present=0
  else
    echo "MA530 adapter not detected as 2c4e:0115 or Mercusys."
  fi
else
  echo "lsusb not available."
fi

echo "== Module path =="
module_path="$(modinfo -n btusb 2>/dev/null || true)"
if [[ -n "${module_path}" ]]; then
  printf '%s\n' "${module_path}" | sanitize_stream
else
  echo "btusb module not found by modinfo."
fi

echo "== Updates module =="
module_ok=1
module_info_path=""
if [[ "${module_path}" == "${UPDATES_DIR}/"* && -f "${module_path}" ]]; then
  module_info_path="${module_path}"
elif [[ -f "${UPDATES_MODULE}" ]]; then
  module_info_path="${UPDATES_MODULE}"
fi

if [[ -n "${module_info_path}" ]]; then
  if modinfo "${module_info_path}" | grep -E '^(srcversion|vermagic|version):' | sanitize_stream; then
    :
  fi
  vermagic="$(modinfo -F vermagic "${module_info_path}" 2>/dev/null || true)"
  if [[ "${module_path}" == "${UPDATES_DIR}/"* && "${vermagic}" == "${KVER}"* ]]; then
    module_ok=0
  else
    echo "btusb updates module is missing from active path or has a kernel mismatch."
    echo "expected_path=${UPDATES_DIR}/..."
    echo "active_path=${module_path:-<missing>}"
    echo "vermagic=${vermagic:-<missing>}"
  fi
else
  echo "Missing active btusb module under ${UPDATES_DIR}"
fi

echo "== Loaded modules =="
lsmod | filter_modules | sanitize_stream || true

echo "== Kernel log =="
if [[ "${#sudo_cmd[@]}" -gt 0 || "${EUID}" -eq 0 ]]; then
  "${sudo_cmd[@]}" dmesg 2>/dev/null | filter_bt | tail -n 120 | sanitize_stream || true
else
  dmesg 2>/dev/null | filter_bt | tail -n 120 | sanitize_stream || true
fi

echo "== Controller =="
controller_present=1
if command -v bluetoothctl >/dev/null 2>&1; then
  controller_output=""
  for ((i = 0; i <= CONTROLLER_WAIT_SECONDS; i++)); do
    controller_output="$(bluetoothctl show 2>&1 || true)"
    if printf '%s\n' "${controller_output}" | grep -q '^Controller '; then
      controller_present=0
      break
    fi
    if [[ "${i}" -lt "${CONTROLLER_WAIT_SECONDS}" ]]; then
      sleep 1
    fi
  done
  printf '%s\n' "${controller_output}" | sanitize_stream
  if [[ "${controller_present}" -ne 0 ]]; then
    echo "bluetoothctl did not report a controller."
  fi
else
  echo "bluetoothctl not available."
fi

echo "== RFKill =="
rfkill list bluetooth 2>&1 | sanitize_stream || true

echo "== Bluetooth service =="
systemctl status bluetooth --no-pager 2>&1 | sanitize_stream || true

if [[ "${module_ok}" -ne 0 ]]; then
  exit 1
fi

if [[ "${adapter_present}" -ne 0 ]]; then
  exit 2
fi

if [[ "${controller_present}" -ne 0 ]]; then
  exit 3
fi

exit 0
