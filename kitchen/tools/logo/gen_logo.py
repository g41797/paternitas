"""Draws the Paternitas logo and favicon: the entries, the belt, the Anchor and the exits.

The SVG is the only source. The PNG and the .ico are converted from it.
Writes into kitchen/docs/assets/logo/. LOGO.md next to this file explains
the picture and the settings below.

Run: python3 kitchen/tools/logo/gen_logo.py  (needs ImageMagick and fontTools)
"""

import functools
import math
import os
import subprocess

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "..", "docs", "assets", "logo")

# Colors.
NAVY = "#0d1b2a"
RAIL = "#6b7280"
RAIL_DARK = "#4b5563"
GRAY = "#6b7280"
GOLD = "#c9a227"
WHITE = "#f8fafc"
MUTED = "#94a3b8"

# Canvas.
WIDTH, HEIGHT = 800, 540
CORNER = 24

# The entries: (color, shape, size). Each parent goes in with its own color
# and shape, before the list makes it anonymous. A mixed order: the list
# mixes them, the exits sort them. No labels: the names are on the exits.
ENTRIES = [
    ("#0d9488", "triangle", 32),
    ("#d97706", "circle", 30),
    ("#dc2626", "hexagon", 32),
]
ENTRY_X = 44       # The middle of the entry packages.
ENTRY_BEND = 100   # Where the lanes stop being level.
ENTRY_SPREAD = 88  # The distance between lanes.

# The belt: a closed track, with the struct packages riding inside.
BELT_LEFT, BELT_RIGHT = 182, 450
BELT_Y, BELT_HEIGHT = 170, 84  # BELT_Y is the middle line.
RAIL_WIDTH = 8

# The packages on the belt. On the list they all look the same: one gray box.
ON_BELT_COUNT = 3
ON_BELT_SIZE = 36
PACKAGE_GAP = 30
PACKAGE_START = 208

# The Anchor at the end of the belt.
ANCHOR_X = 450
ANCHOR_SIZE = 44  # From the middle to a corner.

# The exits: (color, label, shape, size). Each parent comes out with its own
# color and its own shape. Shapes: "box", "circle", "triangle", "hexagon".
EXITS = [
    ("#d97706", "PARENT_A", "circle", 34),
    ("#0d9488", "PARENT_B", "triangle", 36),
    ("#dc2626", "PARENT_C", "hexagon", 36),
]
EXIT_START = 500  # Where the lanes leave the Anchor.
EXIT_BEND = 570   # Where the lanes turn level.
EXIT_END = 630    # Where the lanes stop.
EXIT_SPREAD = 88  # The distance between lanes.
LANE_WIDTH = 3

# Text. The landing page can show the logo smaller than 800 wide, so the
# small text must not be too small.
#
# All text is drawn as paths, so it looks the same everywhere, with no font
# installed. A font is (file, weight, optical size). Optical size 0 means
# the file has none.
FONTS = os.path.join(HERE, "fonts")
INTER = os.path.join(FONTS, "Inter[opsz,wght].ttf")
CINZEL = os.path.join(FONTS, "Cinzel[wght].ttf")

WORDMARK = "Paternitas"
WORDMARK_FONT = (INTER, 700, 32)
WORDMARK_SIZE = 76
WORDMARK_SPACING = -1.5  # Extra room after each letter. Below 0 is tighter.
WORDMARK_Y = 382

RULE_Y = 414

SUBTITLE = "RUNTIME TYPE IDS · SAFER INTRUSIVE TYPE-ERASED CONTAINERS"
SUBTITLE_FONT = (INTER, 500, 14)
SUBTITLE_SIZE = 16
SUBTITLE_SPACING = 1.5
SUBTITLE_Y = 452

LABEL_FONT = (INTER, 700, 14)
LABEL_SIZE = 17
LABEL_SPACING = 0.5

# The motto is in Cinzel, after the capitals on Trajan's Column. The
# middle dot is the old inscription mark.
MOTTO = "AGNITIO · PATERNITATIS"
MOTTO_FONT = (CINZEL, 600, 0)
MOTTO_SIZE = 21
MOTTO_Y = 496
MOTTO_SPACING = 3

# The favicon: the logo's Anchor, scaled to a 64 by 64 square.
FAVICON_ANCHOR_SIZE = 27
FAVICON_STROKE = 5

# Rasters.
PNG_WIDTH = 1600
ICO_SIZES = "48,32,16"


def main() -> None:
    write("paternitas-logo.svg", logo())
    write("favicon.svg", favicon())
    convert("paternitas-logo.svg", "paternitas-logo.png", ["-resize", f"{PNG_WIDTH}x"])
    convert("favicon.svg", "favicon.ico", ["-define", f"icon:auto-resize={ICO_SIZES}"])


