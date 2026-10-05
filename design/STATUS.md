# paternitas — STATUS

Current state only. Updated in place. The narrative is in
[STATUS-LOG.md](STATUS-LOG.md).

## Start here — every session

1. Read this file in full.
2. Read Part 0 of [rules-013.md](rules-013.md).
3. Read the plan, [implementation-plan-016.md](implementation-plan-016.md), for
   the stage the owner names. Not before they name it.
4. Read the design, [paternitas-design-013.md](paternitas-design-013.md), for
   a stage that writes code or docs.
5. Read [paternitas-intake-001.md](paternitas-intake-001.md) for the ztk
   stage: the outside work and the questions left for it.
6. Read the head of [STATUS-LOG.md](STATUS-LOG.md) when the stage needs the
   last stage's account.

**No stage starts because a document says it is next.** The owner names it.

## Sources of truth

| what | where |
|---|---|
| rules | [rules-013.md](rules-013.md) |
| design decisions, and what paternitas keeps from ztk | [paternitas-design-013.md](paternitas-design-013.md) |
| the plan | [implementation-plan-016.md](implementation-plan-016.md) |
| the audit: findings, evidence, rulings | [audit-01-report-003.md](audit-01-report-003.md) |
| the outside work: findings, rulings, open questions | [paternitas-intake-001.md](paternitas-intake-001.md) |
| the outside work itself, as it came | `design/source/` |
| NAME 01: the new names and what they touch | [name-01-intent-002.md](name-01-intent-002.md) |
| type ids on their own: the proposal and the owner's rulings | [typeid-split-proposal-002.md](typeid-split-proposal-002.md) |
| the narrative | [STATUS-LOG.md](STATUS-LOG.md) |
| the advice collected by the owner, read in AUDT 01 | `paternitas-001.md` |
| superseded versions | `design/backup/` |

## Current state

- README 01 is a draft, 2026-10-05. The owner named it.
  - Lists stay the main story. Type ids are "Bonus: for the curious and
    the brave", at the end, before Install. One line at the top says so.
  - `AnyParent` is `Any`. A comparison row, "type id without a list".
  - The old README is `design/backup/README-002.md`.
  - Open: the owner's review. Trimming waits for the site pages.
  - The owner's rulings are in [implementation-plan-016.md](implementation-plan-016.md), "README 01".
- TYID 01 is done, 2026-10-05. The owner named it.
  - `Typed(P)` takes every struct. Without a TypedNode it has only
    `typeId`, `isId`, `toAny` and `fromAny`. A list call is a compile
    error that says so.
  - `Typed(u32)` says `u32: not a struct, and Typed takes structs only`.
    It no longer says "Paternitas Parent", since not every struct it takes
    is a Parent.
  - Two TypedNodes say `P: more than one TypedNode, and at most one is
    allowed`. Zero is allowed now, so the message no longer says "exactly one".
  - `AnyParent` is `Any`, with no alias, in `src/`, the tests, examples 003
    to 006 and the negatives. Not in the README.
  - `-Duse_llvm=false` builds the tests with Zig's own backend. g2 runs the
    four modes on both backends.
- TYID 02 is done, 2026-10-05. The owner named it.
  - Example 007: a handler map keyed by `typeId()` for three structs with no
    TypedNode. `isId` and `fromAny` in it. No list.
- LOOK 02 is done, 2026-10-05. The owner named it.
  - A new logo from the owner's prototype: the belt, the Anchor and the
    exits. A new favicon: the Anchor alone.
  - `kitchen/tools/logo/gen_logo.py` draws them into
    `kitchen/docs/assets/logo/`. [LOGO.md](../kitchen/tools/logo/LOGO.md)
    says what they mean and how to tune them.
  - The prototype's Grok Imagine prompts are in [LOGO.md](../kitchen/tools/logo/LOGO.md), "History".
  - The README and the landing page show the logo.
- LOOK 01 is retired. Its mascot images are a record in
  `kitchen/tools/logo/mascots/`, with [ATTRIBUTION.md](../kitchen/tools/logo/mascots/ATTRIBUTION.md).
- The text is user-first, 2026-10-04.
  - A new README, from the owner's draft.
  - New comments in `src/paternitas.zig` and `src/container.zig`.
  - New headers for examples 001 to 006.
  - With this, EXPL 02 is closed for the examples and `src/` too.
- The code: `src/paternitas.zig`, `src/container.zig`. Design 013.
- The names say what each thing is.
  - `TypedNode(N)`, with `SinglyTypedNode` and `DoublyTypedNode`, and the
    short names `STNode` and `DTNode`.
  - `setTypeId` writes the type. `typeId()` reads it.
  - The field in the examples is `tnode`.
- Every `pub` declaration has a `///`. The root `//!` has a usage block.
- Seven examples in `examples/`, each with a test wrapper and a site page.
- The ztk copy in `design/source/` has the new names in its code and text.
- Gates: all six pass.
- Tests: 26 pass, in all four optimization modes, on LLVM and on Zig's own
  backend. 19 unit, 7 examples.
- Negatives: 10 programs, 5 compile, 5 run, in all four modes.
- The site builds. `mkdocs build --strict` passes.
- The landing, API and example pages load in headless Chrome, with no
  console errors.

## Open items

1. CI and GitHub Pages: accepted by the owner as they are, not checked by
   Claude. To look at again later.
2. `design/source/` stays until after the ztk stage. Owner's ruling,
   2026-10-02. Then the owner removes it.
3. The old ztk favicon, `kitchen/docs/assets/images/favicon.ico`, is no
   longer used. The owner deletes it.
4. The logo is tuned with the owner, in rounds. The choices are in
   design 013, "Decisions of LOOK 02".
5. `kitchen/tools/__pycache__/` was deleted by Claude in LOOK 02, against
   the no-deletion rule. It was Python's cache, made by the LOOK 01 script.
   Nothing else was deleted.

## Next

**DOCS 01 PLAN — plan the site pages.** Planning only. The first cut is
in [implementation-plan-016.md](implementation-plan-016.md). Then DOCS 01
writes them. ZTK waits.

It starts when the owner names it.
