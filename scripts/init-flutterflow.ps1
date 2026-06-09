# SpeakEasy — Initialize FlutterFlow AI workspace (run after saving API token)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$tokenFile = Join-Path $root ".flutterflow-token"

if (-not (Test-Path $tokenFile)) {
  Write-Host "Missing token file: $tokenFile"
  Write-Host "Paste your API token in that file (one line), then run again."
  exit 1
}

$token = (Get-Content $tokenFile -Raw).Trim()
if ($token.Length -lt 10) {
  Write-Host "Token file looks empty. Add your FlutterFlow API token."
  exit 1
}

$env:FLUTTERFLOW_API_TOKEN = $token
$env:Path = "C:\Users\a\AppData\Local\Pub\Cache\bin;C:\Users\a\Desktop\SpeakEasyReports\tools\flutter\bin;" + $env:Path

Set-Location $root
$workspace = Join-Path $root "flutterflow-ai"

if (-not (Test-Path $workspace)) {
  Write-Host "Creating FlutterFlow AI workspace..."
  New-Item -ItemType Directory -Force -Path $workspace | Out-Null
  Set-Location $workspace
  flutterflow ai init speakeasy-reports --yes 2>&1
} else {
  Write-Host "Workspace already exists at $workspace"
  Set-Location $workspace
}

Write-Host ""
Write-Host "Done. Next: flutterflow ai run / validate from workspace."