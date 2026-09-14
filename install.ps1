# s9n CLI installer for Windows (PowerShell).
#
#   irm https://raw.githubusercontent.com/SeKondBrainAILabs/homebrew-s9n/main/install.ps1 | iex
#
# Downloads the latest prebuilt s9n.exe, verifies its SHA-256, installs it under
# %LOCALAPPDATA%\Programs\s9n, and adds that folder to your user PATH.
# No Python required.
#
# Env overrides:
#   $env:S9N_VERSION   pin a version (e.g. v0.2.0); default: latest release
#   $env:GITHUB_TOKEN  optional; only used to raise the GitHub API rate limit
#                      when resolving the latest version. Never sent to the
#                      download, which redirects to a separate asset host.

$ErrorActionPreference = "Stop"
$Repo = "SeKondBrainAILabs/homebrew-s9n"
$Target = "windows-x64"
$Archive = "s9n-$Target.zip"

# --- resolve version ---------------------------------------------------------
# One release stream, two products (see install.sh): s9n tags are vX.Y.Z,
# kemory's are cli-vX.Y.Z, and /releases/latest returns whichever shipped last
# — usually kemory, whose releases carry no s9n asset. Take the newest tag that
# is actually an s9n release. The exact-match pattern also skips prereleases.
$version = $env:S9N_VERSION
if (-not $version) {
  $headers = @{}
  if ($env:GITHUB_TOKEN) { $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN" }
  try {
    $rels = Invoke-RestMethod -UseBasicParsing -Headers $headers "https://api.github.com/repos/$Repo/releases?per_page=100"
  } catch {
    throw "Could not reach the GitHub API. A 403 here is the unauthenticated rate limit (60 requests/hour per IP); set `$env:GITHUB_TOKEN, or pin `$env:S9N_VERSION to skip the lookup. ($_)"
  }
  $version = ($rels | Where-Object { $_.tag_name -match '^v\d+\.\d+\.\d+$' } | Select-Object -First 1).tag_name
}
if (-not $version) { throw "Could not find an s9n release (its tags look like v0.1.3). Set `$env:S9N_VERSION to pin one." }

$base = "https://github.com/$Repo/releases/download/$version"
Write-Host "Installing s9n $version ($Target)..."

# --- download + verify -------------------------------------------------------
$tmp = Join-Path $env:TEMP ("s9n-" + [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $zip = Join-Path $tmp $Archive
  Invoke-WebRequest -UseBasicParsing "$base/$Archive" -OutFile $zip

  # Fetching the sidecar and comparing against it are deliberately separate. A
  # single try/catch around both would let a broadened catch turn a genuine
  # checksum MISMATCH into "skipping verification" — a missing sidecar is
  # tolerable, a wrong hash is not.
  $expected = $null
  try {
    $body = (Invoke-WebRequest -UseBasicParsing "$base/$Archive.sha256").Content
    # GitHub serves the sidecar as application/octet-stream, so PowerShell 7
    # hands back a [byte[]] while Windows PowerShell 5.1 hands back a string.
    # Calling .Trim() on the byte array threw InvalidOperation and aborted the
    # install outright, because $ErrorActionPreference is Stop and the old catch
    # only caught WebException.
    if ($body -is [byte[]]) { $body = [System.Text.Encoding]::UTF8.GetString($body) }
    $expected = $body.Trim().Split()[0].ToLower()
  } catch {
    Write-Host "  (no checksum sidecar; skipping verification)"
  }
  if ($expected) {
    $actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $expected) { throw "Checksum mismatch (expected $expected, got $actual)" }
    Write-Host "  checksum ok"
  }

  # --- install ---------------------------------------------------------------
  $root = Join-Path $env:LOCALAPPDATA "Programs\s9n"
  $dest = Join-Path $root $version
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  New-Item -ItemType Directory -Path $dest | Out-Null
  Expand-Archive -Path $zip -DestinationPath $dest -Force

  # stable "current" junction so PATH never needs updating on upgrade
  $current = Join-Path $root "current"
  if (Test-Path $current) { Remove-Item -Recurse -Force $current }
  cmd /c mklink /J "$current" "$dest" | Out-Null

  # --- PATH --------------------------------------------------------------------
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*$current*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$current", "User")
    Write-Host "  added $current to your user PATH (restart your terminal to pick it up)"
  }
  $env:Path = "$env:Path;$current"

  Write-Host "OK Installed s9n -> $current\s9n.exe"
  Write-Host ""
  Write-Host "Next:"
  Write-Host "    s9n login        # sign in (browser)"
  Write-Host "    s9n install      # wire it into Claude Code, then /mcp"
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
