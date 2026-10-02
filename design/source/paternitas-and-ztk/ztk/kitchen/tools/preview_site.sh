#!/usr/bin/env bash
# preview_site.sh
# Regenerates Zig autodocs then serves the full MkDocs site locally.
# Run from anywhere.

set -e

TOOLS_DIR=$(dirname "$(readlink -f "$0")")
KITCHEN_DIR=$(dirname "$TOOLS_DIR")

if ! command -v mkdocs >/dev/null 2>&1; then
    echo "Error: mkdocs not found in PATH"
    echo "Install: pip install mkdocs-material"
    exit 1
fi

bash "$TOOLS_DIR/docs_zig.sh"
bash "$TOOLS_DIR/gen_examples_docs.sh"
bash "$TOOLS_DIR/fix_md_lists.sh"
bash "$TOOLS_DIR/fix_md_hardbreaks.sh"

echo "--- Starting MkDocs site ---"
echo "Preview: http://localhost:8000"
echo "(Press Ctrl+C to stop)"
cd "$KITCHEN_DIR"
mkdocs serve -f mkdocs.yml
