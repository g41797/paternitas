# The Paternitas logo

The logo shows one list, the Anchor, and the types coming out.

## What the picture says

| in the picture | in the library |
|---|---|
| The belt | One list: `std.DoublyLinkedList`, `std.SinglyLinkedList`, or your own. |
| Gray boxes on the belt, all the same | Your structs. On the list, each is only a Node. The list cannot tell them apart. |
| The gold diamond | The `Anchor`. Paternitas reads the type id there. |
| The exits, each with its own color and shape | `parentFromNode`: each struct comes back as its own type. |
| PARENT_A, PARENT_B, PARENT_C | The types you gave with `setTypeId`. |
| The motto | AGNITIO · PATERNITATIS: recognition of the parent. In Roman capitals. |

On the belt every package is the same gray box. After the Anchor each
parent has its own color and shape: an amber circle, a teal triangle, a
coral hexagon.

## The motto

Three Latin terms were weighed.

1. *Agnitio paternitatis*: the father says "this is mine". Chosen. It
   matches `setTypeId`, which you call yourself.
2. *Judicialis paternitatis declaratio*: a court decides. Too far from the
   code.
3. *Praesumptio paternitatis*: paternity is assumed. The opposite of
   `setTypeId`.

### Paternitas and paternitatis

The motto is not a typo of the name. It is the name, in another case.

- *Paternitas*: paternity. The plain form, for a name or a subject.
- *Paternitatis*: of paternity. The same word in the genitive. Latin
  changes the ending to say "of".
- *Agnitio paternitatis*: recognition of paternity. *Agnitio* is the
  subject. *Paternitatis* says what is recognized.

So the motto reads: Paternitas, and what it does. It recognizes the
parent. Latin mottos often take up a name this way.

Two traps.

- *Agnitio* is recognition. *Agnatio* is kinship through the father. The
  logo uses *agnitio*.
- In Roman capitals, U is written V. AGNITIO · PATERNITATIS has no U and
  no J, so nothing changes.

## Files

| file | what it is |
|---|---|
| `gen_logo.py` | The only source. Draws every image below. |
| `kitchen/docs/assets/logo/paternitas-logo.svg` | The logo. The README and the landing page use it. |
| `kitchen/docs/assets/logo/paternitas-logo.png` | The logo, 1600 pixels wide. For GitHub's social preview. |
| `kitchen/docs/assets/logo/favicon.svg` | The logo's Anchor alone: diamond, ring, dot. The site header uses it. |
| `kitchen/docs/assets/logo/favicon.ico` | The same, at 48, 32 and 16 pixels. The browser tab uses it. |
| `fonts/Inter[opsz,wght].ttf`, `fonts/OFL-Inter.txt` | Inter, for the name, the subtitle and the labels, with its license. |
| `fonts/Cinzel[wght].ttf`, `fonts/OFL-Cinzel.txt` | Cinzel, for the motto, with its license. |
| `mascots/` | The first direction, LOOK 01: Zero and Ziggy with masks. Kept as a record, with its attribution. |

## Run it

```bash
python3 kitchen/tools/logo/gen_logo.py
```

It needs Python 3, fontTools and ImageMagick (`magick`).

It writes the SVGs first. Then ImageMagick turns them into the PNG and
the .ico. So the PNG cannot drift from the SVG.

## Tune it

Every setting is a constant at the top of `gen_logo.py`.

| to change | edit |
|---|---|
| colors | `NAVY`, `RAIL`, `GRAY`, `GOLD`, `WHITE`, `MUTED`, and the colors in `EXITS` |
| canvas size, corners | `WIDTH`, `HEIGHT`, `CORNER` |
| the belt | `BELT_LEFT`, `BELT_RIGHT`, `BELT_Y`, `BELT_HEIGHT`, `RAIL_WIDTH` |
| the packages on the belt | `ON_BELT_COUNT`, `ON_BELT_SIZE`, `PACKAGE_START`, `PACKAGE_GAP` |
| the Anchor | `ANCHOR_X`, `ANCHOR_SIZE` |
| the exits | `EXITS`, `EXIT_START`, `EXIT_BEND`, `EXIT_END`, `EXIT_SPREAD`, `LANE_WIDTH` |
| the name | `WORDMARK`, `WORDMARK_FONT`, `WORDMARK_SIZE`, `WORDMARK_SPACING`, `WORDMARK_Y` |
| the gold rule | `RULE_Y` |
| the subtitle | `SUBTITLE`, `SUBTITLE_FONT`, `SUBTITLE_SIZE`, `SUBTITLE_SPACING`, `SUBTITLE_Y` |
| the exit labels | `LABEL_FONT`, `LABEL_SIZE`, `LABEL_SPACING` |
| the motto | `MOTTO`, `MOTTO_FONT`, `MOTTO_SIZE`, `MOTTO_SPACING`, `MOTTO_Y` |
| the PNG width | `PNG_WIDTH` |
| the favicon | `FAVICON_ANCHOR_SIZE`, `FAVICON_STROKE` |
| the .ico sizes | `ICO_SIZES` |

