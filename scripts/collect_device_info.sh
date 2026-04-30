#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
out_root="${REPO_ROOT}/logs"
run_id="$(date +"%Y%m%d-%H%M%S")"
out_dir="${out_root}/${run_id}"

mkdir -p "${out_dir}"

run_cmd() {
  local outfile="$1"
  shift
  {
    echo "# $*"
    echo
    "$@"
  } >"${outfile}" 2>&1 || true
}

run_cmd "${out_dir}/uname.txt" uname -a
run_cmd "${out_dir}/lsusb.txt" lsusb
run_cmd "${out_dir}/lsusb-2c4e-0115.txt" lsusb -d 2c4e:0115 -v
run_cmd "${out_dir}/usb-devices.txt" usb-devices
run_cmd "${out_dir}/hciconfig.txt" hciconfig -a
run_cmd "${out_dir}/bluetoothctl-show.txt" bluetoothctl show
run_cmd "${out_dir}/btmgmt-info.txt" timeout 5 btmgmt info
run_cmd "${out_dir}/lsmod.txt" lsmod
run_cmd "${out_dir}/modinfo-btusb.txt" modinfo btusb
run_cmd "${out_dir}/modinfo-btrtl.txt" modinfo btrtl
run_cmd "${out_dir}/btusb-sysfs.txt" ls -la /sys/bus/usb/drivers/btusb
run_cmd "${out_dir}/rtl_bt-dir.txt" ls -la /lib/firmware/rtl_bt
run_cmd "${out_dir}/journalctl-k-tail.txt" bash -c 'journalctl -k | tail -n 400'
run_cmd "${out_dir}/dmesg.txt" bash -c 'sudo dmesg'

printf "Saved logs to: %s\n" "${out_dir}"
