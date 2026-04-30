#!/usr/bin/env bash
set -euo pipefail

DURATION="${1:-15}"

echo "Scanning for ${DURATION}s..."

timeout "${DURATION}" bluetoothctl scan on || true

echo "Known devices:"
bluetoothctl devices
