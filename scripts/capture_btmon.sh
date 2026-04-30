#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
out_root="${REPO_ROOT}/logs"
run_id="$(date +"%Y%m%d-%H%M%S")"
out_dir="${out_root}/${run_id}"
mkdir -p "${out_dir}"

out_snoop="${out_dir}/btmon-${run_id}.btsnoop"
out_txt="${out_dir}/btmon-${run_id}.log"

echo "Starting btmon capture..."
echo "Output: ${out_snoop}"
echo "Tip: replug the dongle or run scripts/rebind_btusb.sh while this runs."
echo "Press Ctrl+C to stop."

sudo btmon -w "${out_snoop}" | tee "${out_txt}"
