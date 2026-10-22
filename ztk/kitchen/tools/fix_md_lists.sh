#!/usr/bin/env bash
# Inserts a blank line before any Markdown list that directly follows plain
# text with no blank line — CommonMark/Python-Markdown treats such a list as
# a lazy paragraph continuation, collapsing every bullet into one run-on
# sentence instead of rendering a <ul>/<ol>. Auto-fixes every kitchen/docs/
# .md file in place; mechanical formatting only, no wording changes.
#
# Skips fenced code blocks (``` or ~~~) so `-`/`1.` lines inside example
# source or shell snippets are never touched. Does not insert a blank line
# when the previous line is itself a list item or blank — only when a list
# starts right after ordinary paragraph text.
set -euo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
docs_root="$repo_root/kitchen/docs"

fix_one() {
    local f="$1"
    awk '
        BEGIN { in_fence = 0; prev_is_list = 1; prev_is_blank = 1 }
        {
            line = $0
            is_fence = (line ~ /^[[:space:]]*(```|~~~)/)
            if (is_fence) {
                in_fence = !in_fence
                print line
                prev_is_list = 0
                prev_is_blank = 0
                next
            }
            if (in_fence) {
                print line
                next
            }
            is_blank = (line ~ /^[[:space:]]*$/)
            is_list = (line ~ /^[[:space:]]*([-*+][[:space:]]|[0-9]+[.)][[:space:]])/)
            if (is_list && !prev_is_list && !prev_is_blank) {
                print ""
            }
            print line
            prev_is_list = is_list
            prev_is_blank = is_blank
        }
    ' "$f" > "$f.tmp"
    if ! cmp -s "$f" "$f.tmp"; then
        mv "$f.tmp" "$f"
        echo "fixed: ${f#"$repo_root"/}"
    else
        rm -f "$f.tmp"
    fi
}

while IFS= read -r -d '' f; do
    fix_one "$f"
done < <(find "$docs_root" -name '*.md' -print0)

echo "Blank-line-before-list scan done."