def logo() -> str:
    parts = [f'<rect width="{WIDTH}" height="{HEIGHT}" rx="{CORNER}" fill="{NAVY}"/>']
    parts += entries()
    parts += belt()
    parts += exits()
    parts += anchor(ANCHOR_X, BELT_Y, ANCHOR_SIZE, 6)
    parts += words()
    parts.insert(0, glyph_defs())
    label = ("Paternitas: runtime type ids, safer intrusive type-erased containers. Typed structs go in, ride one list "
             "as anonymous boxes, and come out recognized by type. Agnitio paternitatis.")
    return svg(f"0 0 {WIDTH} {HEIGHT}", label, parts)


def belt() -> list:
    top, bottom = BELT_Y - BELT_HEIGHT / 2, BELT_Y + BELT_HEIGHT / 2
    r = BELT_HEIGHT / 2
    track = (f"M{BELT_LEFT + r},{top} L{BELT_RIGHT},{top} M{BELT_RIGHT},{bottom} L{BELT_LEFT + r},{bottom} "
             f"A{r},{r} 0 0,1 {BELT_LEFT + r},{top}")
    parts = [
        f'<path d="{track}" fill="none" stroke="{RAIL}" stroke-width="{RAIL_WIDTH}" stroke-linecap="round"/>',
        f'<path d="M{BELT_LEFT + r},{BELT_Y} L{BELT_RIGHT - ANCHOR_SIZE},{BELT_Y}" stroke="{RAIL_DARK}" '
        f'stroke-width="3" stroke-dasharray="6 8"/>',
    ]
    size = ON_BELT_SIZE
    for i in range(ON_BELT_COUNT):
        x = PACKAGE_START + i * (size + PACKAGE_GAP)
        parts.append(package("box", x + size / 2, BELT_Y, size, GRAY))
    return parts


def entries() -> list:
    parts = []
    middle = (len(ENTRIES) - 1) / 2
    slot = max(size for _, _, size in ENTRIES)
    merge = BELT_LEFT - RAIL_WIDTH / 2 - 6  # The lanes meet just outside the belt's left end.
    pull = (merge - ENTRY_BEND) / 2
    for i, (color, shape, size) in enumerate(ENTRIES):
        y = BELT_Y + (i - middle) * ENTRY_SPREAD
        start = ENTRY_X + slot / 2 + 12
        lane = f"M{start},{y} L{ENTRY_BEND},{y} C{ENTRY_BEND + pull},{y} {merge - pull},{BELT_Y} {merge},{BELT_Y}"
        parts.append(f'<path d="{lane}" fill="none" stroke="{color}" stroke-width="{LANE_WIDTH}" stroke-linecap="round"/>')
        parts.append(package(shape, ENTRY_X, y, size, color))
    return parts


def exits() -> list:
    parts = []
    middle = (len(EXITS) - 1) / 2
    slot = max(size for _, _, _, size in EXITS)
    for i, (color, name, shape, size) in enumerate(EXITS):
        y = BELT_Y + (i - middle) * EXIT_SPREAD
        lane = f"M{EXIT_START},{BELT_Y} C{EXIT_START + 30},{BELT_Y} {EXIT_BEND - 30},{y} {EXIT_BEND},{y} L{EXIT_END},{y}"
        parts.append(f'<path d="{lane}" fill="none" stroke="{color}" stroke-width="{LANE_WIDTH}" stroke-linecap="round"/>')
        # All packages share one slot, so all labels start at one x.
        cx = EXIT_END + 12 + slot / 2
        parts.append(package(shape, cx, y, size, color))
        parts.append(text_path(name, EXIT_END + 24 + slot, y + 6, LABEL_FONT, LABEL_SIZE, LABEL_SPACING, color,
                               centered=False))
    return parts


def words() -> list:
    c = WIDTH / 2
    return [
        text_path(WORDMARK, c, WORDMARK_Y, WORDMARK_FONT, WORDMARK_SIZE, WORDMARK_SPACING, WHITE),
        f'<path d="M{c - 220},{RULE_Y} H{c - 26} M{c + 26},{RULE_Y} H{c + 220}" stroke="{GOLD}" stroke-width="1.5"/>',
        f'<path d="M{c},{RULE_Y - 8} l8,8 l-8,8 l-8,-8 Z" fill="{GOLD}"/>',
        text_path(SUBTITLE, c, SUBTITLE_Y, SUBTITLE_FONT, SUBTITLE_SIZE, SUBTITLE_SPACING, MUTED),
        text_path(MOTTO, c, MOTTO_Y, MOTTO_FONT, MOTTO_SIZE, MOTTO_SPACING, GOLD),
    ]


