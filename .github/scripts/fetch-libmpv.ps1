<#
.SYNOPSIS
    Downloads the libmpv development package for Windows (x86_64) and extracts
    it into a folder usable by CMake.

.DESCRIPTION
    The shinchiro/mpv-winbuild-cmake builds are the reference source for libmpv
    on Windows (they are what mpv.io distributes). The "mpv-dev" archive contains
    include/mpv/*.h, libmpv.dll.a (MinGW import library) and libmpv-2.dll.

    After extraction:
      <Destination>\include\mpv\client.h
      <Destination>\libmpv.dll.a
      <Destination>\libmpv-2.dll
#>
param(
    [Parameter(Mandatory = $true)]
    [string] $Destination
)

$ErrorActionPreference = 'Stop'

$headers = @{ 'User-Agent' = 'OTTix-CI' }
if ($env:GITHUB_TOKEN) { $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN" }

$release = Invoke-RestMethod -Headers $headers `
    -Uri 'https://api.github.com/repos/shinchiro/mpv-winbuild-cmake/releases/latest'

# mpv-dev-x86_64-<date>-git-<sha>.7z, excluding the "-v3-" variant, which
# requires an x86-64-v3 CPU.
$asset = $release.assets |
    Where-Object { $_.name -match '^mpv-dev-x86_64-\d{8}-' } |
    Select-Object -First 1

if (-not $asset) {
    throw "No mpv-dev-x86_64 package in release $($release.tag_name)"
}

Write-Host "libmpv: $($asset.name) ($($release.tag_name))"

$archive = Join-Path $env:RUNNER_TEMP $asset.name
Invoke-WebRequest -Headers $headers -Uri $asset.browser_download_url -OutFile $archive

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
& 7z x $archive "-o$Destination" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Extraction of $($asset.name) failed" }

foreach ($required in @('include\mpv\client.h', 'libmpv.dll.a', 'libmpv-2.dll')) {
    $path = Join-Path $Destination $required
    if (-not (Test-Path $path)) { throw "Expected file missing after extraction: $required" }
}

Write-Host "libmpv extracted into $Destination"
