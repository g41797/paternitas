#!/bin/bash

set -e

cd "$(dirname "$0")/.."

date

zig build negative --summary all -Doptimize=Debug
zig build negative --summary all -Doptimize=ReleaseSafe
zig build negative --summary all -Doptimize=ReleaseFast
zig build negative --summary all -Doptimize=ReleaseSmall

date
