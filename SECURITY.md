# Security policy

This repository distributes the **s9n CLI** (Homebrew tap, installers, and
prebuilt binaries). The binaries published here are **production-only**.

## Reporting a vulnerability

Please report security issues privately to **security@sekondbrain.ai** — do not
open a public issue for anything security-sensitive. We aim to acknowledge
reports within two business days.

## Verifying a download

Every release asset ships a `.sha256` sidecar. The `install.sh` and `install.ps1`
installers verify it automatically. To check a manual download:

```sh
shasum -a 256 s9n-macos-universal.tar.gz   # compare with the .sha256 file
```

Homebrew verifies the formula's pinned `sha256` on install.
