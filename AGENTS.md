# AGENTS.md

This repository is designed to be operated by coding agents as well as humans.

It contains a Linux `btusb` patch and operational scripts for the **Mercusys MA530 Bluetooth Nano USB Adapter**:

- USB ID: `2c4e:0115`
- Chip family: Realtek `RTL8761BU` / `RTL8761BUV`
- Linux path: `btusb` + `btrtl`
- Primary target: Ubuntu or Ubuntu-based Linux

## Mission

When a user says something like "implement the patch", "install this", or "fix my MA530", the agent should attempt a complete driver install/repair without asking for setup details first.

Prioritize:

1. Driver integrity
2. Adapter/controller health
3. Pairing/connectivity state
4. Autoconnect/keepalive consistency

Do not start with pairing actions until driver integrity has been checked.

## Autonomy Model

This file seeds agent autonomy; it is not a cage.

Agents are expected to:

- infer reasonable defaults from the host system;
- create or improve scripts under `scripts/` when missing automation blocks progress;
- add short notes under `notes/` when a new environment-specific workaround is discovered;
- adapt package/source acquisition to the distribution in front of them;
- prefer idempotent commands that can be safely re-run;
- continue from partial progress instead of restarting blindly;
- verify outcomes with commands, not assumptions.

The default no-input command is:

```bash
./scripts/agent_install.sh
```

If that script fails because an environment is different, repair or extend the automation and re-run it. Ask the human only for things an agent cannot infer or perform, such as plugging in hardware, entering a Bluetooth pairing code shown on another device, or approving credentials.

## Safety Rules

- Do not store passwords, tokens, private keys, or credentials.
- Do not publish real Bluetooth MAC addresses, hostnames, serial numbers, or user-specific machine details.
- Do not commit `firmware/`, `driver/build/`, `logs/`, `.ko`, `.btsnoop`, or generated logs.
- Do not delete Bluetooth pairing databases unless explicitly asked.
- Do not run destructive Git commands.
- Use command output and reproducible checks as the source of truth.
- If local automation must be changed to complete the install, keep changes scoped and document the reason.

## Repository Map

- `patches/btusb-ma530.patch`: patch that adds MA530 `2c4e:0115` to `btusb` Realtek handling.
- `patches/btusb-ma530-minimal.patch`: preferred minimal patch; it only adds the MA530 USB ID to the Realtek `btusb` table.
- `scripts/prepare_source.sh`: validates a prepared out-of-tree `btusb` source tree and applies the patch.
- `scripts/bootstrap_source.sh`: creates a minimal out-of-tree `btusb` source tree from local or installable Linux source when needed.
- `scripts/agent_install.sh`: no-input install/repair entry point for coding agents.
- `scripts/verify_driver.sh`: central driver/controller verification script with stable return codes.
- `scripts/uninstall_driver.sh`: removes only installed `/updates` modules and reloads stock `btusb` when possible.
- `scripts/dkms_prepare.sh`, `scripts/dkms_install.sh`, `scripts/dkms_remove.sh`: optional DKMS workflow.
- `scripts/collect_diagnostics.sh`: collects and sanitizes issue diagnostics.
- `scripts/build_driver.sh`: builds `btusb.ko` for the current or specified kernel.
- `scripts/install_driver.sh`: installs the built module to `/lib/modules/<kver>/updates/`.
- `scripts/load_driver.sh`: reloads `btusb` so Linux uses the installed module.
- `scripts/driver_status.sh`: prints active `btusb` module status.
- `scripts/scan_devices.sh`: scans for Bluetooth devices.
- `scripts/pair_device.sh`: pairs, trusts, and connects a Bluetooth device.
- `scripts/install_system_integration.sh`: installs system autoconnect and MA530 autosuspend rules.
- `scripts/install_user_autoconnect.sh`: installs user-session autoconnect.
- `scripts/disable_autosuspend.sh`: disables USB autosuspend for MA530.
- `scripts/keep_bt_connected.sh`: loop used by keepalive services.
- `notes/`: background runbooks and investigation notes.

## Agent Inputs

