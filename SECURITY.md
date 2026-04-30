# Security And Privacy

This repository should not contain credentials, private keys, firmware blobs, or personal machine details.

When sharing logs:

- Use `./scripts/collect_diagnostics.sh` when possible; it writes a sanitized diagnostics file under `logs/`.
- Remove Bluetooth MAC addresses.
- Remove hostnames and usernames.
- Remove serial numbers from USB descriptors if present.
- Do not attach full `btmon` captures unless you have reviewed them.
- Do not share firmware blobs, `.ko` files, build outputs, private keys, tokens, credentials, or pairing databases.

If you find sensitive data in the public repository, open an issue with a minimal description and avoid reposting the sensitive value.
