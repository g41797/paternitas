#!/usr/bin/env bash
# Runs the ztk gates, for the ZTK stages. Separate from kitchen/gates.sh.
#
# ztk lives in ztk/ and depends on paternitas through `.path = ".."`. A
# paternitas fix during ZTK passes both scripts.
#
# Each gate writes its full output to a fixed log in zig-out/. The screen gets
# one line per gate. Pass or fail comes from the exit code, never from the log
# text.
#
# Stops at the first failure. Exit 0 when all three pass.
set -uo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "$repo_root"
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

for name in z1_test z2_negative z3_fmt; do
    log="$repo_root/zig-out/ztk_$name.log"
    if (cd ztk && "$name") > "$log" 2>&1; then
        echo "PASS  $name  zig-out/ztk_$name.log"
    else
        echo "FAIL  $name  zig-out/ztk_$name.log"
        exit 1
    fi
done

echo "all three ztk gates pass"
