#Requires -Version 7.0
# build_shorebird.ps1 — builds Android and iOS release patches using Shorebird
# Prerequisites: shorebird_cli installed and logged in
# Usage: .\scripts\build_shorebird.ps1 [-Patch] [-Release]

param(
    [switch]$Patch,
    [switch]$Release
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BELTECH Shorebird Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$shorebird = Get-Command shorebird -ErrorAction SilentlyContinue
if (-not $shorebird) {
    Write-Host "❌ shorebird CLI not found. Install from https://docs.shorebird.dev" -ForegroundColor Red
    exit 1
}

& shorebird doctor

if ($Release) {
    Write-Host "📦 Building Android release..." -ForegroundColor Green
    & shorebird release android --flutter-version stable

    Write-Host "📦 Building iOS release..." -ForegroundColor Green
    & shorebird release ios --flutter-version stable
}

if ($Patch) {
    Write-Host "🔧 Patching Android..." -ForegroundColor Yellow
    & shorebird patch android --flutter-version stable

    Write-Host "🔧 Patching iOS..." -ForegroundColor Yellow
    & shorebird patch ios --flutter-version stable
}

if (-not $Release -and -not $Patch) {
    Write-Host "Usage: .\scripts\build_shorebird.ps1 [-Release] [-Patch]"
    Write-Host "  -Release  Create new release builds"
    Write-Host "  -Patch    Create OTA patches against latest release"
    exit 0
}

Write-Host "✅ Shorebird build complete." -ForegroundColor Green
