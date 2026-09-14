# kemory CLI installer for Windows (PowerShell).
#
#   irm https://raw.githubusercontent.com/SeKondBrainAILabs/homebrew-s9n/refs/heads/main/install-kemory.ps1 | iex
#
# Downloads the latest prebuilt kemory.exe, verifies its SHA-256, installs it
# under %LOCALAPPDATA%\Programs\kemory, and adds that folder to your user PATH.
# No Python required.
#
# Sibling of install.ps1 (the s9n installer); the difference is the product and
# the cli-vX.Y.Z tag namespace.
#
# Env overrides:
#   $env:KEMORY_VERSION   pin a version (e.g. cli-v0.6.8); default: latest release
#   $env:GITHUB_TOKEN     optional; only used to raise the GitHub API rate limit
#                         when resolving the latest version. Never sent to the
#                         download, which redirects to a separate asset host.

$ErrorActionPreference = "Stop"
$Repo = "SeKondBrainAILabs/homebrew-s9n"
$Target = "windows-x64"
$Archive = "kemory-$Target.zip"

# --- resolve version ---------------------------------------------------------
# One release stream, two products (see install-kemory.sh): kemory tags are
# cli-vX.Y.Z, s9n's are vX.Y.Z, and /releases/latest returns whichever shipped
# last — so it cannot be trusted to carry a kemory asset. Take the newest tag
# that is actually a kemory release. The exact-match pattern also skips
# prereleases.
$version = $env:KEMORY_VERSION
if (-not $version) {
  $headers = @{}
  if ($env:GITHUB_TOKEN) { $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN" }
  try {
    $rels = Invoke-RestMethod -UseBasicParsing -Headers $headers "https://api.github.com/repos/$Repo/releases?per_page=100"
  } catch {
    throw "Could not reach the GitHub API. A 403 here is the unauthenticated rate limit (60 requests/hour per IP); set `$env:GITHUB_TOKEN, or pin `$env:KEMORY_VERSION to skip the lookup. ($_)"
  }
  $version = ($rels | Where-Object { $_.tag_name -match '^cli-v\d+\.\d+\.\d+$' } | Select-Object -First 1).tag_name
}
if (-not $version) { throw "Could not find a kemory release (its tags look like cli-v0.6.8). Set `$env:KEMORY_VERSION to pin one." }

$base = "https://github.com/$Repo/releases/download/$version"
Write-Host "Installing kemory $version ($Target)..."

# --- download + verify -------------------------------------------------------
$tmp = Join-Path $env:TEMP ("kemory-" + [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $zip = Join-Path $tmp $Archive
  Invoke-WebRequest -UseBasicParsing "$base/$Archive" -OutFile $zip

  # Fetching the sidecar and comparing against it are deliberately separate — a
  # single broadened catch would turn a checksum MISMATCH into "skipping
  # verification". See the same note in install.ps1.
  $expected = $null
  try {
    $body = (Invoke-WebRequest -UseBasicParsing "$base/$Archive.sha256").Content
    # GitHub serves the sidecar as application/octet-stream, so PowerShell 7
    # returns .Content as a [byte[]] and 5.1 returns a string.
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
  $root = Join-Path $env:LOCALAPPDATA "Programs\kemory"
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

  Write-Host "OK Installed kemory -> $current\kemory.exe"
  Write-Host ""
  Write-Host "Next:"
  Write-Host "    kemory login     # sign in (browser)"
  Write-Host "    kemory connect   # register the MCP server in your agent"
  Write-Host "    kemory doctor    # check the connection"
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
