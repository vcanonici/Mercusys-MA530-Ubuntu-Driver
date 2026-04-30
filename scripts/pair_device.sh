#!/usr/bin/env bash
set -euo pipefail

MAC="${1:-}"
if [[ -z "${MAC}" ]]; then
  echo "Usage: $0 <MAC>"
  exit 1
fi

bluetoothctl <<EOF2
power on
agent KeyboardOnly
default-agent
pair ${MAC}
trust ${MAC}
connect ${MAC}
EOF2
