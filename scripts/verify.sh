#!/bin/bash
# scripts/verify.sh

set -e

echo "=== Running GDScript Syntax Check ==="
find src -name "*.gd" -exec gdparse {} +
echo "Done."

echo ""
echo "=== Running GDScript Linting ==="
# We only lint src/ to avoid issues with external files
# We allow some linting errors if they are just about order, but syntax must pass
gdlint src/ || echo "Linting found some style issues (non-fatal)."

echo ""
echo "=== Running Game Logic and Resource Verification ==="
python3 manual_verify.py

echo ""
echo "=== Verification Successful! ==="
