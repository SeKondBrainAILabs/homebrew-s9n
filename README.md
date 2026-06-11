# s9n CLI — install

Connect your coding agent (Claude Code, Cursor) to SeKondBrain over MCP with a
browser sign-in — no key to paste. This repo holds the prebuilt binaries, the
Homebrew tap, and the install script. Learn more at
[sekondbrain.ai](https://www.sekondbrain.ai).

## Install

**Homebrew (macOS / Linux)**

```sh
brew install sekondbrainailabs/s9n/s9n
```

**curl (macOS / Linux)**

```sh
curl -fsSL https://get.s9n.ai | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/SeKondBrainAILabs/homebrew-s9n/main/install.ps1 | iex
```

(Or download `s9n-windows-x64.zip` from the
[latest release](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases/latest),
unzip it, and put the folder on your PATH.)

## Use

```sh
s9n login        # sign in via the browser
s9n install      # register the MCP server in Claude Code
# then open Claude Code and run /mcp — it shows connected, no key needed
```

## How updates work

Each tagged release publishes the per-platform binaries to this repo's
[Releases](https://github.com/SeKondBrainAILabs/homebrew-s9n/releases) and
regenerates `Formula/s9n.rb` via CI. `brew upgrade s9n` picks up the new version.
