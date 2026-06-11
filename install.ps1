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

$ErrorActionPreference = "Stop"
$Repo = "SeKondBrainAILabs/homebrew-s9n"
$Target = "windows-x64"
$Archive = "s9n-$Target.zip"

# --- resolve version ---------------------------------------------------------
$version = $env:S9N_VERSION
if (-not $version) {
  $rel = Invoke-RestMethod -UseBasicParsing "https://api.github.com/repos/$Repo/releases/latest"
  $version = $rel.tag_name
}
if (-not $version) { throw "Could not determine latest version (no releases yet?). Set `$env:S9N_VERSION to pin one." }

$base = "https://github.com/$Repo/releases/download/$version"
Write-Host "Installing s9n $version ($Target)..."

# --- download + verify -------------------------------------------------------
$tmp = Join-Path $env:TEMP ("s9n-" + [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $zip = Join-Path $tmp $Archive
  Invoke-WebRequest -UseBasicParsing "$base/$Archive" -OutFile $zip

  try {
    $expected = (Invoke-WebRequest -UseBasicParsing "$base/$Archive.sha256").Content.Trim()
    $actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $expected) { throw "Checksum mismatch (expected $expected, got $actual)" }
    Write-Host "  checksum ok"
  } catch [System.Net.WebException] {
    Write-Host "  (no checksum sidecar; skipping verification)"
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
