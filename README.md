# SeKondBrain CLIs — install

The Homebrew tap, prebuilt binaries, and install scripts for the two
SeKondBrain command-line tools. Learn more at
[sekondbrain.ai](https://www.sekondbrain.ai).

| CLI | What it does | Docs |
| --- | --- | --- |
| `kemory` | Persistent memory for AI agents: browser sign-in, MCP bridge, vault search | [docs](https://docs.sekondbrain.ai/kemory/cli/) |
| `s9n` | Connects a coding agent (Claude Code, Cursor) to SeKondBrain over MCP | — |

Both sign you in through the browser; there is no key to paste.

## Supported platforms

| Platform | `kemory` | `s9n` |
| --- | --- | --- |
| macOS arm64 | Homebrew, curl, direct download | Homebrew, curl, direct download |
| macOS x86_64 | Homebrew, curl, direct download | Homebrew, curl, direct download |
| Linux x86_64 / arm64 | Homebrew, curl, direct download | Homebrew, curl, direct download |
| Windows x64 | PowerShell installer, direct download | PowerShell installer, direct download |

Homebrew runs on Linux as well as macOS, and both formulae carry Linux builds —
`brew` is not a macOS-only route. Two build constraints worth knowing:

- `kemory` ships **separate per-arch macOS binaries**, not a universal2 one. Its
  `pydantic-core` dependency publishes single-arch wheels, so there is no fat
  binary to build. `s9n` does ship universal2.
- The **Intel macOS** builds are produced on GitHub's `macos-15-intel` runner,
  which GitHub retires in **August 2027**. There is no x86_64 macOS image after
  that.

## kemory

**Homebrew (macOS / Linux)**

```sh
brew install sekondbrainailabs/s9n/kemory
```

**curl (macOS / Linux)** — no Homebrew needed, which is also the route to use
in CI and containers:

```sh
curl -fsSL https://install.sekondbrain.ai/kemory | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/SeKondBrainAILabs/homebrew-s9n/refs/heads/main/install-kemory.ps1 | iex
```

Or download `kemory-windows-x64.zip` by hand from the
[releases](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases) — pick the
newest tag shaped `cli-vX.Y.Z` — unzip it, and put the folder on your PATH.

```sh
kemory login     # sign in via the browser
kemory connect   # register the MCP server in your agent
kemory doctor    # check the connection
```

Full command reference: [docs.sekondbrain.ai/kemory/cli](https://docs.sekondbrain.ai/kemory/cli/).

## s9n

**Homebrew (macOS / Linux)**

```sh
brew install sekondbrainailabs/s9n/s9n
```

**curl (macOS / Linux)**

```sh
curl -fsSL https://install.sekondbrain.ai | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/SeKondBrainAILabs/homebrew-s9n/refs/heads/main/install.ps1 | iex
```

Or download `s9n-windows-x64.zip` by hand from the
[releases](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases) — pick the
newest tag shaped `vX.Y.Z`. Do **not** use the "Latest" release badge: this repo
publishes both products into one release stream, so "Latest" is usually a
`cli-vX.Y.Z` kemory release, which carries no `s9n` asset at all.

```sh
s9n login        # sign in via the browser
s9n install      # register the MCP server in Claude Code
# then open Claude Code and run /mcp — it shows connected, no key needed
```

## Upgrading

| Installed with | Upgrade with |
| --- | --- |
| Homebrew | `brew upgrade kemory` / `brew upgrade s9n` |
| curl (`install.sh` / `install-kemory.sh`) | re-run the same curl command |
| PowerShell (`install.ps1` / `install-kemory.ps1`) | re-run the same `irm … \| iex` command |
| direct download | download the new archive and replace the folder |

`kemory` can also update itself: `kemory upgrade` (`kemory doctor` reports
whether you are behind).

## Pinning a version

The install scripts take a version override, which is also how you roll back:

```sh
S9N_VERSION=v0.1.3 curl -fsSL https://install.sekondbrain.ai | sh
```

```powershell
$env:S9N_VERSION = "v0.1.3"; irm https://raw.githubusercontent.com/SeKondBrainAILabs/homebrew-s9n/refs/heads/main/install.ps1 | iex
```

`kemory` uses `KEMORY_VERSION` and its tags carry the `cli-` prefix:

```sh
KEMORY_VERSION=cli-v0.6.8 curl -fsSL https://install.sekondbrain.ai/kemory | sh
```

For Homebrew, install from a pinned formula revision rather than pinning here.

## Uninstalling

| Installed with | Remove with |
| --- | --- |
| Homebrew | `brew uninstall kemory` / `brew uninstall s9n` |
| curl | `rm -rf ~/.s9n/lib ~/.local/bin/s9n` (kemory: `~/.kemory/lib`, `~/.local/bin/kemory`) |
| PowerShell | delete `%LOCALAPPDATA%\Programs\s9n` (or `…\kemory`) and remove it from your user PATH |

Neither CLI writes outside those paths, but both store credentials separately —
`kemory logout` / `s9n logout` first if you want the machine signed out.

## Verifying a manual download

Every release asset ships a `.sha256` sidecar; check it before running the
binary. See [SECURITY.md](SECURITY.md) for the exact commands.

The published binaries are **not yet code-signed or notarized**. Homebrew and
the install scripts handle this for you (the scripts clear the quarantine
attribute), but a macOS binary you download and unpack by hand is quarantined by
Gatekeeper and refuses to launch. Clear it yourself:

```sh
xattr -dr com.apple.quarantine ~/Downloads/kemory-macos-arm64
```

On Windows, SmartScreen will warn about the unsigned `.exe` on first run.

## How updates work

Both products publish into this repo's
[Releases](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases), in two
tag namespaces:

| Tag | Product | Formula regenerated |
| --- | --- | --- |
| `cli-vX.Y.Z` | `kemory` | `Formula/kemory.rb`, by the kemory release-cli workflow |
| `vX.Y.Z` | `s9n` | `Formula/s9n.rb`, by the s9n release workflow |

`brew upgrade kemory` / `brew upgrade s9n` picks up the new version. Because the
two namespaces share one release stream, anything resolving a version must
filter by tag shape rather than asking for the newest release — see the comment
in `install.sh`.
