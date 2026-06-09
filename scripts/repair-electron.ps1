$ErrorActionPreference = 'Stop'

$desktop = Join-Path $PSScriptRoot '..\desktop'
$electronDir = Join-Path $desktop 'node_modules\electron'
$electronExe = Join-Path $electronDir 'dist\electron.exe'
$pathTxt = Join-Path $electronDir 'path.txt'

if (Test-Path $electronExe) {
  if (-not (Test-Path $pathTxt)) {
    Set-Content -Path $pathTxt -Value 'electron.exe' -NoNewline
  }
  exit 0
}

Write-Host 'Repairing Electron runtime (one-time download)...'

Push-Location $desktop
try {
  if (-not (Test-Path (Join-Path $desktop 'node_modules\electron\install.js'))) {
    npm install
  }

  $env:force_no_cache = 'true'
  node (Join-Path $electronDir 'install.js')
  if (-not (Test-Path $electronExe)) {
    $cacheRoot = Join-Path $env:LOCALAPPDATA 'electron\Cache'
    $zip = Get-ChildItem -Path $cacheRoot -Recurse -Filter 'electron-v*-win32-x64.zip' -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
    if (-not $zip) { throw 'Electron download cache not found.' }

    $dist = Join-Path $electronDir 'dist'
    if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
    Expand-Archive -Path $zip.FullName -DestinationPath $dist -Force
    Set-Content -Path $pathTxt -Value 'electron.exe' -NoNewline
  }
}
finally {
  Pop-Location
}

if (-not (Test-Path $electronExe)) {
  throw 'Electron repair failed.'
}

Write-Host 'Electron repair complete.'