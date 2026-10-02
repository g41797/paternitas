#!/usr/bin/env bash
# Gate for the rewritten tree — its documents and its code.
#
# The old tree's kitchen/tools/check_design.sh cannot cover this tree:
# check_design.sh line 103 prunes design/secondary/lang outright, so every file
# here is invisible to it. That prune is right for the frozen c3 material and
# wrong for a tree being written, so this is the replacement.
#
# Three checks:
#
#   1. Dead cross-references, in both syntaxes — [text](target.md) and
#      `target.md`. The same defect class check_design.sh check 1 catches.
#   2. Retired vocabulary. The words the backport ruled out must not appear in
#      the new tree at all. This is the inverse of check_design.sh's glossary
#      check, which defends the OLD words in the old tree.
#   3. Banned and AI-sh words, from rules-050.md Part 5.
#
# Exit 0 when clean, 1 on any hit. Read-only — reports, never edits.
#
# next-log.md and backup/ are exempt from 2 and 3: the log is an append-only
# narrative and backup/ is superseded copies. Both legitimately name what is
# gone. This script is scanned against its own lists, for the reason Part 5
# gives: the file that names a word to ban it is the one most likely to repeat
# it.
set -uo pipefail

next_root="$(cd "$(dirname "$(readlink -f "$0")")/../../.." && pwd)"
tree="$next_root/ztk"
repo_root="$(cd "$next_root/../../../../../.." && pwd)"

hits=0

report() {
    hits=$((hits + 1))
    printf '%s\n' "$1"
}

# The documents of this tree: the trio in next/, and the project's own
# documents in ztk/design/, which travel with the code when it is copied up.
#
# next-log.md is left out: a past entry names the document version that was
# current when it was written, and that name is the fact the entry records.
# check_design.sh leaves STATUS-LOG.md out of its own check 1 for the same
# reason.
docs() {
    {
        find "$next_root" -maxdepth 1 -name '*.md' -not -name 'next-log.md'
        find "$tree/design" -maxdepth 1 -name '*.md' 2>/dev/null
    } | sort
}

# Every file a reference may resolve to. The last two candidates matter: this
# tree's documents legitimately name the old tree's files, by a path written
# from the repository root, and name their own files by a path written from the
# backport folder.
resolve() {
    local from_dir="$1" target="$2" c
    for c in "$from_dir/$target" "$next_root/$target" "$tree/$target" \
             "$tree/design/$target" "$next_root/../$target" \
             "$repo_root/$target" "$repo_root/design/$target"; do
        [ -e "$c" ] && return 0
    done
    return 1
}

echo "== 1. dead cross-references =="

