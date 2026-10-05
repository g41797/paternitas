#!/bin/bash

set -e

cd "$(dirname "$0")/.."

date

zig build --summary all

zig build test -freference-trace --summary all -Doptimize=Debug
zig build test -freference-trace --summary all -Doptimize=ReleaseSafe
zig build test -freference-trace --summary all -Doptimize=ReleaseFast
zig build test -freference-trace --summary all -Doptimize=ReleaseSmall

# The same, with Zig's own backend instead of LLVM.
zig build test -freference-trace --summary all -Doptimize=Debug -Duse_llvm=false
zig build test -freference-trace --summary all -Doptimize=ReleaseSafe -Duse_llvm=false
zig build test -freference-trace --summary all -Doptimize=ReleaseFast -Duse_llvm=false
zig build test -freference-trace --summary all -Doptimize=ReleaseSmall -Duse_llvm=false

date
