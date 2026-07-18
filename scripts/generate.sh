#!/usr/bin/env bash
# Regenerate Atlas.xcodeproj from project.yml.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen not found. Install with: brew install xcodegen" >&2
    exit 1
fi

rm -rf Atlas.xcodeproj
xcodegen generate
echo "Generated Atlas.xcodeproj"
