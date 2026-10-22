"""Shared LOC-counting logic for src/*.zig. See design/src-loc-counter-001.md."""

import glob
import os

_IMPORT_RE_MARKER = "@import("


def _is_import_line(line: str) -> bool:
    if _IMPORT_RE_MARKER not in line:
        return False
    stripped = line.strip()
    return stripped.startswith(("const", "pub const", "var", "pub var", _IMPORT_RE_MARKER))


def _counts(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    if stripped.startswith("//"):
        return False
    if _is_import_line(stripped):
        return False
    return True


def count_file_loc(filepath: str) -> int:
    with open(filepath, "r", encoding="utf-8") as f:
        return sum(1 for line in f if _counts(line))


def count_src_loc(src_dir: str) -> int:
    total = 0
    for filepath in glob.glob(os.path.join(src_dir, "*.zig")):
        total += count_file_loc(filepath)
    return total
