#!/usr/bin/env bash
# docs_zig.sh: Regenerate the Zig autodoc artifacts (apidocs).
# Run from anywhere.

set -e

TOOLS_DIR=$(dirname "$(readlink -f "$0")")
KITCHEN_DIR=$(dirname "$TOOLS_DIR")
ROOT_DIR=$(dirname "$KITCHEN_DIR")

cd "$ROOT_DIR"
echo "Regenerating Zig autodocs..."
zig build docs
echo "Autodocs regenerated."
