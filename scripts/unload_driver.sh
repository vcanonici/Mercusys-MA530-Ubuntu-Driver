#!/usr/bin/env bash
set -euo pipefail

echo "Unloading btusb..."
sudo modprobe -r btusb || true
