#!/usr/bin/env bash
# Runs the ztk gates. Works from any directory: it moves to the ztk root
# first, the folder above this script's kitchen/.
#
# Each gate writes its full output to a fixed log in zig-out/. The screen gets
# one line per gate. Pass or fail comes from the exit code, never from the log
# text.
#
# Stops at the first failure. Exit 0 when all four pass.
#
# z5, the rule 2 check, is reserved. It is not approved yet.
set -uo pipefail

ztk_root="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "$ztk_root"
mkdir -p zig-out

modes=(Debug ReleaseSafe ReleaseFast ReleaseSmall)

z1_test() {
    for m in "${modes[@]}"; do
        echo "== test $m"
        zig build test -freference-trace --summary all "-Doptimize=$m" || return 1
    done
}

z2_negative() {
    for m in "${modes[@]}"; do
        echo "== negative $m"
        zig build negative --summary all "-Doptimize=$m" || return 1
    done
}

z3_fmt() {
    zig fmt --check src tests examples negative build.zig
}

z4_readme() {
    bash kitchen/tools/check_readme_claim.sh
}

for name in z1_test z2_negative z3_fmt z4_readme; do
    log="$ztk_root/zig-out/$name.log"
    if "$name" > "$log" 2>&1; then
        echo "PASS  $name  zig-out/$name.log"
    else
        echo "FAIL  $name  zig-out/$name.log"
        exit 1
    fi
done

echo "all four ztk gates pass"