No input is required for the default driver install path. Agents may receive optional environment variables:

- `BTUSB_SRC_DIR`: override for the out-of-tree `btusb` source directory. Default: `/usr/src/btusb-4.3`.
- `TARGET_BT_MAC`: optional Bluetooth MAC to pair/connect/trust after driver install.
- `KVER`: optional target kernel version. Default: `$(uname -r)`.
- `MA530_USE_DKMS`: set to `1` to use DKMS through `scripts/agent_install.sh`; set to `0` for the manual `/updates` flow.

If `BTUSB_SRC_DIR` is missing, the agent should create it. Start with `scripts/bootstrap_source.sh`; if that is insufficient, extend the script. Viable source strategies include:

- reuse an existing `/usr/src/btusb-4.3`;
- use an installed `/usr/src/linux-source-*` tree;
- install and extract the `linux-source` package;
- use distribution source packages when available;
- as a fallback, fetch a matching or nearby upstream kernel source and adapt the patch if the local kernel API allows it.

The goal is not to preserve one exact source acquisition method; the goal is to produce a `btusb.ko` that builds against `/lib/modules/<kver>/build` and binds MA530 `2c4e:0115` through Realtek `btusb` handling.

## Single-Shot Install Flow

Use this flow for an autonomous install/repair pass. Prefer the short form first:

```bash
./scripts/agent_install.sh
```

Expanded equivalent:

```bash
set -euo pipefail

export KVER="${KVER:-$(uname -r)}"
export BTUSB_SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"

echo "== Environment =="
uname -r
lsusb | rg -i '2c4e:0115|mercusys' || {
  echo "MA530 adapter not found as 2c4e:0115. Continuing driver install; final hardware verification may require plugging it in."
}

echo "== Dependencies =="
sudo apt update
sudo apt install -y --no-upgrade build-essential "linux-headers-${KVER}" bluez usbutils ripgrep patch

echo "== Source =="
./scripts/bootstrap_source.sh "${BTUSB_SRC_DIR}"
./scripts/prepare_source.sh "${BTUSB_SRC_DIR}"

echo "== Build/install/load =="
if [[ "${MA530_USE_DKMS:-0}" == "1" ]]; then
  ./scripts/dkms_install.sh
else
  ./scripts/build_driver.sh "${KVER}"
  ./scripts/install_driver.sh "${KVER}"
  ./scripts/load_driver.sh "${KVER}"
fi

echo "== Verify driver =="
./scripts/verify_driver.sh "${KVER}"

echo "== Optional pairing =="
if [[ -n "${TARGET_BT_MAC:-}" ]]; then
  ./scripts/pair_device.sh "${TARGET_BT_MAC}"
  bluetoothctl info "${TARGET_BT_MAC}"
  sudo ./scripts/install_system_integration.sh "${TARGET_BT_MAC}"
  ./scripts/disable_autosuspend.sh
else
  echo "TARGET_BT_MAC not set; driver install complete without pairing."
fi
```

## Success Criteria

An install/repair is successful when all of these are true:

- `modinfo -n btusb` resolves to `/lib/modules/<kver>/updates/btusb.ko`.
- `modinfo /lib/modules/<kver>/updates/btusb.ko` has `vermagic` matching the target kernel.
- `lsmod` shows `btusb`, `btrtl`, and `bluetooth`.
- `scripts/verify_driver.sh` exits with `0`.
- If the compatibility patch was used, `dmesg` may contain the MA530 marker: `MA530: binding RTL8761BU via btusb`.
- `dmesg` contains Realtek firmware loading, usually `rtl8761bu_fw.bin`.
- `bluetoothctl show` reports a controller.

If `TARGET_BT_MAC` was provided, also verify:

- `bluetoothctl info <MAC>` shows `Trusted: yes`.
- `Connected: yes` is preferred, but transient `Connected: no` can happen if the device is asleep.
- Only one keepalive/autoconnect service should target the current MAC for the same keyboard.

## First Response Checklist

Before changing pairing or service state, run:

