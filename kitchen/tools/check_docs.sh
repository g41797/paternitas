#!/usr/bin/env bash
# Gate for paternitas' documents and code. It comes from next/ztk's
# check_next_docs.sh.
#
# Two checks:
#
#   1. Dead cross-references, in both syntaxes — [text](target.md) and
#      `target.md`.
#   2. Banned and AI-sh words, from design/rules-NNN.md Part 4.
#
# Exit 0 when clean, 1 on any hit. Read-only — reports, never edits.
#
# Exempt from both checks:
#   - design/STATUS-LOG.md and design/backup/ — they record what is gone.
#   - design/paternitas-001.md — kept untouched, by the owner's ruling.
# Exempt from check 2 only:
#   - design/rules-NNN.md — it has to name every banned word. Scan it by hand.
#
# A reference into ztk is written from ZTK/ or NEXT/, as in
# design/paternitas-design-NNN.md. It is checked only where the ztk repo is on
# disk; elsewhere it is counted and skipped.
set -uo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
ztk_root="$(realpath -m "${ZTK_ROOT:-$repo_root/../matryoshka-ztk}")"
next_root="$ztk_root/design/secondary/lang/port/3tk-to-ztk/next"

hits=0
skipped=0

report() {
    hits=$((hits + 1))
    printf '%s\n' "$1"
}

# The documents: design/, the README, and the hand-written site pages.
docs() {
    {
        find "$repo_root/design" -maxdepth 1 -name '*.md' \
            -not -name 'STATUS-LOG.md' -not -name 'paternitas-001.md'
        find "$repo_root" -maxdepth 1 -name '*.md'
        find "$repo_root/kitchen/docs" -maxdepth 1 -name '*.md' 2>/dev/null
    } | sort
}

# 0 when the target exists, 1 when it does not, 2 when it cannot be checked.
resolve() {
    local from_dir="$1" target="$2" c
    case "$target" in
        ZTK/*|NEXT/*)
            [ -d "$ztk_root" ] || return 2
            target="${target/#ZTK/$ztk_root}"
            target="${target/#NEXT/$next_root}"
            [ -e "$target" ] && return 0
            return 1 ;;
        /*)
            [ -e "$target" ] && return 0
            case "$target" in "$ztk_root"/*) [ -d "$ztk_root" ] || return 2 ;; esac
            return 1 ;;
    esac
    for c in "$from_dir/$target" "$repo_root/$target" "$repo_root/design/$target"; do
        [ -e "$c" ] && return 0
    done
    return 1
}

check_ref() {
    local kind="$1" rel="$2" dir="$3" t="$4" rc
    resolve "$dir" "$t"
    rc=$?
    case "$rc" in
        1) report "$kind $rel -> $t" ;;
        2) skipped=$((skipped + 1)) ;;
    esac
}

echo "== 1. dead cross-references =="

body="$(mktemp)"
trap 'rm -f "$body"' EXIT

while IFS= read -r f; do
    rel="${f#$repo_root/}"
    dir="$(dirname "$f")"

    # A changelog row names the document it replaced. That name is the point of
    # the row, so those lines are not scanned.
    grep -vE '^\| *[0-9]{3} *\|' "$f" > "$body"

    # [text](target.md) and [text](target.md#anchor). A process substitution,
    # not a pipe: report increments a counter, and a pipe would run it in a
    # subshell where the increment is lost.
    while IFS= read -r t; do
        case "$t" in http*) continue ;; esac
        check_ref "DEAD LINK " "$rel" "$dir" "$t"
    done < <(grep -oE '\]\([^)]+\.md(#[^)]*)?\)' "$body" \
        | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | sort -u)

    # `target.md` written as inline code. A name holding NNN is the project's
    # placeholder for "whatever version is current", not a reference.
    while IFS= read -r t; do
        case "$t" in *NNN*) continue ;; esac
        check_ref "DEAD REF  " "$rel" "$dir" "$t"
    done < <(grep -oE '`[A-Za-z0-9._/-]+\.md`' "$body" | tr -d '`' | sort -u)
done < <(docs)

if [ "$skipped" -gt 0 ]; then
    echo "  $skipped ztk reference(s) not checked: no ztk repo at $ztk_root"
fi

echo "== 2. banned and AI-sh words =="

# `.unlock(` is a std method name that code cannot rename. Only the method
# call is skipped: the word on its own in prose is still a hit.
banned_skip='.unlock('
banned=(drain DLL seam seamless sweep settle settled underneath hatch parked
        lifecycle ledger ownership robust seamlessly comprehensive
        leverage efficient powerful facilitate utilize ensure performant
        ergonomic idiomatic streamline orchestrate sophisticated intuitive
        scalable unlock empower harness deliver idempotent paradigm mindset
        gained wire wired wires wiring)

for w in "${banned[@]}"; do
    while IFS= read -r line; do
        report "BANNED     $w  $line"
    done < <(grep -rniw --include='*.md' --include='*.zig' \
        --exclude='STATUS-LOG.md' --exclude='paternitas-001.md' \
        --exclude='rules-[0-9][0-9][0-9].md' \
        --exclude-dir=backup --exclude-dir=.zig-cache --exclude-dir=zig-out \
        --exclude-dir=.git --exclude-dir=.idea --exclude-dir=apidocs \
        -- "$w" "$repo_root/design" "$repo_root/src" "$repo_root/tests" \
                "$repo_root/examples" "$repo_root/kitchen" "$repo_root/README.md" \
                2>/dev/null \
        | grep -vF "$banned_skip" | grep -v "^$repo_root/kitchen/docs/examples/" \
        | sed "s|^$repo_root/||")
done

echo
if [ "$hits" -eq 0 ]; then
    echo "clean"
    exit 0
fi

echo "$hits hit(s)"
exit 1
