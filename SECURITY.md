# Security policy

This repository distributes the **`kemory` and `s9n` CLIs** — the Homebrew tap,
the installers, and the prebuilt binaries for both. The binaries published here
are **production-only**.

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

```powershell
Get-FileHash kemory-windows-x64.zip -Algorithm SHA256
```

Homebrew verifies the formula's pinned `sha256` on install.

The binaries are **not yet code-signed or notarized**, so the checksum is
currently the only integrity check available for a manual download. macOS
quarantines an unpacked binary until you clear the attribute — see
[README.md](README.md#verifying-a-manual-download).