```bash
uname -r
modinfo -n btusb || true
modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version' || true
lsmod | rg -n '^btusb|^btrtl|^bluetooth' || true
./scripts/verify_driver.sh || true
```

If the custom module is missing or built for a different kernel, rebuild/install/load before pairing.

## Keyboard Recovery Flow

1. Confirm adapter/controller:

```bash
lsusb | rg -i '2c4e:0115|mercusys'
hciconfig -a
bluetoothctl show
```

2. Discover the current keyboard address:

```bash
./scripts/scan_devices.sh 20
bluetoothctl devices
```

3. Pair/connect/trust:

```bash
./scripts/pair_device.sh <MAC>
bluetoothctl info <MAC>
```

4. Install reconnect support:

```bash
sudo ./scripts/install_system_integration.sh <MAC>
./scripts/disable_autosuspend.sh
```

BLE keyboards may rotate addresses. Disable stale services bound to old MACs.

## Rebuild After Kernel Update

```bash
export KVER="$(uname -r)"
export BTUSB_SRC_DIR="${BTUSB_SRC_DIR:-/usr/src/btusb-4.3}"
./scripts/bootstrap_source.sh "${BTUSB_SRC_DIR}"
./scripts/prepare_source.sh "${BTUSB_SRC_DIR}"
./scripts/build_driver.sh "${KVER}"
./scripts/install_driver.sh "${KVER}"
./scripts/load_driver.sh "${KVER}"
modinfo -n btusb
sudo dmesg | rg -i 'MA530|RTL|btusb' | tail -n 80
```

## Adaptive Recovery

Before asking the human, try to recover:

- If the MA530 adapter is not visible as `2c4e:0115`, still build/install the driver, then ask the user to plug the adapter in for final verification.
- If `BTUSB_SRC_DIR` is missing, create it with `scripts/bootstrap_source.sh`.
- If `bootstrap_source.sh` cannot find kernel source, install `linux-source` or use the distro's source package mechanism.
- If the patch does not apply cleanly, inspect `btusb.c`, add the MA530 `USB_DEVICE` entry near other Realtek 8761BU devices, keep the `MA530` log marker, then rebuild.
- If `make` fails, read the compiler error and adapt the minimal out-of-tree source for the running kernel headers.
- If `modinfo -n btusb` does not point to `/updates/`, inspect `depmod`, module priority, and install location before asking for help.
- If `bluetoothctl show` reports no controller, check `dmesg`, `rfkill`, `systemctl status bluetooth`, and whether the adapter is physically present.
- Prefer DKMS when available by using `MA530_USE_DKMS=1 ./scripts/agent_install.sh`; use the manual flow when DKMS is unavailable or actively being debugged.
- Always run `scripts/verify_driver.sh` after installing or changing the module, and do not run pairing/autoconnect actions until driver and controller checks are complete.
- Use `scripts/collect_diagnostics.sh` for issue reports and do not publish logs before sanitization.

Only stop for a human when progress requires physical action, credentials, unavailable network/package access, or a policy-sensitive operation.

## Tool Creation Guidelines

Agents may add tooling when it helps complete the install in one pass.

Good tools are:

- idempotent;
- explicit about what they install or modify;
- safe to re-run after a kernel update;
- verbose enough for issue reports;
- scoped to MA530 / `btusb` / Bluetooth recovery.

Good candidates:

- source bootstrap improvements;
- distro detection;
- module verification;
- DKMS packaging;
- service cleanup for stale Bluetooth MACs;
- sanitized diagnostic bundle creation.

Avoid committing generated build outputs, firmware, or private logs.

## Good Issue Data

When preparing an issue, collect sanitized output:

```bash
uname -r
lsusb | rg -i '2c4e:0115|mercusys'
modinfo -n btusb
modinfo /lib/modules/$(uname -r)/updates/btusb.ko | rg -n 'srcversion|vermagic|version'
lsmod | rg -n '^btusb|^btrtl|^bluetooth'
sudo dmesg | rg -i 'MA530|RTL|btusb' | tail -n 120
bluetoothctl show
```

Remove Bluetooth MAC addresses and personal device names before posting.
