"""mkdocs build-time hook: substitute {{ src_loc() }} with the current src/*.zig LOC total."""

import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from src_loc import count_src_loc  # noqa: E402

_HOOK_DIR = os.path.dirname(__file__)
_SRC_DIR = os.path.join(_HOOK_DIR, "..", "..", "src")

_PATTERN = re.compile(r"\{\{\s*src_loc\(\)\s*\}\}")


def on_page_markdown(markdown, page, config, files):
    return _PATTERN.sub(str(count_src_loc(_SRC_DIR)), markdown)
