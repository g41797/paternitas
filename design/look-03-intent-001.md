# LOOK 03 — intent (001)

The logo gets its "in" side. The owner named it, 2026-10-07.

- The plan: [implementation-plan-021.md](implementation-plan-021.md), "LOOK 03".
- The rules: [rules-014.md](rules-014.md).
- The logo today: `kitchen/tools/logo/gen_logo.py`, explained in
  [LOGO.md](../kitchen/tools/logo/LOGO.md). LOOK 02 made it.

---

## Why

The owner's look at the logo, 2026-10-07:

- The right side has three Parents: color, shape, a name.
- The left end of the belt shows nothing.

The picture starts in the middle of the story.

- The gray boxes are already anonymous on the belt.
- The "before" is missing: each struct had its type before it entered the
  list.
- The right half is busy. The left half is a bare rounded end.

---

## The owner's choice

Option 1 of three: the "in" side.

- Not taken: a "?" on each gray box. The left stays empty.
- Not taken: only re-centering. The "before" stays missing.

---

## The picture after

```text
  ▲ ─╮                                        ╭─ ● PARENT_A
  ● ─┼─( ■ - ■ - ■ - ■ - ◇ )──────────────────┼─ ▲ PARENT_B
  ⬢ ─╯                                        ╰─ ⬢ PARENT_C
 typed        anonymous on the list    Anchor    recognized
```

Left to right, one story:

1. Typed Parents go in: three colored shapes.
2. On the belt each is the same gray box.
3. At the Anchor each comes out with its own color, shape and name.

---

## The "in" side

- Three shapes on the left: the same three as the exits. A circle, a
  triangle, a hexagon. Their own colors.
- No labels. The names stay on the right, once.
- A mixed order: triangle, circle, hexagon, top to bottom.
  - The exits stay sorted: A, B, C.
  - It shows the list mixes them, and *Paternitas* sorts them out.
- Each shape has a short curved lane, in its color. The lanes merge into
  the belt's left end.
  - They mirror the exit lanes.
  - The same vertical spread as the exits.
- The shapes may be a little smaller than the exits. The eye goes to the
  right.

---

## What makes room

The canvas stays 800 by 540. The left side needs about 100 more.

- The belt starts further right: `BELT_LEFT` from 50 to about 150.
- Four gray boxes, not five: `ON_BELT_COUNT` 4.
- `PACKAGE_START` moves with the belt.
- The Anchor and the exits do not move.

The numbers are a first guess. They are tuned with the owner, in rounds,
as in LOOK 02.

---

## The code

`kitchen/tools/logo/gen_logo.py`:

- A new setting, `ENTRIES`: (color, shape, size), in the mixed order.
- New settings for the lanes in: `ENTRY_X`, `ENTRY_BEND`, `ENTRY_END`.
- A new function, `entries()`, beside `exits()`. It reuses `package()`.
- `logo()` draws `entries()`.
- The `aria-label`: "Typed structs go in, ride one list as anonymous
  boxes, and come out recognized by type. Agnitio paternitatis."

Not changed:

- The favicon: the Anchor alone.
- The words: the wordmark, the subtitle, the motto.
- The colors.

---

## The text

- [LOGO.md](../kitchen/tools/logo/LOGO.md), "What the picture says": a new
  first row.
  - "The colored shapes on the left": your structs, each typed with
    `setTypeId`, before they enter the list.
  - The "Settings" table gets the new settings.
- The site and the README show the logo by path. No change.

---

## Order of work

1. `gen_logo.py`: `ENTRIES`, `entries()`, the room on the left.
2. Run it. The SVG and the PNG are made again.
3. The owner looks, in the preview. Tuning rounds.
4. `kitchen/tools/logo/LOGO.md`.
5. The six gates. The strict site build.

---

## Open

1. The owner approves this intent before any code.
