"""Draws Paternitas' logo, mask picture and favicon from the two Zig mascots.

The first logo direction, kept as a record. LOOK 02 replaced it.

Reads Zero and Ziggy from this folder, as they came from
Wikimedia Commons. Writes the SVGs and favicon.ico next to them.
See ATTRIBUTION.md there for the sources and the license.

Each mascot holds up the same mask on a stick. A thin thread joins the sticks.

Run: python3 kitchen/tools/logo/mascots/gen_logo.py  (needs ImageMagick for the .ico)
"""

import os
import re
import subprocess

LOGO_DIR = os.path.dirname(os.path.abspath(__file__))

MASK_COLOR = "#283593"
STICK_COLOR = "#c8962e"
THREAD_COLOR = "#f7a41d"
FONT = 'font-family="system-ui, -apple-system, Segoe UI, Helvetica, Arial, sans-serif"'
MONO = 'font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"'

# Where each mascot's eye and holding paw are, in its own SVG units.
ZIGGY_EYE = (307.6, 104.0)
ZIGGY_PAW = (300.0, 278.0)
ZERO_EYE = (81.6, 72.0)
ZERO_PAW = (96.0, 178.0)

# Where the stick meets the mask, in mask units: low, at the back.
STICK_AT = (-36.0, 16.0)

# The mask in profile, drawn around an eye hole at (0,0), looking toward +x.
MASK = f"""<g>
<path fill-rule="evenodd" d="M-48,-8 C-34,-30 22,-32 38,-14 C46,-4 40,12 28,18 C12,26 -30,26 -46,12 C-52,6 -52,-2 -48,-8 Z M0,-21 a20,17 0 1,0 0.1,0 Z" fill="{MASK_COLOR}" stroke="#111" stroke-width="2.5" stroke-linejoin="round"/>
<path d="M-46,-6 C-56,-22 -44,-34 -30,-30 C-40,-26 -42,-18 -36,-14" fill="{MASK_COLOR}" stroke="#111" stroke-width="2.5" stroke-linejoin="round"/>
<path d="M-34,-16 C-20,-26 10,-27 24,-20" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="3" stroke-linecap="round"/>
</g>"""


def main() -> None:
    zero = inner(read("zero-the-ziguana.svg"))
    # Ziggy keeps the root attributes of its own file.
    ziggy = (
        '<g fill-rule="evenodd" clip-rule="evenodd" stroke-linejoin="round" stroke-miterlimit="2">'
        + inner(read("ziggy-the-ziguana.svg"))
        + "</g>"
    )
    write("paternitas-logo.svg", logo(zero, ziggy))
    write("paternitas-mask.svg", picture(zero, ziggy))
    write("favicon.svg", favicon())
    make_ico()


class Figure:
    """A mascot placed on the page, with the mask it holds up."""

    def __init__(self, body: str, at: tuple, scale: float, eye: tuple, paw: tuple, mask_scale: float, flip: bool):
        self.body = placed(body, at, scale)
        self.eye = point(at, scale, eye)
        self.paw = point(at, scale, paw)
        self.mask_scale = mask_scale
        self.flip = flip
        side = -1 if flip else 1
        self.top = (self.eye[0] + side * STICK_AT[0] * mask_scale, self.eye[1] + STICK_AT[1] * mask_scale)

    def along(self, t: float) -> tuple:
        """A point on the stick: 0 is the paw, 1 is the mask."""
        return (self.paw[0] + (self.top[0] - self.paw[0]) * t, self.paw[1] + (self.top[1] - self.paw[1]) * t)

    def stick(self, width: float) -> str:
        d = f"M{self.paw[0]:.1f},{self.paw[1]:.1f} L{self.top[0]:.1f},{self.top[1]:.1f}"
        return (f'<path d="{d}" stroke="#111" stroke-width="{width + 2.5:.1f}" stroke-linecap="round"/>'
                f'<path d="{d}" stroke="{STICK_COLOR}" stroke-width="{width:.1f}" stroke-linecap="round"/>')

    def mask(self) -> str:
        sx = -self.mask_scale if self.flip else self.mask_scale
        return f'<g transform="translate({self.eye[0]:.1f} {self.eye[1]:.1f}) scale({sx} {self.mask_scale})">{MASK}</g>'


def ziggy_at(body: str, at: tuple, scale: float, mask_scale: float) -> Figure:
    return Figure(body, at, scale, ZIGGY_EYE, ZIGGY_PAW, mask_scale, flip=False)


def zero_at(body: str, at: tuple, scale: float, mask_scale: float) -> Figure:
    return Figure(body, at, scale, ZERO_EYE, ZERO_PAW, mask_scale, flip=True)


def logo(zero: str, ziggy: str) -> str:
    """Ziggy and Zero look at each other. Each holds up the same mask. A thread joins the sticks."""
    figures = [ziggy_at(ziggy, (0, 70), 1.0, 1.0), zero_at(zero, (390, 10), 1.3, 1.0)]
    a, b = figures[0].along(0.45), figures[1].along(0.45)
    parts = [f.body for f in figures]
    parts.append(thread([a, b], sag=40, width=2))
    parts += [f.stick(5) for f in figures]
    parts += [f.mask() for f in figures]
    return svg("0 0 770 400", "Paternitas: Ziggy and Zero, the Zig mascots, each holding up the same mask on a stick, the sticks joined by a thread.", parts)


