#!/usr/bin/env pwsh
# secret_scan.ps1 — Windows equivalent of secret_scan.sh.
# Usage: pwsh scripts/secret_scan.ps1
# The CI pipeline uses secret_scan.sh on Linux runners; run this locally on
# Windows dev machines before pushing.

$ErrorActionPreference = 'Stop'

$patterns = @(
    'supabase_url\s*=\s*[''"]https',
    'supabase_anon_key\s*=\s*[''"]ey',
    'SUPABASE_URL\s*=\s*[''"]https',
    'SUPABASE_ANON_KEY\s*=\s*[''"]ey',
    'openai_api_key',
    'sk-[a-zA-Z0-9]{48}',
    'AIzaSy[0-9A-Za-z_-]{33}',
    'AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}',
    'AKIA[0-9A-Z]{16}',
    'sk_live_[0-9a-zA-Z]{24}',
    'pk_live_[0-9a-zA-Z]{24}',
    'sentry\.io/[0-9]',
)

$searchPaths = @('lib', 'test')
$found = $false

foreach ($pattern in $patterns) {
    foreach ($searchPath in $searchPaths) {
        if (-not (Test-Path $searchPath)) { continue }
        $hits = Get-ChildItem -Path $searchPath -Recurse -Filter '*.dart' |
            Select-String -Pattern $pattern -CaseSensitive:$false
        if ($hits) {
            Write-Host "❌ SECRET DETECTED — pattern: $pattern" -ForegroundColor Red
            $hits | ForEach-Object { Write-Host "   $_" }
            Write-Host ''
            $found = $true
        }
    }
}

if ($found) {
    Write-Host 'Secret scan FAILED. Remove hardcoded secrets before committing.' -ForegroundColor Red
    exit 1
}

Write-Host '✅ Secret scan passed — no hardcoded secrets found.' -ForegroundColor Green
