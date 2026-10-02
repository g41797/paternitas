#!/usr/bin/env bash
# Fixes Markdown soft-break staccato lines: CommonMark collapses two lines
# separated only by a single newline into one rendered line (soft break ->
# space), losing the intended two-line effect unless the first line ends in
# two-or-more trailing spaces (hard break) or the lines are blank-line-
# separated paragraphs. Appends two trailing spaces to any plain-text line
# immediately followed by another non-blank plain-text line. Auto-fixes
# every .md file in the repo in place; mechanical formatting only, no
# wording changes. Idempotent — safe to re-run.
#
# Skips fenced code blocks (``` or ~~~). Does not touch list items,
# headings, blockquotes, table rows, or link/image reference lines (badges,
# shields, footnote-style refs) — a following non-blank line after these is
# normal Markdown syntax, not a soft-break hazard. Does not touch lines that
# are already blank or already end in two-or-more trailing spaces.
set -euo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"

fix_one() {
    local f="$1"
    awk '
        function is_special(line) {
            return (line ~ /^[[:space:]]*([-*+][[:space:]]|[0-9]+[.)][[:space:]]|#|>|\||\[)/)
        }
        BEGIN { in_fence = 0 }
        {
            lines[NR] = $0
        }
        END {
            n = NR
            for (i = 1; i <= n; i++) {
                line = lines[i]
                is_fence_line = (line ~ /^[[:space:]]*(```|~~~)/)
                if (is_fence_line) {
                    in_fence = !in_fence
                    print line
                    continue
                }
                if (in_fence) {
                    print line
                    continue
                }
                is_blank = (line ~ /^[[:space:]]*$/)
                next_line = (i < n) ? lines[i+1] : ""
                next_is_blank = (next_line ~ /^[[:space:]]*$/)
                has_hard_break = (line ~ /  $/)
                if (!is_blank && !next_is_blank && i < n && !has_hard_break && !is_special(line) && !is_special(next_line)) {
                    print line "  "
                } else {
                    print line
                }
            }
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
done < <(find "$repo_root" -name '*.md' -print0)

echo "Hard-break scan done."
