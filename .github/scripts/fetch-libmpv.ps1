<#
.SYNOPSIS
    Telecharge le paquet libmpv de developpement pour Windows (x86_64) et
    l'extrait dans un dossier utilisable par CMake.

.DESCRIPTION
    Les builds shinchiro/mpv-winbuild-cmake sont la source de reference pour
    libmpv sous Windows (c'est ce que distribue mpv.io). L'archive "mpv-dev"
    contient include/mpv/*.h, libmpv.dll.a (import MinGW) et libmpv-2.dll.

    Apres extraction :
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

# mpv-dev-x86_64-<date>-git-<sha>.7z, en excluant la variante "-v3-" qui exige
# un CPU x86-64-v3.
$asset = $release.assets |
    Where-Object { $_.name -match '^mpv-dev-x86_64-\d{8}-' } |
    Select-Object -First 1

if (-not $asset) {
    throw "Aucun paquet mpv-dev-x86_64 dans la release $($release.tag_name)"
}

Write-Host "libmpv : $($asset.name) ($($release.tag_name))"

$archive = Join-Path $env:RUNNER_TEMP $asset.name
Invoke-WebRequest -Headers $headers -Uri $asset.browser_download_url -OutFile $archive

New-Item -ItemType Directory -Force -Path $Destination | Out-Null
& 7z x $archive "-o$Destination" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Extraction de $($asset.name) echouee" }

foreach ($required in @('include\mpv\client.h', 'libmpv.dll.a', 'libmpv-2.dll')) {
    $path = Join-Path $Destination $required
    if (-not (Test-Path $path)) { throw "Fichier attendu absent apres extraction : $required" }
}

Write-Host "libmpv extrait dans $Destination"
