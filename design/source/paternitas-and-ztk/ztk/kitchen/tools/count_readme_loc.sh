#!/usr/bin/env bash
#
# README lines, computed on demand. A line counts when it carries text: not
# blank, not a `---` separator rule.
#
# Everything else counts, code fences and diagrams included -- they are the
# page as a reader meets it.
#
# Usage:  ./count_readme_loc.sh [file]   file defaults to README.md in this
#                                        script's own directory's parent
#
# Prints the number and nothing else, so `$(...)` consumes it without
# parsing. Exit 2 on a missing file.

set -u

FILE=${1:-}
[ -n "$FILE" ] || FILE=$(cd "$(dirname "$0")" && pwd)/../../README.md
[ -f "$FILE" ] || { echo "no such file: $FILE" >&2; exit 2; }

awk '
    { line = $0 }
    line ~ /^[[:space:]]*$/      { next }   # blank
    line ~ /^[[:space:]]*-{3,}[[:space:]]*$/ { next }   # --- separator
    { n++ }
    END { print n + 0 }
' "$FILE"
