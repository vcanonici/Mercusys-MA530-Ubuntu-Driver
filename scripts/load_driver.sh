#!/usr/bin/env bash
set -euo pipefail

KVER="${1:-$(uname -r)}"

echo "Unloading btusb..."
sudo modprobe -r btusb || true

# Ensure dependencies are available
sudo modprobe btrtl || true
sudo modprobe btbcm || true
sudo modprobe btintel || true
sudo modprobe btmtk || true

# Load btusb (should pick /updates if installed)
sudo modprobe btusb

modinfo -n btusb
