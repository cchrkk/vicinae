# Usage: scripts/mkportable.ps1 [-BuildDir build-release] [-OutDir <BuildDir>] [-Arch x64]
# Produces a self-contained portable zip: the binaries, Qt runtime and themes
# are all bundled next to each other, and the app stores its data (config,
# cache, state, logs) inside the extracted folder instead of %LOCALAPPDATA%.
param(
    [string]$BuildDir = "build-release",
    [string]$OutDir = "",
    [string]$Arch = "x64"
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot

$BuildDir = Join-Path $root $BuildDir
if (-not (Test-Path (Join-Path $BuildDir "CMakeCache.txt"))) {
    throw "no CMake build at $BuildDir (configure and build first)"
}

try { $version = git -C $root describe --tags --abbrev=0 2>$null } catch { $version = $null }
if ($version) { $version = $version -replace '^v', '' } else { $version = "0.0.0" }

cmake --build $BuildDir --target vicinae-server vicinae
if ($LASTEXITCODE -ne 0) { throw "cmake --build failed" }

$stage = Join-Path $BuildDir "portable"
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
cmake --install $BuildDir --prefix $stage
if ($LASTEXITCODE -ne 0) { throw "cmake --install failed" }

# Portable marker so the app forces portable mode even from read-only media.
New-Item -ItemType File -Force -Path (Join-Path $stage "vicinae.portable") | Out-Null

if ($OutDir) { $OutDir = Join-Path $root $OutDir } else { $OutDir = $BuildDir }
$zip = Join-Path $OutDir "vicinae-windows-$Arch-portable-$version.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }

# Zip the *contents* of the stage dir so extraction yields a clean top-level
# folder (bin/, themes/, qml/, ...) with nothing written outside of it.
$tmp = Join-Path $BuildDir "portable-wrap"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Force -Path (Join-Path $tmp "vicinae-portable") | Out-Null
Copy-Item (Join-Path $stage "*") -Destination (Join-Path $tmp "vicinae-portable") -Recurse -Force

Compress-Archive -Path (Join-Path $tmp "vicinae-portable") -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -Recurse -Force $tmp

Write-Host ("portable zip: {0} ({1:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))