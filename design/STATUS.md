# paternitas — STATUS

Current state only. Updated in place. The narrative is in
[STATUS-LOG.md](STATUS-LOG.md).

## Start here — every session

1. Read this file in full.
2. Read Part 0 of [rules-006.md](rules-006.md).
3. Read the plan, [implementation-plan-009.md](implementation-plan-009.md), for
   the stage the owner names. Not before they name it.
4. Read the design, [paternitas-design-009.md](paternitas-design-009.md), for
   a stage that writes code or docs.
5. Read [paternitas-intake-001.md](paternitas-intake-001.md) for the ztk
   stage: the outside work and the questions left for it.
6. Read the head of [STATUS-LOG.md](STATUS-LOG.md) when the stage needs the
   last stage's account.

**No stage starts because a document says it is next.** The owner names it.

## Sources of truth

| what | where |
|---|---|
| rules | [rules-006.md](rules-006.md) |
| design decisions, and what paternitas keeps from ztk | [paternitas-design-009.md](paternitas-design-009.md) |
| the plan | [implementation-plan-009.md](implementation-plan-009.md) |
| the audit: findings, evidence, rulings | [audit-01-report-003.md](audit-01-report-003.md) |
| the outside work: findings, rulings, open questions | [paternitas-intake-001.md](paternitas-intake-001.md) |
| the outside work itself, as it came | `design/source/` |
| the narrative | [STATUS-LOG.md](STATUS-LOG.md) |
| the advice collected by the owner, read in AUDT 01 | `paternitas-001.md` |
| superseded versions | `design/backup/` |

## Current state

- PTRN 02 is done, 2026-10-02.
- The code: `src/paternitas.zig`, `src/container.zig`. Design 009.
- Every `pub` declaration has a `///`. The root `//!` has a usage block.
- `Info(P)` is now `Typed(P)`. The examples put the types first.
- The README, the comments and the source order are written for the user.
  Rules 006, design 009.
- Six examples in `examples/`, each with a test wrapper and a site page.
- The README replaces `WIP`.
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
[implementation-plan-009.md](implementation-plan-009.md). The owner names the
model. Claude's proposal: Opus 5.5, since it writes the README and site text
around the picture. It starts when the owner names it.
