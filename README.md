# SeKondBrain CLIs — install

The Homebrew tap, prebuilt binaries, and install scripts for the two
SeKondBrain command-line tools. Learn more at
[sekondbrain.ai](https://www.sekondbrain.ai).

| CLI | What it does | Docs |
| --- | --- | --- |
| `kemory` | Persistent memory for AI agents: browser sign-in, MCP bridge, vault search | [docs](https://docs.sekondbrain.ai/kemory/cli/) |
| `s9n` | Connects a coding agent (Claude Code, Cursor) to SeKondBrain over MCP | — |

Both sign you in through the browser; there is no key to paste.

## kemory

**Homebrew (macOS / Linux)**

```sh
brew install sekondbrainailabs/s9n/kemory
```

**Windows** — download `kemory-windows-x64.zip` from the
[releases](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases), unzip
it, and put the folder on your PATH.

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

(Or download `s9n-windows-x64.zip` from the
[latest release](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases/latest),
unzip it, and put the folder on your PATH.)

```sh
s9n login        # sign in via the browser
s9n install      # register the MCP server in Claude Code
# then open Claude Code and run /mcp — it shows connected, no key needed
```

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
