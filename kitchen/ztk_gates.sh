#!/usr/bin/env bash
# Runs the ztk gates, for the ZTK stages. Separate from kitchen/gates.sh.
#
# The gates live in ztk/kitchen/gates.sh, so they move with ztk. This script
# only calls them. The logs are in ztk/zig-out/.
#
# ztk depends on paternitas through `.path = ".."`. A paternitas fix during
# ZTK passes both scripts.
set -uo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
exec bash "$repo_root/ztk/kitchen/gates.sh"
