$ErrorActionPreference = 'Stop'
$bundleId = 'com.speakeasy.speakeasyReports'
$repoRoot = Split-Path $PSScriptRoot -Parent
$mobile = Join-Path $repoRoot 'mobile'
$checks = @(
    @{ Path = Join-Path $mobile 'ios\Runner.xcodeproj\project.pbxproj'; Pattern = "PRODUCT_BUNDLE_IDENTIFIER = $bundleId;" },
    @{ Path = Join-Path $mobile 'ios\Runner\Info.plist'; Pattern = "<string>$bundleId</string>" },
    @{ Path = Join-Path $mobile 'app.json'; Pattern = "`"bundleIdentifier`": `"$bundleId`"" },
    @{ Path = Join-Path $mobile 'android\app\build.gradle.kts'; Pattern = "applicationId = `"$bundleId`"" }
)

$failed = $false
Write-Host "Verifying bundle ID: $bundleId"
foreach ($check in $checks) {
    if (-not (Test-Path $check.Path)) {
        Write-Host "MISSING: $($check.Path)" -ForegroundColor Red
        $failed = $true
        continue
    }
    $text = Get-Content $check.Path -Raw
    if ($text -match [regex]::Escape($check.Pattern)) {
        Write-Host "OK: $($check.Path)"
    } else {
        Write-Host "FAIL: $($check.Path)" -ForegroundColor Red
        $failed = $true
    }
}

if ($failed) {
    exit 1
}

Write-Host 'All bundle ID checks passed.' -ForegroundColor Green