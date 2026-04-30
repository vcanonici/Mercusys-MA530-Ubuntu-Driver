#!/usr/bin/env bash
set -euo pipefail

base="${1:-rtl8761bu}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
dest_dir="${REPO_ROOT}/firmware"
mkdir -p "${dest_dir}"

copy_one() {
  local name="$1"
  local src="/lib/firmware/rtl_bt/${name}"

  if [[ -f "${src}" ]]; then
    cp -f "${src}" "${dest_dir}/"
    echo "Copied ${src}"
    return 0
  fi

  if [[ -f "${src}.zst" ]]; then
    cp -f "${src}.zst" "${dest_dir}/"
    if command -v unzstd >/dev/null 2>&1; then
      unzstd -f "${dest_dir}/${name}.zst" -o "${dest_dir}/${name}"
    else
      echo "unzstd not found; leaving ${name}.zst only"
    fi
    echo "Copied ${src}.zst"
    return 0
  fi

  echo "Missing firmware: ${src}(.zst)"
  return 1
}

copy_one "${base}_fw.bin" || true
copy_one "${base}_config.bin" || true

sha256sum "${dest_dir}/${base}_fw.bin" "${dest_dir}/${base}_config.bin" \
  2>/dev/null | tee "${dest_dir}/${base}_hashes.txt"
