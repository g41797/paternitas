# paternitas — STATUS

Current state only. Updated in place. The narrative is in
[STATUS-LOG.md](STATUS-LOG.md).

## Start here — every session

1. Read this file in full.
2. Read Part 0 of [rules-010.md](rules-010.md).
3. Read the plan, [implementation-plan-012.md](implementation-plan-012.md), for
   the stage the owner names. Not before they name it.
4. Read the design, [paternitas-design-011.md](paternitas-design-011.md), for
   a stage that writes code or docs.
5. Read [paternitas-intake-001.md](paternitas-intake-001.md) for the ztk
   stage: the outside work and the questions left for it.
6. Read the head of [STATUS-LOG.md](STATUS-LOG.md) when the stage needs the
   last stage's account.

**No stage starts because a document says it is next.** The owner names it.

## Sources of truth

| what | where |
|---|---|
| rules | [rules-010.md](rules-010.md) |
| design decisions, and what paternitas keeps from ztk | [paternitas-design-011.md](paternitas-design-011.md) |
| the plan | [implementation-plan-012.md](implementation-plan-012.md) |
| the audit: findings, evidence, rulings | [audit-01-report-003.md](audit-01-report-003.md) |
| the outside work: findings, rulings, open questions | [paternitas-intake-001.md](paternitas-intake-001.md) |
| the outside work itself, as it came | `design/source/` |
| NAME 01: the new names and what they touch | [name-01-intent-002.md](name-01-intent-002.md) |
| the narrative | [STATUS-LOG.md](STATUS-LOG.md) |
| the advice collected by the owner, read in AUDT 01 | `paternitas-001.md` |
| superseded versions | `design/backup/` |

## Current state

- EXPL 02 is done, 2026-10-03. The README names the two uses: "One list,
  many types" and "Pass it on, handle by type". The second passes an
  `AnyParent`. `*Anchor` is for container authors.
- EXPL 01 is done, 2026-10-03. The README and the module header say what
  "intrusive" and "type-erased" mean, and when you need paternitas.
- NAME 01 is done, 2026-10-03.
- The code: `src/paternitas.zig`, `src/container.zig`. Design 011.
- The names say what each thing is.
  - `TypedNode(N)`, with `SinglyTypedNode` and `DoublyTypedNode`, and the
    short names `STNode` and `DTNode`.
  - `setTypeId` writes the type. `typeId()` reads it.
  - The field in the examples is `tnode`.
- Every `pub` declaration has a `///`. The root `//!` has a usage block.
- Six examples in `examples/`, each with a test wrapper and a site page.
- The ztk copy in `design/source/` has the new names in its code and text.
- Gates: all six pass.
- Tests: 22 pass, in all four optimization modes. 16 unit, 6 examples.
- Negatives: 9 programs, 5 compile, 4 run, in all four modes.
- The site builds. `mkdocs build --strict` passes.
- The API and example pages load in headless Chrome, with no console errors.

## Open items

1. CI and GitHub Pages: accepted by the owner as they are, not checked by
   Claude. To look at again later.
2. `design/source/` stays until after the ztk stage. Owner's ruling,
   2026-10-02. Then the owner removes it.

## Next

**LOOK 01 — the picture and the logo.** The charter is in
[implementation-plan-012.md](implementation-plan-012.md). The owner names the
model. Claude's proposal: Opus 5.5, since it writes the README and site text
around the picture.

It starts when the owner names it.
