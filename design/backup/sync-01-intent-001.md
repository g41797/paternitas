# SYNC 01 — intent (001)

The comments in `src/`, `examples/` and `negative/` follow the README and
the site. The owner named it, 2026-10-07.

- The plan: [implementation-plan-022.md](implementation-plan-022.md),
  "SYNC 01".
- The rules: [rules-014.md](rules-014.md). Part 0, "The README and the site":
  text cut from a comment stays on the site.

---

## The owner's rulings, 2026-10-07

1. The README and the site are the truth. The comments follow them.
2. The module comment of `src/paternitas.zig` shrinks.
3. The first line of each example header is its site title.
4. g4 checks `src/`, `examples/` and `negative/` too.

---

## Why

- The comments become the API pages, `apidocs/`. The hero pill opens them.
- The module comment of `src/paternitas.zig` was 194 lines: a third manual,
  next to the README and the site.
- It drifted. "marks", a link to the README for the migration, an example
  named by its number.

---

## The inventory

Read only, before any edit.

| file | line | drift | fix |
|---|---|---|---|
| `src/paternitas.zig` | 4-197 | the module comment repeats the site | shrink, see below |
| `src/paternitas.zig` | 56 | "The full program and the migration are in the README" | the site has them now |
| `src/paternitas.zig` | 61 | "`setTypeId(&p)` marks the struct as that type" | "sets the struct's type id" |
| `src/paternitas.zig` | 195 | "A struct marked by `setTypeId` in the library" | "whose type id was set in the library" |
| `src/paternitas.zig` | 280 | "Marks `p` as a value of type `P`." | "Sets the type id of `p`." |
| `src/paternitas.zig` | 615 | "A struct marked by `setTypeId` in the library" | "whose type id was set in the library" |
| `src/container.zig` | 51 | "The full program is example 006, "Your own stack"." | the title only |

Clean, no change:

- The example headers. Each opens with `Title:` and the site title.
  Ruling 3 holds already.
- The inline comments in the examples.
- The `negative/` headers.
- The `///` comments on each `pub` declaration, apart from the two above.
- The module comment of `src/container.zig`, apart from line 51. It is
  for container authors, and stays at its length.

---

## The new module comment

It keeps:

- the first lines: the problem and the check;
- what a wrong type gives, every build mode, the std list stays;
- the four calls and `mustParentFromNode`;
- the "after" code;
- the setTypeId rule, in three lines;
- one line each for `Any`, `typeId` and `container`;
- a link to the site, with the page names.

It cuts, and the site holds each:

| cut | the site page |
|---|---|
| "Do you need it?", the typical places | "Are you my Parent?": "When the trouble starts", "Do you need it?"; "Queues, maps, union fields"; "Your own container" |
| "Three words first" | "Intrusive lists", "Type-erased lists", "Stuck on a word?" |
| the Messages and Jobs story | "Are you my Parent?": "The footgun" |
| "Typical use": the diagram, before, the five steps, the compiler | "Migrate your code" |
| "A small but important rule", in full | "The setTypeId rule" |
| "Passing a struct through type-erased code", the handler code | "Queues, maps, union fields"; "Handler map" |
| "Writing a container" | "Your own container" |
| "Limits" | "Limits" |

The site link: `https://g41797.github.io/paternitas/`, the GitHub Pages
address of the repo. Not checked live: CI and Pages are an open item.

---

## g4

- Check 2 reads `negative/` too.
- A new check 4: the old wording. `mark`, `marks`, `marked`, `marking` in
  `src/`, `examples/`, `negative/`, `tests/`, the README and the site
  pages. Not in `design/`: the log and the old docs record it.

---

## Order of work

1. `src/paternitas.zig`: the module comment, then lines 280 and 615.
2. `src/container.zig`: line 51.
3. g4: `negative/`, check 4.
4. The six gates. The strict site build. The API pages, one look.
5. STATUS.md, STATUS-LOG.md.
