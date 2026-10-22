#!/usr/bin/env bash
# build_site.sh
# Generates Zig autodocs then builds the full MkDocs static site.
# Output goes to docs/ (repo root). Run from anywhere.

set -e

TOOLS_DIR=$(dirname "$(readlink -f "$0")")
KITCHEN_DIR=$(dirname "$TOOLS_DIR")

if ! command -v mkdocs >/dev/null 2>&1; then
    echo "Error: mkdocs not found in PATH"
    echo "Install: pip install mkdocs-material"
    exit 1
fi

echo "--- Generating API docs ---"
bash "$TOOLS_DIR/docs_zig.sh"

echo "--- Generating examples catalog ---"
bash "$TOOLS_DIR/gen_examples_docs.sh"

echo "--- Fixing blank-line-before-list ---"
bash "$TOOLS_DIR/fix_md_lists.sh"

echo "--- Fixing staccato hard-breaks ---"
bash "$TOOLS_DIR/fix_md_hardbreaks.sh"

echo "--- Building MkDocs site ---"
cd "$KITCHEN_DIR"
mkdocs build -f mkdocs.yml

echo "--- Removing unused Material default favicon ---"
rm -f "$(dirname "$KITCHEN_DIR")/docs/assets/images/favicon.png"

echo "--- Done ---"
echo "Output: $(dirname "$KITCHEN_DIR")/docs/"
