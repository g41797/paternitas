# ZTK DOCS — backlog (004)

Change from 003: the ZTK HOME answers, 2026-10-22. Items B35 to B40, from
[ztk-home-audit-002.md](ztk-home-audit-002.md). Old versions are never
deleted; cleanup is later, the owner's.

Change from 002, kept:
Change from 002: the example pages are generated. 2026-10-22.

- The inventory (B28) covers only the 60 hand-written pages. The examples
  get one line: generated.
- An example page is fixed in its `//!` header in `ztk/examples/`, never in
  the `.md`. The old matryoshka-ztk example pages are not a source. ztk's
  own examples, in today's words, are.
- B30: the generator, in the site build, with the nav sync.
- B34: each example's `//!` header, checked.

Change from 001, kept:
Change from 001: the owner, 2026-10-22. The docs are the whole site, not
the README alone. The README was temporary: it grows into a real one. The
hero page takes the paternitas style: the image and two buttons.

The ztk docs are fixed in many small steps. The owner's ruling, 2026-10-22:

- One stage does not fix all of it. The work is iterative.
- Nothing important is lost. Every finding, deviation and idea is written
  here first, even if no step takes it yet.
- Each step is small, has its own approval, and passes all gates.

Sources: [ztk-docs-01-findings-001.md](ztk-docs-01-findings-001.md) (the
F numbers), [ztk-docs-01-intent-001.md](ztk-docs-01-intent-001.md).

## How the backlog works

- One line per item. An id, the F number, the size, the state.
- Sizes: S (one file, comments only), M (several files), L (needs a
  ruling or touches code).
- States: open, next, done (with the date), dropped (with the reason).
- A step takes one to three S items. A new finding goes in as a new line.
  An item is never deleted. A dropped item says why.

## What the docs are

- The ztk site: `ztk/kitchen/docs/`. Today one page, a hero with one badge.
- Its source: the matryoshka-ztk site, `kitchen/docs/`, 148 pages, read
  only.
  - 4 root pages: `index`, `manifesto`, `history`, `the-shape`.
  - `tools/` 5, `api/` 30, `patterns/` 7, `addendums/` 14.
  - `examples/` 88, generated from the `//!` headers.
  - 35 hand-written pages use 3tk-era names: `polynode`, `PolyHelper`.
- The README: 69 lines of context notes today. It grows into a real
  README, from `readme-creation-002` and the matryoshka-ztk README (80
  lines).
- The doc comments in `src/`.

## Suggested order

Small steps. Each passes all gates. Each new finding goes into this file.

1. Step 1 — the frame: the hero in the paternitas style, B27. A nav with
   the page groups, empty pages marked "to come". The site builds strict.
2. Step 2 — the page inventory, B28: one line per hand-written
   matryoshka-ztk page, 60 pages, with a verdict: take, rewrite, merge,
   drop. The examples: one line, generated. No page written.
3. Step 3 — rule 2 in `src/`: B1, B2, B3. Three comment lines.
4. Step 4 — the README, first real version, B11: what ztk is, install,
   the first example, "Built on Paternitas" (B10).
5. Then the pages, one group per step, in the inventory's order. The
   errors page (B12) and the pointer page (B13) are early ones.
6. The doc comments, B5, B6, between page groups.
7. The items that need a ruling (L) come one at a time.

## Items

### Comments in `src/`

| id | F | what | size | state |
|---|---|---|---|---|
| B1 | F2.1 | `inner.zig:19` names Paternitas | S | open |
| B2 | F2.2 | `inner.zig:97` names Paternitas, and says how it is built | S | open |
| B3 | F2.3 | `helper.zig:10` names `paternitas.Typed` | S | open |
| B4 | F1.5 | six `//!` headers link to example pages that do not exist | S | open, ruling: keep or remove |
| B5 | F1.1 | `anchor.typeId()` has no ztk doc | S | open |
| B6 | F1.2, F1.3 | `Anchor` and `AnyParent` members: ztk words in the alias `///` and `inner.zig` `//!` | M | open, ruling Q1 |
| B7 | F1.4 | `condition_waitTimeout` is `pub`, internal | S | open, low |
| B8 | — | `NodeKind`, `TypeInfo`, `node_next_offset` reachable, not ztk names | S | open, low |

### Tests, build, negatives

