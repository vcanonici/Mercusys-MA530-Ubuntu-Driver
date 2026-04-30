#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${REPO_ROOT}/logs"
timestamp="$(date +"%Y%m%d-%H%M%S")"
out_file="${LOG_DIR}/ma530-diagnostics-${timestamp}.txt"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
  sudo_cmd=(sudo)
fi

mkdir -p "${LOG_DIR}"

run_section() {
  local title="$1"
  shift

  {
    echo
    echo "## ${title}"
    echo "\$ $*"
    "$@"
  } >>"${out_file}" 2>&1 || true
}

run_section "uname" uname -a
run_section "lsusb" lsusb
run_section "modinfo path" modinfo -n btusb
run_section "modinfo updates btusb" modinfo "/lib/modules/$(uname -r)/updates/btusb.ko"
run_section "lsmod" lsmod
run_section "dmesg" bash -c 'dmesg | rg -i "MA530|RTL|btusb|rtl8761bu" | tail -n 200'
if [[ "${#sudo_cmd[@]}" -gt 0 ]]; then
  run_section "sudo dmesg" "${sudo_cmd[@]}" bash -c 'dmesg | rg -i "MA530|RTL|btusb|rtl8761bu" | tail -n 200'
fi
run_section "bluetoothctl show" bluetoothctl show
run_section "rfkill" rfkill list bluetooth
run_section "bluetooth service" systemctl status bluetooth --no-pager

python3 "${REPO_ROOT}/scripts/sanitize_logs.py" "${out_file}" >/dev/null

echo "${out_file}"
