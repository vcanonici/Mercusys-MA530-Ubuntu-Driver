# MA530 RE - Plan (rtl8761bu)

## Phase 0: Confirm Target and Gather Artifacts
- Confirm HCI version/revision and LMP subversion (done).
- Confirm firmware mapping via btrtl.c (done, inferred).
- Collect firmware + config blobs (done).

## Phase 1: Understand Firmware Format
- Inspect headers/sections with hexdump and strings.
- Read btrtl.c firmware parsing routines to mirror layout.
- Write a small parser to split sections and dump metadata.

## Phase 2: Observe Live Firmware Download
- Capture HCI vendor traffic during attach (btmon).
- Compare offsets/lengths to parser output to validate format.

## Phase 3: Config Analysis
- Identify fields in rtl8761bu_config.bin (very small).
- Map potential BD_ADDR or RF settings if present.

## Phase 4: Patch and Test (Safe)
- Patch config first (low risk) and reload via driver override.
- Only consider firmware patching after format is clear.

## Phase 5: Firmware Patching (High Risk)
- Identify patch table / relocation mechanism.
- Implement a patch injector and confirm device boots.

## Risks
- Realtek firmware is closed and undocumented; high effort.
- A bad patch can brick the dongle until power cycle.
