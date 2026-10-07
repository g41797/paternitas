"""mkdocs build-time hook: a link on a page opens in a new tab.

A link that already has a target keeps it. To keep a link in the same tab, give it target="_self".
A link to a heading on the same page (#...) stays in the same tab.
"""

import re

_LINK = re.compile(r'<a\s(?![^>]*\btarget=)([^>]*\bhref="(?!#)[^"]*"[^>]*)>')


def on_page_content(html, page, config, files):
    return _LINK.sub(r'<a \1 target="_blank" rel="noopener">', html)
