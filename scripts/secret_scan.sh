#!/usr/bin/env bash
# secret_scan.sh — fails with exit 1 if hardcoded secrets are found in lib/ or test/
# Usage: bash scripts/secret_scan.sh
# Integrated in .github/workflows/ci.yml as the "secret-scan" job.

set -euo pipefail

PATTERNS=(
  # Supabase URL / anon key literals
  "supabase_url\s*=\s*['\"]https"
  "supabase_anon_key\s*=\s*['\"]ey"
  "SUPABASE_URL\s*=\s*['\"]https"
  "SUPABASE_ANON_KEY\s*=\s*['\"]ey"
  # OpenAI / GPT key
  "openai_api_key"
  "sk-[a-zA-Z0-9]{48}"
  # Google API key
  "AIzaSy[0-9A-Za-z_-]{33}"
  # Firebase server key
  "AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}"
  # AWS credentials
  "AKIA[0-9A-Z]{16}"
  # Stripe keys
  "sk_live_[0-9a-zA-Z]{24}"
  "pk_live_[0-9a-zA-Z]{24}"
  # Sentry DSN (only flag if hardcoded, not via --dart-define)
  "sentry\.io/[0-9]"
)

FOUND=0

for pattern in "${PATTERNS[@]}"; do
  MATCHES=$(grep -rniE "$pattern" lib/ test/ 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    echo "❌ SECRET DETECTED — pattern: $pattern"
    echo "$MATCHES"
    echo ""
    FOUND=1
  fi
done

if [ "$FOUND" -eq 1 ]; then
  echo "Secret scan FAILED. Remove hardcoded secrets before committing."
  exit 1
fi

echo "✅ Secret scan passed — no hardcoded secrets found."
