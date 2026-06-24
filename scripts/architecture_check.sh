#!/usr/bin/env bash
# architecture_check.sh — enforces clean-architecture boundaries in lib/
# Fails with exit 1 if any violation is detected.
# Usage: bash scripts/architecture_check.sh
# Integrated in .github/workflows/ci.yml before flutter analyze.

set -euo pipefail

FAIL=0

# ── Rule 1: Presentation layer must not import data layer directly ────────────
echo "Checking: presentation → data imports..."
VIOLATIONS=$(grep -rn "package:beltech/.*data/" \
  lib/features/*/presentation/ \
  lib/presentation/ \
  2>/dev/null || true)

if [ -n "$VIOLATIONS" ]; then
  echo "❌ ARCHITECTURE VIOLATION: Presentation layer directly imports data layer:"
  echo "$VIOLATIONS"
  FAIL=1
fi

# ── Rule 2: No cross-feature data-layer imports ───────────────────────────────
# Allowed: lib/features/foo/*/... imports lib/features/foo/data/
# Forbidden: lib/features/foo/*/... imports lib/features/bar/data/
echo "Checking: cross-feature data imports..."
# Find every import of another feature's data layer
while IFS= read -r file; do
  # Extract the feature name from the importing file's path
  # e.g. lib/features/tasks/presentation/... → tasks
  feature=$(echo "$file" | sed -E 's|lib/features/([^/]+)/.*|\1|')
  # Find imports from OTHER features' data layers
  cross=$(grep -n "package:beltech/features/" "$file" 2>/dev/null \
    | grep "/data/" \
    | grep -v "features/$feature/data/" \
    || true)
  if [ -n "$cross" ]; then
    echo "❌ CROSS-FEATURE VIOLATION in $file:"
    echo "$cross"
    FAIL=1
  fi
done < <(find lib/features -name "*.dart" 2>/dev/null)

# ── Rule 3: Domain layer must not import Flutter widgets ─────────────────────
echo "Checking: domain layer has no Flutter widget imports..."
WIDGET_IN_DOMAIN=$(grep -rn "package:flutter/material\|package:flutter/widgets\|package:flutter/cupertino" \
  lib/features/*/domain/ \
  lib/domain/ \
  2>/dev/null || true)

if [ -n "$WIDGET_IN_DOMAIN" ]; then
  echo "❌ ARCHITECTURE VIOLATION: Domain layer imports Flutter widgets:"
  echo "$WIDGET_IN_DOMAIN"
  FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
  echo ""
  echo "Architecture check FAILED. Fix violations before merging."
  exit 1
fi

echo "✅ Architecture boundaries OK."