def text_path(text: str, x: float, baseline: float, font: tuple, size: float, spacing: float, color: str,
              centered: bool = True) -> str:
    """The text as paths. Centered on x, or starting at x."""
    face = load_font(*font)
    glyphs, cmap = face.getGlyphSet(), face.getBestCmap()
    k = size / face["head"].unitsPerEm
    names = [cmap[ord(ch)] for ch in text]
    widths = [glyphs[n].width * k + spacing for n in names]
    if centered:
        x -= (sum(widths) - spacing) / 2
    parts = []
    for name, w in zip(names, widths):
        ref = glyph(font, name)
        if ref:
            parts.append(f'<use href="#{ref}" transform="translate({x:.2f} {baseline}) scale({k:.5f} {-k:.5f})"/>')
        x += w
    return f'<g fill="{color}">' + "".join(parts) + "</g>"


# Each letter is drawn once, in <defs>, and used again by its id.
GLYPHS: dict = {}


def glyph(font: tuple, name: str) -> str:
    """The id of the letter's path in <defs>, or "" for a blank."""
    ref = f"{os.path.basename(font[0]).split('[')[0].lower()}-{font[1]}-{font[2]}-{name}"
    if ref not in GLYPHS:
        glyphs = load_font(*font).getGlyphSet()
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        GLYPHS[ref] = pen.getCommands()
    return ref if GLYPHS[ref] else ""


def glyph_defs() -> str:
    paths = "".join(f'<path id="{ref}" d="{d}"/>' for ref, d in GLYPHS.items() if d)
    return f"<defs>{paths}</defs>"


@functools.cache
def load_font(path: str, weight: int, optical_size: int) -> TTFont:
    axes = {"wght": weight}
    if optical_size:
        axes["opsz"] = optical_size
    return instancer.instantiateVariableFont(TTFont(path), axes)


def favicon() -> str:
    """The Anchor of the logo, the same diamond, ring and dot, on navy."""
    return svg("0 0 64 64", "Paternitas", [f'<rect width="64" height="64" rx="12" fill="{NAVY}"/>']
               + anchor(32, 32, FAVICON_ANCHOR_SIZE, FAVICON_STROKE))


def anchor(cx: float, cy: float, size: float, stroke: float) -> list:
    """The gold diamond with a ring and a dot: the one place where the type id is read."""
    s = size
    return [
        f'<path d="M{cx},{cy - s} L{cx + s},{cy} L{cx},{cy + s} L{cx - s},{cy} Z" fill="{NAVY}" stroke="{GOLD}" '
        f'stroke-width="{stroke}" stroke-linejoin="miter"/>',
        f'<circle cx="{cx}" cy="{cy}" r="{s * 0.34:.1f}" fill="none" stroke="{GOLD}" stroke-width="{stroke * 0.7:.1f}"/>',
        f'<circle cx="{cx}" cy="{cy}" r="{s * 0.12:.1f}" fill="{GOLD}"/>',
    ]


def package(shape: str, cx: float, cy: float, size: float, color: str) -> str:
    """One package, centered on (cx, cy), size wide."""
    r = size / 2
    if shape == "circle":
        return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{color}"/>'
    if shape == "triangle":
        h = size * 0.87
        points = [(cx, cy - h / 2), (cx + r, cy + h / 2), (cx - r, cy + h / 2)]
    elif shape == "hexagon":
        points = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))) for a in range(0, 360, 60)]
    else:
        return f'<rect x="{cx - r:.1f}" y="{cy - r:.1f}" width="{size}" height="{size}" rx="4" fill="{color}"/>'
    d = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    return f'<polygon points="{d}" fill="{color}" stroke="{color}" stroke-width="3" stroke-linejoin="round"/>'


def svg(view_box: str, label: str, parts: list) -> str:
    # width and height give the image a size of its own. Without them a page
    # can shrink it to nothing.
    _, _, width, height = view_box.split()
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view_box}" role="img" aria-label="{label}">\n'
            + "\n".join(parts) + "\n</svg>\n")


def convert(src: str, dst: str, options: list) -> None:
    subprocess.run(["magick", "-background", "none", "-density", "600", os.path.join(OUT_DIR, src),
                    *options, os.path.join(OUT_DIR, dst)], check=True)


def write(name: str, text: str) -> None:
    with open(os.path.join(OUT_DIR, name), "w", encoding="utf-8") as f:
        f.write(text)


if __name__ == "__main__":
    main()
