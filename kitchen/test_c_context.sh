#!/bin/bash
# Runs the C-callback scenario in design/c-test/: four modes, both backends.
# Not one of the six gates. Output: zig-out/c_context.log.

set -e

cd "$(dirname "$0")/.."

mkdir -p zig-out
log=zig-out/c_context.log
: > "$log"

for backend in -fllvm -fno-llvm; do
    for mode in Debug ReleaseSafe ReleaseFast ReleaseSmall; do
        echo "== $mode $backend" >> "$log"
        zig test -O "$mode" "$backend" --dep paternitas \
            -Mroot=design/c-test/c_context_test.zig \
            -Mpaternitas=src/paternitas.zig >> "$log" 2>&1
    done
done

echo "c_context: 8 runs pass  $log"
