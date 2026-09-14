#!/bin/sh
# kemory CLI installer.
#
#   curl -fsSL https://install.sekondbrain.ai/kemory | sh
#
# Downloads the latest prebuilt kemory binary for your OS/arch from the public
# release repo, verifies its SHA-256, installs it under ~/.kemory/lib, and links
# the launcher into a bin dir on your PATH. No Python required.
#
# This is the sibling of install.sh (the s9n installer). Two deliberate
# differences: it resolves `cli-vX.Y.Z` tags rather than `vX.Y.Z`, and it picks a
# per-arch macOS asset because kemory has no universal2 build — its
# `pydantic-core` dependency ships single-arch wheels, so PyInstaller cannot
# fuse a fat binary.
#
# Env overrides:
#   KEMORY_VERSION   pin a version (e.g. cli-v0.6.8); default: latest release
#   KEMORY_BIN_DIR   where to symlink the launcher (default: ~/.local/bin)
#   GITHUB_TOKEN     optional; only used to raise the GitHub API rate limit when
#                    resolving the latest version. Never sent to the download.
set -eu

REPO="SeKondBrainAILabs/homebrew-s9n"
BIN_DIR="${KEMORY_BIN_DIR:-$HOME/.local/bin}"
LIB_ROOT="$HOME/.kemory/lib"

say()  { printf '%s\n' "$*"; }
err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

main() {
  # --- detect platform -------------------------------------------------------
  os=$(uname -s)
  arch=$(uname -m)
  case "$os" in
    Darwin) os_tag="macos" ;;
    Linux)  os_tag="linux" ;;
    *) err "unsupported OS '$os'. On Windows, run this in PowerShell instead:
    irm https://raw.githubusercontent.com/$REPO/refs/heads/main/install-kemory.ps1 | iex" ;;
  esac
  case "$arch" in
    arm64|aarch64) arch_tag="arm64" ;;
    x86_64|amd64)  arch_tag="x64" ;;
    *) err "unsupported architecture '$arch'." ;;
  esac
  target="${os_tag}-${arch_tag}"

  # --- resolve version -------------------------------------------------------
  # The tap holds two products in ONE release stream: kemory tags are
  # `cli-vX.Y.Z`, s9n's are `vX.Y.Z`. /releases/latest returns whichever shipped
  # last, so it cannot be trusted to carry a kemory asset — take the newest tag
  # that is actually a kemory release. The exact-match pattern also skips
  # prereleases (`cli-v0.6.8-rc1`), which /releases lists.
  version="${KEMORY_VERSION:-}"
  if [ -z "$version" ]; then
    api="https://api.github.com/repos/$REPO/releases?per_page=100"
    have curl || have wget || err "need curl or wget."
    releases=$(api_get "$api") || err "could not reach the GitHub API.
    A 403 here is the unauthenticated rate limit — 60 requests/hour per IP,
    which CI runners and anyone behind a shared NAT exhaust routinely. Either
    set GITHUB_TOKEN, or skip the lookup entirely by pinning KEMORY_VERSION."
    version=$(printf '%s' "$releases" \
      | sed -n 's/.*"tag_name" *: *"\([^"]*\)".*/\1/p' \
      | grep -E '^cli-v[0-9]+\.[0-9]+\.[0-9]+$' \
      | head -1)
    [ -n "$version" ] || err "could not find a kemory release (its tags look like cli-v0.6.8). Set KEMORY_VERSION to pin one."
  fi

  archive="kemory-${target}.tar.gz"
  base="https://github.com/$REPO/releases/download/$version"
  say "Installing kemory $version ($target)…"

  # --- download + verify -----------------------------------------------------
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  fetch "$base/$archive" "$tmp/$archive" || err "download failed: $base/$archive"
  if fetch "$base/$archive.sha256" "$tmp/$archive.sha256" 2>/dev/null; then
    expected=$(tr -d '[:space:]' < "$tmp/$archive.sha256")
    if have shasum;      then actual=$(shasum -a 256 "$tmp/$archive" | awk '{print $1}')
    elif have sha256sum; then actual=$(sha256sum "$tmp/$archive" | awk '{print $1}')
    else actual=""; fi
    if [ -n "$actual" ] && [ "$actual" != "$expected" ]; then
      err "checksum mismatch (expected $expected, got $actual)"
    fi
    [ -n "$actual" ] && say "  checksum ok"
  fi

  # --- install ---------------------------------------------------------------
  dest="$LIB_ROOT/$version"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar -xzf "$tmp/$archive" -C "$dest"
  [ -x "$dest/kemory" ] || chmod +x "$dest/kemory" 2>/dev/null || true

  mkdir -p "$BIN_DIR"
  ln -sf "$dest/kemory" "$BIN_DIR/kemory"
  # point a stable "current" symlink at this version too
  ln -sfn "$dest" "$LIB_ROOT/current"

  # macOS: strip the quarantine flag so Gatekeeper doesn't block the unsigned binary
  if [ "$os_tag" = "macos" ] && have xattr; then
    xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true
  fi

  say "✓ Installed kemory → $BIN_DIR/kemory"

  # --- PATH hint -------------------------------------------------------------
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
  say "    kemory login     # sign in (browser)"
  say "    kemory connect   # register the MCP server in your agent"
  say "    kemory doctor    # check the connection"
}

fetch() {
  if have curl; then curl -fsSL "$1" -o "$2"; else wget -qO "$2" "$1"; fi
}

# Only ever used for api.github.com. The token deliberately does not reach
# fetch(): release downloads redirect to a separate asset host, and an
# Authorization header follows the redirect.
api_get() {
  if have curl; then
    if [ -n "${GITHUB_TOKEN:-}" ]
      then curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "$1"
      else curl -fsSL "$1"
    fi
  else
    if [ -n "${GITHUB_TOKEN:-}" ]
      then wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$1"
      else wget -qO- "$1"
    fi
  fi
}

# Everything above is a definition; this is the only line that acts. See the
# same note in install.sh — a truncated pipe must not execute a partial script.
main "$@"
