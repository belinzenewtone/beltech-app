#!/usr/bin/env bash
# build_shorebird.sh — builds Android and iOS release patches using Shorebird
# Prerequisites: shorebird_cli installed and logged in
# Usage: bash scripts/build_shorebird.sh [--patch] [--release]

set -euo pipefail

PATCH=false
RELEASE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --patch) PATCH=true; shift ;;
    --release) RELEASE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "========================================"
echo "BELTECH Shorebird Build Script"
echo "========================================"

if ! command -v shorebird &> /dev/null; then
  echo "❌ shorebird CLI not found. Install from https://docs.shorebird.dev"
  exit 1
fi

shorebird doctor || true

if [[ "$RELEASE" == true ]]; then
  echo "📦 Building Android release..."
  shorebird release android --flutter-version stable

  echo "📦 Building iOS release..."
  shorebird release ios --flutter-version stable
fi

if [[ "$PATCH" == true ]]; then
  echo "🔧 Patching Android..."
  shorebird patch android --flutter-version stable

  echo "🔧 Patching iOS..."
  shorebird patch ios --flutter-version stable
fi

if [[ "$RELEASE" == false && "$PATCH" == false ]]; then
  echo "Usage: bash scripts/build_shorebird.sh [--release | --patch]"
  echo "  --release  Create new release builds"
  echo "  --patch    Create OTA patches against latest release"
  exit 0
fi

echo "✅ Shorebird build complete."
