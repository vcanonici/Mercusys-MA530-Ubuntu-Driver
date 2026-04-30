# Secure Boot

Secure Boot can prevent locally built kernel modules from loading when they are unsigned.

The MA530 workflow does not create, import, or enroll MOK keys automatically. Key enrollment changes boot trust state and should only happen through an explicit user action.

## Check State

```bash
mokutil --sb-state
```

The installer and DKMS installer run this check when `mokutil` is available.

If Secure Boot is enabled, you may see:

```text
Secure Boot appears to be enabled. Unsigned kernel modules may fail to load.
Check dmesg for module signature errors.
```

## Diagnose Signature Failures

```bash
sudo dmesg | rg -i 'module verification|signature|key rejected|Required key not available'
```

Typical remedies are to disable Secure Boot in firmware settings or sign the built module with a key enrolled through MOK. This repository intentionally does not automate MOK key generation or enrollment.
