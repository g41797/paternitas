#!/usr/bin/env bash
# Checks the README's lines-of-code claim: "about N lines of Zig".
#
# The claim holds while count_src_loc.sh, rounded to the nearest hundred,
# equals N. Exit 0 when it holds, 1 when it does not or the claim is missing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README="$SCRIPT_DIR/../../README.md"

claim=$(grep -oE 'about [0-9]+ lines of Zig' "$README" | grep -oE '[0-9]+')
if [ -z "$claim" ]; then
    echo "README: no \"about N lines of Zig\" claim"
    exit 1
fi

loc=$(bash "$SCRIPT_DIR/count_src_loc.sh")
rounded=$(( (loc + 50) / 100 * 100 ))
echo "code $loc lines, rounded $rounded, README says about $claim"
if [ "$rounded" -ne "$claim" ]; then
    echo "README claim is wrong: write about $rounded"
    exit 1
fi