while IFS= read -r f; do
    rel="${f#$next_root/}"
    dir="$(dirname "$f")"

    # A changelog row names the document it replaced. That name is the point of
    # the row, so those lines are not scanned.
    grep -vE '^\| *[0-9]{3} *\|' "$f" > "/tmp/.cn_body.$$"

    # [text](target.md) and [text](target.md#anchor). A process substitution,
    # not a pipe: report increments a counter, and a pipe would run it in a
    # subshell where the increment is lost.
    while IFS= read -r t; do
        case "$t" in http*|/*) continue ;; esac
        resolve "$dir" "$t" || report "DEAD LINK  $rel -> $t"
    done < <(grep -oE '\]\([^)]+\.md(#[^)]*)?\)' "/tmp/.cn_body.$$" \
        | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | sort -u)

    # `target.md` written as inline code. A name holding NNN is the project's
    # placeholder for "whatever version is current", not a reference.
    while IFS= read -r t; do
        case "$t" in *NNN*) continue ;; esac
        resolve "$dir" "$t" || report "DEAD REF   $rel -> $t"
    done < <(grep -oE '`[A-Za-z0-9._/-]+\.md`' "/tmp/.cn_body.$$" \
        | tr -d '`' | sort -u)

    rm -f "/tmp/.cn_body.$$"
done < <(docs)

echo "== 2. retired vocabulary =="

# Ruled out by the backport. Item becomes Outer, PolyNode becomes Inner, and a
# per-type static tag becomes a descriptor, so PolyTag has no successor. The
# word "parent" points opposite ways in Zig and C3, which is why it is banned
# rather than replaced.
#
# A line that says what a retired word became has to name it. Such a line
# carries the marker `retired-ok` and is skipped, the way check_design.sh skips
# a changelog row for the same reason.
retired=(PolyNode PolyTag is_it_you 'parent')

for w in "${retired[@]}"; do
    while IFS= read -r line; do
        report "RETIRED    $w  $line"
    done < <(grep -rnw --include='*.md' --include='*.zig' \
        --exclude='next-log.md' --exclude-dir=backup \
        --exclude='check_next_docs.sh' \
        -- "$w" "$next_root" 2>/dev/null \
        | grep -v 'retired-ok' | sed "s|^$next_root/||")
done

echo "== 3. banned and AI-sh words =="

# rules-050.md Part 5. @fieldParentPtr is a Zig builtin and is not a hit for
# "parent"; check 2 uses -w, so it does not match inside the builtin's name.
#
# `.unlock(` is the same kind of exception, and it arrived with MBOX. The
# banned word is the AI-ish verb — "unlock the potential of" — and
# `std.Io.Mutex.unlock` is a std method name that a mailbox cannot avoid
# calling and cannot rename. Only the method call is skipped: the word on its
# own in prose is still a hit, which is what the list is for.
banned_skip='.unlock('
banned=(drain DLL seam seamless sweep settle settled underneath hatch parked
        lifecycle ledger MayItem ownership robust seamlessly comprehensive
        leverage efficient powerful facilitate utilize ensure performant
        ergonomic idiomatic streamline orchestrate sophisticated intuitive
        scalable unlock empower harness deliver idempotent paradigm mindset
        gained wire wired wires wiring)

for w in "${banned[@]}"; do
    while IFS= read -r line; do
        report "BANNED     $w  $line"
    done < <(grep -rniw --include='*.md' --include='*.zig' \
        --exclude='next-log.md' --exclude-dir=backup \
        --exclude='check_next_docs.sh' \
        -- "$w" "$next_root" 2>/dev/null \
        | grep -vF "$banned_skip" | sed "s|^$next_root/||")
done

echo "== 4. the staging plan keeps up with the log =="

# The rule: next-status.md is updated in place, next-log.md is appended to, and
# the staging plan is VERSIONED — a new number per completed stage, the old one
# moved to backup/.
#
# This check exists because SPEC broke that rule by editing 001 in place, and
# nothing noticed: the version number simply stopped moving while stages
# accumulated. The text SETUP wrote is not recoverable.
#
# The invariant: the plan's version is at least the number of stages the log
# records. Greater is fine — a stage may write more than one version. Less means
# a stage changed the plan without versioning it, or closed without touching it.
plans=("$next_root"/next-staging-plan-[0-9][0-9][0-9].md)

if [ ! -e "${plans[0]}" ]; then
    report "NO PLAN    no next-staging-plan-NNN.md in $next_root"
elif [ "${#plans[@]}" -gt 1 ]; then
    report "TWO PLANS  only one staging plan is live; the rest belong in backup/"
    printf '           %s\n' "${plans[@]#$next_root/}"
else
    plan="${plans[0]}"
    version="$(basename "$plan" .md)"
    version="${version##*-}"
    version="$((10#$version))"

    # A stage entry in the log: "## <date> — <name>".
    stages="$(grep -cE '^## [0-9]{4}-[0-9]{2}-[0-9]{2} — ' "$next_root/next-log.md" 2>/dev/null || echo 0)"

    if [ "$version" -lt "$stages" ]; then
        report "STALE PLAN $(basename "$plan") is version $version, and the log records $stages completed stage(s)."
        report "           A stage changed the plan without writing a new version. See rule: the plan is versioned."
    else
        echo "  plan version $version, $stages stage(s) in the log"
    fi
fi

echo
if [ "$hits" -eq 0 ]; then
    echo "clean"
    exit 0
fi

echo "$hits hit(s)"
exit 1
