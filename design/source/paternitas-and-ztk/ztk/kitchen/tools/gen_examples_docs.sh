#!/usr/bin/env bash
# Mirrors examples/ and stories/ into kitchen/docs/examples/ as .md pages.
#
# For every *.zig file except barrel files (a file named after its own
# directory, or examples.zig/stories.zig), writes a .md at the matching
# relative path holding: title, `## Description`, `## Diagram` (when
# present), `## Source` — the full source fenced as zig, with the SPDX
# header and the leading //! description/diagram block stripped from the
# embedded snippet only (both already shown above it as rendered markdown;
# the source file itself keeps them). Regenerated on every run — never
# hand-edited.
set -euo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
out_root="$repo_root/kitchen/docs/examples"

# Only clear the mirrored per-example subdirs, not the whole out_root — it
# also holds hand-authored catalog/group pages (index.md, polynode.md,
# mailbox.md, pool.md, io.md, flow.md) that this script must not touch.
rm -rf "$out_root/layer1" "$out_root/layer2" "$out_root/layer3" "$out_root/layer4" \
       "$out_root/parents" "$out_root/hooks" "$out_root/helpers" "$out_root/stories"
mkdir -p "$out_root"

is_barrel() {
    # A barrel file only re-exports sibling modules: every non-blank,
    # non-comment line is `pub const X = @import(...);`.
    local src="$1"
    ! grep -vEq '^\s*(//.*)?$|^pub const [A-Za-z_][A-Za-z0-9_]* = @import\("[^"]+"\);\s*(//.*)?$' "$src"
}

gen_one() {
    local src="$1" out="$2"
    mkdir -p "$(dirname "$out")"

    local desc
    desc="$(awk '
        /^\/\/!/ { started=1; sub(/^\/\/!/,""); sub(/^ /,""); print; next }
        started { exit }
    ' "$src")"

    local title
    title="$(printf '%s\n' "$desc" | sed -n '1{s/[.]*$//;p;q}')"
    [ -n "$title" ] || title="$(basename "$src" .zig)"

    # Split desc into prose (before the first fenced ``` line, trailing
    # blank lines trimmed) and diagram (the fenced block's contents) —
    # rendered under separate headings below.
    local prose
    prose="$(printf '%s\n' "$desc" | awk '/^```$/{exit} {print}' | awk '
        { a[NR] = $0 }
        END { n = NR; while (n > 0 && a[n] == "") n--; for (i = 1; i <= n; i++) print a[i] }
    ')"
    local diagram
    diagram="$(printf '%s\n' "$desc" | awk 'BEGIN{state=0} /^```$/{state++; next} state==1{print}')"

    {
        printf '# %s\n\n' "$title"
        if [ -n "$prose" ]; then
            printf '## Description\n\n%s\n\n' "$prose"
        fi
        if [ -n "$diagram" ]; then
            printf '## Diagram\n\n```\n%s\n```\n\n' "$diagram"
        fi
        printf '## Source\n\n```zig\n'
        # Drop the SPDX header, then the leading blank/`//!` run (the
        # description + diagram, already rendered above as markdown) from
        # the embedded snippet. Source file itself is untouched.
        sed -e '/^\/\/ SPDX-FileCopyrightText:/d' -e '/^\/\/ SPDX-License-Identifier:/d' "$src" \
            | awk '
                !done && ($0 == "" || $0 ~ /^\/\/!/) { next }
                { done=1; print }
            '
        printf '```\n'
    } > "$out"
}

mirror_root() {
    local src_root="$1" dest_prefix="$2"
    [ -d "$repo_root/$src_root" ] || return 0
    while IFS= read -r -d '' f; do
        rel="${f#"$repo_root/$src_root/"}"
        is_barrel "$f" && continue
        out="$out_root${dest_prefix:+/$dest_prefix}/${rel%.zig}.md"
        gen_one "$f" "$out"
    done < <(find "$repo_root/$src_root" -name '*.zig' -print0)
}

mirror_root "examples" ""
mirror_root "stories" "stories"

echo "Generated examples catalog under kitchen/docs/examples/"
