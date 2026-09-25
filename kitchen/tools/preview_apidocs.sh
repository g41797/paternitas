#!/usr/bin/env bash
# preview_apidocs.sh
# Regenerates Zig autodocs and serves the kitchen/docs folder, apidocs included,
# locally for visual inspection. Run from anywhere.

set -e

TOOLS_DIR=$(dirname "$(readlink -f "$0")")
KITCHEN_DIR=$(dirname "$TOOLS_DIR")

bash "$TOOLS_DIR/docs_zig.sh"

echo "--- Starting local server ---"
echo "Preview: http://localhost:8000"
echo "(Press Ctrl+C to stop)"
cd "$KITCHEN_DIR/docs"
python3 -m http.server 8000
