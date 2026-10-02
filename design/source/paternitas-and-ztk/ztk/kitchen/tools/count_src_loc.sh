#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../../src"

python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from src_loc import count_src_loc
print(count_src_loc('$SRC_DIR'))
"
