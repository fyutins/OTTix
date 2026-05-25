$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$BuildDir    = Join-Path $ProjectRoot "build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug"
$InstallerDir = Join-Path $ProjectRoot "installer"
$DataDir     = Join-Path $InstallerDir "packages\com.iptvplayer\data"

# ── 1. Clean and recreate data dir ──
if (Test-Path $DataDir) { Remove-Item -Recurse -Force $DataDir }
New-Item -ItemType Directory -Path $DataDir | Out-Null

# ── 2. Copy app exe ──
Write-Host "Copying appIptvPlayer.exe ..."
Copy-Item (Join-Path $BuildDir "appIptvPlayer.exe") $DataDir

# ── 3. windeployqt ──
Write-Host "Running windeployqt ..."
$Windeploy = "C:\Qt\6.11.0\mingw_64\bin\windeployqt.exe"
& $Windeploy --qmldir $ProjectRoot (Join-Path $DataDir "appIptvPlayer.exe") 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "windeployqt failed"; exit 1 }

# ── 4. Copy mpv DLL ──
Write-Host "Copying libmpv-2.dll ..."
Copy-Item "C:\tools\mpv\libmpv-2.dll" $DataDir

# ── 5. Copy IptvPlayer QML module (qmldir + .qmltypes) ──
Write-Host "Copying IptvPlayer QML module ..."
Copy-Item -Recurse (Join-Path $BuildDir "IptvPlayer") (Join-Path $DataDir "IptvPlayer")

# ── 6. Remove software OpenGL (causes window-move freeze with mpv) ──
Write-Host "Removing opengl32sw.dll (use system OpenGL instead) ..."
Remove-Item (Join-Path $DataDir "opengl32sw.dll") -ErrorAction SilentlyContinue

# ── 7. Run binarycreator ──
Write-Host "Building installer ..."
$BinaryCreator = "C:\Qt\Tools\QtInstallerFramework\4.11\bin\binarycreator.exe"
$InstallerOut  = Join-Path $InstallerDir "IPTVPlayer-0.1.0-Setup.exe"

& $BinaryCreator `
    -c (Join-Path $InstallerDir "config\config.xml") `
    -p (Join-Path $InstallerDir "packages") `
    "$InstallerOut"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Installer created: $InstallerOut" -ForegroundColor Green
} else {
    Write-Host "binarycreator failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}