| id | F | what | size | state |
|---|---|---|---|---|
| B9 | F2.4, F2.5 | test comment `layer1_any.zig:202`, build comment `build.zig:57` | S | open, ruling Q3 |
| B15 | F3.3 | two examples numbered 104 | L | open, code, ruling Q4 |
| B16 | F3.6 | `306_no_inner`, `307_two_inners`, `NoInner`, `TwoInners` | L | open, code, ruling Q5 |
| B17 | F1.7 | no negative for `not a struct` or the `fromAny` panic | L | open, code |

### README and site

| id | F | what | size | state |
|---|---|---|---|---|
| B10 | F3.2 | "Built on Paternitas" in rule 2's form | S | open |
| B11 | F3.1, F3.4 | the README is temporary; it grows into a real README, from `readme-creation-002` and the matryoshka-ztk README | L | open, many steps |
| B12 | F1.6 | the errors page: three paternitas messages, ztk meaning and fix | M | open |
| B13 | — | the optional pointer page: own container over Anchors | M | open |
| B14 | F3.5 | `ztk/kitchen/docs/index.md` and the nav | M | open, step 1 |
| B27 | — | hero as paternitas: logo image, two buttons ("Get Started", "N lines of code" to `apidocs/`). ztk has a logo PNG | S | next |
| B28 | — | inventory of the 60 hand-written matryoshka-ztk pages, a verdict each. Examples: one line, generated | M | open, step 2 |
| B29 | — | 35 pages with 3tk names; rewrite in today's names | L | open, after B28 |
| B30 | F4.10 | bring `gen_examples_docs.sh` into `ztk/kitchen/tools/`; run it in the site build; keep the nav in step with `examples/` (rules-050 nav sync) | M | open |
| B31 | — | two examples numbered 104 (B15), in `bridge/` and `layer4/`. The generated pages likely do not clash; the nav labels confuse | — | note |
| B34 | — | each example's `//!` header: "description as code", rules 1 and 2, old words, style. A grep found no paternitas names; old words and style not checked | M | open |
| B32 | — | `hooks/new_tab_links.py`, `fix_md_*` from paternitas's site tools: take for ztk? | S | open |
| B33 | — | site style: the italic name, NAQ blocks, snippets from working code (paternitas DOCS 01, 02): take for ztk? | M | open, ruling |

### Rules and checks

| id | F | what | size | state |
|---|---|---|---|---|
| B18 | F4.1–F4.8 | eight paternitas rules into ztk rules-002 | M | open |
| B19 | F4.15, F4.16 | the two conflicts: example layout, superseded docs | L | open, ruling Q6 |
| B20 | F4.9–F4.14 | ztk rules paternitas dropped: confirm they apply to ztk | M | open |
| B21 | — | z4 in `ztk_gates.sh`, the rule-2 check | M | open, after B1–B3, B9 |
| B22 | — | ztk has no design gate and no context index; applies at ZTK HOME | L | open, ZTK HOME |

### ZTK HOME preparation

| id | H | what | size | state |
|---|---|---|---|---|
| B35 | H1, H2 | two stale pointers in matryoshka-ztk: root STATUS to staging plan 019; next-status to paternitas STATUS | S | next, ZTK PREP 01 |
| B36 | H9 | remove `VERSION` and the two tests "317" that read it | S | next, ZTK PREP 01 |
| B37 | H11, H13 | a ztk gate script in `ztk/kitchen/`, run from `ztk/`; z4 goes there | M | open |
| B38 | H22 | ztk's design notes in `ztk/design/`: design 017's ztk part, plan 003's name table | M | open |
| B39 | H23 | a ztk-only log in `ztk/design/`, from now on, with a summary of ZTK 00 to now | M | open |
| B40 | H14 | no `../` link in ztk text; the README's link becomes a URL | S | open, with B10 |

### Plans and sources

| id | F | what | size | state |
|---|---|---|---|---|
| B23 | F3.7, F5.1 | NEXT's 002 plans use old names; read through plan 003's table | — | note |
| B24 | — | the intent's "Found before" list was out of date; check claims live | — | note |
| B25 | — | plan 003, "Rules for the Matryoshka docs": one item one chain, stale `next`, `next` holds `*Anchor` | M | open |
| B26 | — | carried from ZTK 01: question 4, NEXT's newer README-stage docs | — | open |