def picture(zero: str, ziggy: str) -> str:
    """Three structs on one list. The list sees the same mask. Paternitas sees the type."""
    width, height, base = 900, 330, 185
    cols = [340, 560, 780]
    cast = [("ziggy", "Message"), ("zero", "Job"), ("ziggy", "Message")]
    parts = [f'<rect x="1" y="1" width="{width - 2}" height="{height - 2}" rx="14" fill="#f7f8fc" stroke="#d5d9e6" stroke-width="2"/>']
    figures = []
    for cx, (who, _) in zip(cols, cast):
        if who == "ziggy":
            scale = 0.45
            figures.append(ziggy_at(ziggy, (cx - 194 * scale, base - 300 * scale), scale, 0.42))
        else:
            scale = 0.5
            figures.append(zero_at(zero, (cx - 144 * scale, base - 288 * scale), scale, 0.42))
    parts += [f.body for f in figures]
    knots = [f.along(0.5) for f in figures]
    first, last = knots[0], knots[-1]
    lead = f"M{first[0] - 120:.1f},{first[1] - 10:.1f} L{first[0]:.1f},{first[1]:.1f}"
    tail = f"M{last[0]:.1f},{last[1]:.1f} L{last[0] + 80:.1f},{last[1] - 10:.1f}"
    for d in (lead, tail):
        parts.append(f'<path d="{d}" fill="none" stroke="{THREAD_COLOR}" stroke-width="2" stroke-linecap="round" stroke-dasharray="2 6"/>')
    parts.append(thread(knots, sag=25, width=2))
    parts += [f.stick(2.5) for f in figures]
    parts += [f.mask() for f in figures]
    parts.append(f'<text x="30" y="110" {FONT} font-size="20" font-weight="600" fill="{MASK_COLOR}">The list sees</text>')
    parts.append(f'<text x="30" y="262" {FONT} font-size="20" font-weight="600" fill="{MASK_COLOR}">Paternitas sees</text>')
    for cx, (_, name) in zip(cols, cast):
        parts.append(f'<text x="{cx}" y="214" text-anchor="middle" {MONO} font-size="17" fill="#555">Node</text>')
        parts.append(f'<path d="M{cx},224 v18 m-6,-7 l6,7 l6,-7" fill="none" stroke="#888" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>')
        parts.append(f'<text x="{cx}" y="268" text-anchor="middle" {MONO} font-size="19" font-weight="700" fill="#111">{name}</text>')
    parts.append(f'<text x="{width / 2:.0f}" y="308" text-anchor="middle" {FONT} font-size="15" fill="#555">Each one holds up the same mask. The type id says who is behind it.</text>')
    label = "The list sees the same Node on each struct. Paternitas reads the type id and sees a Message, a Job and a Message."
    return svg(f"0 0 {width} {height}", label, parts)


def favicon() -> str:
    """The same mask, seen from the front, on its stick, on Zig orange."""
    return svg("0 0 64 64", "Paternitas", [
        '<rect width="64" height="64" rx="12" fill="#f7a41d"/>',
        '<path d="M47,36 L55,59" stroke="#111" stroke-width="6" stroke-linecap="round"/>',
        f'<path d="M47,36 L55,59" stroke="{STICK_COLOR}" stroke-width="3.5" stroke-linecap="round"/>',
        f'<path fill-rule="evenodd" fill="{MASK_COLOR}" stroke="#111" stroke-width="1.6" stroke-linejoin="round" '
        'd="M5,22 C5,12 20,10 32,16 C44,10 59,12 59,22 C59,35 47,41 39,36 C36,34 34,32 32,32 C30,32 28,34 25,36 C17,41 5,35 5,22 Z '
        'M19,19 a6.5,5.2 0 1,0 0.1,0 Z M45,19 a6.5,5.2 0 1,0 0.1,0 Z"/>',
    ])


def make_ico() -> None:
    src = os.path.join(LOGO_DIR, "favicon.svg")
    dst = os.path.join(LOGO_DIR, "favicon.ico")
    subprocess.run(["magick", "-background", "none", "-density", "600", src,
                    "-define", "icon:auto-resize=48,32,16", dst], check=True)


def thread(points: list, sag: float, width: float) -> str:
    d = f"M{points[0][0]:.1f},{points[0][1]:.1f}"
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        dx = (x1 - x0) / 3
        d += f" C{x0 + dx:.1f},{y0 + sag:.1f} {x1 - dx:.1f},{y1 + sag:.1f} {x1:.1f},{y1:.1f}"
    return f'<path d="{d}" fill="none" stroke="{THREAD_COLOR}" stroke-width="{width}" stroke-linecap="round"/>'


def point(at: tuple, scale: float, own: tuple) -> tuple:
    return (at[0] + own[0] * scale, at[1] + own[1] * scale)


def placed(body: str, at: tuple, scale: float) -> str:
    return f'<g transform="translate({at[0]:.1f} {at[1]:.1f}) scale({scale})">{body}</g>'


def svg(view_box: str, label: str, parts: list) -> str:
    # width and height give the image a size of its own. Without them a page
    # can shrink it to nothing.
    _, _, width, height = view_box.split()
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view_box}" role="img" aria-label="{label}">\n'
            + "\n".join(parts) + "\n</svg>\n")


def inner(text: str) -> str:
    text = re.sub(r"^.*?<svg[^>]*>", "", text, flags=re.S)
    return text.rsplit("</svg>", 1)[0]


def read(name: str) -> str:
    with open(os.path.join(LOGO_DIR, name), encoding="utf-8") as f:
        return f.read()


def write(name: str, text: str) -> None:
    with open(os.path.join(LOGO_DIR, name), "w", encoding="utf-8") as f:
        f.write(text)


if __name__ == "__main__":
    main()
