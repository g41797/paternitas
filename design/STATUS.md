# paternitas — STATUS

Current state only. Updated in place. The narrative is in
[STATUS-LOG.md](STATUS-LOG.md).

## Start here — every session

1. Read this file in full.
2. Read Part 0 of [rules-003.md](rules-003.md).
3. Read the plan, [implementation-plan-004.md](implementation-plan-004.md), for
   the stage the owner names. Not before they name it.
4. Read the head of [STATUS-LOG.md](STATUS-LOG.md) when the stage needs the
   last stage's account.

**No stage starts because a document says it is next.** The owner names it.

## Sources of truth

| what | where |
|---|---|
| rules | [rules-003.md](rules-003.md) |
| design decisions, and what paternitas keeps from ztk | [paternitas-design-003.md](paternitas-design-003.md) |
| the plan | [implementation-plan-004.md](implementation-plan-004.md) |
| the narrative | [STATUS-LOG.md](STATUS-LOG.md) |
| the advice collected by the owner — not read until after ADPT 01 | `paternitas-001.md` |
| superseded versions | `design/backup/` |

## Current state

- INTR 15 is done, 2026-09-25. The development process lives here now.
- The sources are placeholders. They implement nothing.
- Gates: all five pass.
- Tests: 2 pass, in all four optimization modes.
  - `tests/paternitas_tests.zig`: 1.
  - `tests/examples_tests.zig`: 1.
- Cross-compile passes for x86_64-macos, aarch64-macos, x86_64-windows.
- The site builds, and `mkdocs build --strict` passes.
- CI has not run yet. The owner pushes.

## Open items

1. GitHub Pages must be set to deploy from GitHub Actions. Owner's action.

## Next

**ADPT 01 — adaptation.** Opus 5.5. The charter is in
[implementation-plan-004.md](implementation-plan-004.md).

- In progress. The owner's answers are in
  [adpt-01-intent-002.md](adpt-01-intent-002.md).
- Parts 1 and 2 now. Part 3 after the owner's push.