Change a number. Run the script. Look at the PNG.

## Fonts

All text in the logo is drawn as paths. No viewer needs a font. The logo
looks the same on GitHub, on the site and in the PNG.

- Inter: the name, the subtitle, the labels. A font made for screens.
- Cinzel: the motto. It follows the capitals carved on Trajan's Column in
  Rome. The middle dot is the old inscription mark.
- Both are under the SIL Open Font License 1.1, from the Google Fonts
  repository. The licenses are in `fonts/`.

A font setting is (file, weight, optical size).

- Weight: 400 is regular, 700 is bold.
- Optical size: Inter has one, from 14 to 32. Big text looks best at 32,
  small text at 14. Cinzel has none, so it is 0.
- Spacing is extra room after each letter, in pixels. Below 0 is tighter.

Each letter is stored once in the SVG and used again where it repeats.
Kerning is not applied. Spacing does the same job by hand.

## History

The owner drafted the concept with Grok Imagine, an image generator. Then
came an SVG and a Pillow script. LOOK 02 made the logo again with
`gen_logo.py`. The prototype folder was removed after these prompts were
copied here.

The motto in prompt 4 replaced an earlier Latin line, and the Archimedes
quote was the first Anchor motto. It stays in the `Anchor` `///`.

### The Grok Imagine prompts, in order

#### 1. Anchor-style logo (first exploration)

```
Minimal modern software project logo for "Paternitas", a Zig library for safer
intrusive type-erased containers. Center: a strong geometric anchor symbol as
the fixed point (Archimedes "give me a place to stand"). From the anchor,
subtle linked nodes or chain links form a clean doubly-linked list path,
suggesting structure without clutter. Typography: bold clean sans-serif
wordmark "Paternitas" below or integrated, professional and technical. Color
palette: deep charcoal/navy background, single accent of warm amber or soft
gold for the anchor, white or light gray for text and nodes. Flat vector style,
high contrast, suitable for GitHub README and app icons, no gradients overload,
no clutter, elegant and precise like a systems programming tool. Square
composition, centered, plenty of negative space.
```

#### 2. Transportation-line logo (core concept)

```
Minimal modern software project logo for "Paternitas", a Zig library for safer
intrusive type-erased containers. Visual concept: a clean horizontal conveyor /
transportation line. On the left and middle of the belt: several simple
geometric packages or gadgets (small boxes, cylinders, rounded blocks)
traveling as anonymous identical silhouettes in muted gray/silver, linked by
subtle chain or node dots suggesting an intrusive list. At the right end: the
packages diverge into separate type-colored paths or small labeled lanes
(warm amber, soft teal, muted coral), each package now distinct by shape or
color, representing recovery by type. Center or integrated mark: a strong
geometric anchor or fixed-point symbol where the belt runs through, tying to
the Archimedes motto. Typography: bold clean sans-serif wordmark "Paternitas"
below, professional technical feel. Color palette: deep charcoal or navy
background, silver/gray packages on the belt, single gold/amber accent for the
anchor and type-sorted exits, white text. Flat vector style, high contrast,
elegant systems-programming aesthetic, square composition, plenty of negative
space, no clutter, suitable for GitHub README and icons.
```

#### 3. Edit: Type → Parent

```
Replace every label that says TYPE_A, TYPE_B, TYPE_C (and the letter T above
them) with PARENT_A, PARENT_B, PARENT_C. Keep the same colors, layout, conveyor
belt, packages, gold diamond mark, wordmark "Paternitas", and all other text
exactly as they are. Only change Type to Parent in those exit labels.
```

#### 4. Edit: motto → Agnitio paternitatis

```
Replace the Latin motto text at the bottom that currently reads
"FIX FIXTUS, LUCET INVENIT" with "AGNITIO PATERNITATIS". Keep the same gold
color, same small diamond bullets on both sides, same font style and size,
same position under the subtitle. Do not change anything else in the image:
conveyor, packages, PARENT_A/B/C labels, gold diamond mark, wordmark
Paternitas, or background.
```
