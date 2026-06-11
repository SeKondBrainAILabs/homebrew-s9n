#!/bin/sh
# s9n CLI installer.
#
#   curl -fsSL https://get.s9n.ai | sh
#
# Downloads the latest prebuilt s9n binary for your OS/arch from the public
# release repo, verifies its SHA-256, installs it under ~/.s9n/lib, and links
# the launcher into a bin dir on your PATH. No Python required.
#
# Env overrides:
#   S9N_VERSION   pin a version (e.g. v0.2.0); default: latest release
#   S9N_BIN_DIR   where to symlink the launcher (default: ~/.local/bin)
set -eu

REPO="SeKondBrainAILabs/homebrew-s9n"
BIN_DIR="${S9N_BIN_DIR:-$HOME/.local/bin}"
LIB_ROOT="$HOME/.s9n/lib"

say()  { printf '%s\n' "$*"; }
err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- detect platform ---------------------------------------------------------
os=$(uname -s)
arch=$(uname -m)
case "$os" in
  Darwin) os_tag="macos" ;;
  Linux)  os_tag="linux" ;;
  *) err "unsupported OS '$os'. On Windows use: scoop install s9n (or download the zip release)." ;;
esac
case "$arch" in
  arm64|aarch64) arch_tag="arm64" ;;
  x86_64|amd64)  arch_tag="x64" ;;
  *) err "unsupported architecture '$arch'." ;;
esac
# macOS ships a single universal2 binary (Apple Silicon + Intel).
if [ "$os_tag" = "macos" ]; then
  target="macos-universal"
else
  target="${os_tag}-${arch_tag}"
fi

# --- resolve version ---------------------------------------------------------
version="${S9N_VERSION:-}"
if [ -z "$version" ]; then
  api="https://api.github.com/repos/$REPO/releases/latest"
  if have curl; then
    version=$(curl -fsSL "$api" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/')
  elif have wget; then
    version=$(wget -qO- "$api" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/')
  else
    err "need curl or wget."
  fi
  [ -n "$version" ] || err "could not determine latest version (no releases yet?). Set S9N_VERSION to pin one."
fi

archive="s9n-${target}.tar.gz"
base="https://github.com/$REPO/releases/download/$version"
say "Installing s9n $version ($target)…"

# --- download + verify -------------------------------------------------------
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fetch() {
  if have curl; then curl -fsSL "$1" -o "$2"; else wget -qO "$2" "$1"; fi
}
fetch "$base/$archive" "$tmp/$archive" || err "download failed: $base/$archive"
if fetch "$base/$archive.sha256" "$tmp/$archive.sha256" 2>/dev/null; then
  expected=$(tr -d '[:space:]' < "$tmp/$archive.sha256")
  if have shasum;     then actual=$(shasum -a 256 "$tmp/$archive" | awk '{print $1}')
  elif have sha256sum; then actual=$(sha256sum "$tmp/$archive" | awk '{print $1}')
  else actual=""; fi
  if [ -n "$actual" ] && [ "$actual" != "$expected" ]; then
    err "checksum mismatch (expected $expected, got $actual)"
  fi
  [ -n "$actual" ] && say "  checksum ok"
fi

# --- install -----------------------------------------------------------------
dest="$LIB_ROOT/$version"
rm -rf "$dest"
mkdir -p "$dest"
tar -xzf "$tmp/$archive" -C "$dest"
[ -x "$dest/s9n" ] || chmod +x "$dest/s9n" 2>/dev/null || true

mkdir -p "$BIN_DIR"
ln -sf "$dest/s9n" "$BIN_DIR/s9n"
# point a stable "current" symlink at this version too
ln -sfn "$dest" "$LIB_ROOT/current"

# macOS: strip the quarantine flag so Gatekeeper doesn't block the unsigned binary
if [ "$os_tag" = "macos" ] && have xattr; then
  xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true
fi

say "✓ Installed s9n → $BIN_DIR/s9n"

# --- PATH hint ---------------------------------------------------------------
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    say ""
    say "⚠  $BIN_DIR is not on your PATH. Add it:"
    say "    echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc && exec \$SHELL"
    ;;
esac

say ""
say "Next:"
say "    s9n login        # sign in (browser)"
say "    s9n install      # wire it into Claude Code, then /mcp"
