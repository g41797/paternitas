#!/usr/bin/env bash
# Runs the five gates of rules-NNN.md Part 0, in order.
#
# Each gate writes its full output to a fixed log in zig-out/. The screen gets
# one line per gate. Pass or fail comes from the exit code, never from the log
# text: a passing test's log output shows under Zig's "failed command:" line.
#
# Stops at the first failure. Exit 0 when all five pass.
set -uo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "$repo_root"
mkdir -p zig-out

gates=(
    "g1_debug|bash kitchen/build_and_test_debug.sh"
    "g2_all|bash kitchen/build_and_test_all.sh"
    "g3_cross|bash kitchen/build_cross_debug.sh"
    "g4_docs|bash kitchen/tools/check_docs.sh"
    "g5_fmt|zig fmt --check src tests examples build.zig"
)

for gate in "${gates[@]}"; do
    name="${gate%%|*}"
    cmd="${gate#*|}"
    log="zig-out/$name.log"
    if bash -c "$cmd" > "$log" 2>&1; then
        echo "PASS  $name  $log"
    else
        echo "FAIL  $name  $log"
        exit 1
    fi
done

echo "all five gates pass"
