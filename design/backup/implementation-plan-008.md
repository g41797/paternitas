# paternitas — Implementation plan (008)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-005.md](rules-005.md).
- Design: [paternitas-design-006.md](paternitas-design-006.md).
- The audit and the owner's rulings:
  [audit-01-report-003.md](audit-01-report-003.md).
- The outside work: [paternitas-intake-001.md](paternitas-intake-001.md).
- Change from 007: PTRN 01 is closed. Its account is in
  [STATUS-LOG.md](STATUS-LOG.md). PTRN 02 takes its open points.
- Change from 006, kept: the owner's rulings on ChatGPT's review of design
  004. Notes for the ztk stage.

**No stage starts because this plan says it is next.** The owner names it.

---

## Completed stages

- INTR 15 (2026-09-25, Opus 5.5) — the development process moved from next/ztk
  into paternitas: rules, design doc, placeholder skeleton, kitchen, site, CI.
  Five gates green.
- ADPT 01 (2026-10-02, Opus 5.5) — the workflow tuned: rules 003 and 004,
  `kitchen/gates.sh`, the full banned list in the gate, the hard-break fixer,
  the Examples button. CI accepted by the owner, not checked by Claude. Five
  gates green.
- AUDT 01 (2026-10-02, Opus 5.5) — the outside paternitas built and checked
  in all four modes; findings A1 to A14 and T1 to T7 ruled; design 004. A1:
  two types shared one TypeId in release modes. Five gates green.
- PTRN 01 (2026-10-02, Opus 5.5) — the outside code ported, with A1, A3,
  A11, T6, A15. 17 tests and 9 negatives in all four modes. Gate 6. Six gates
  green.

---

## Order

paternitas first, until it is done. Then ztk, built on it. The ztk stage may
need paternitas fixes; the work then goes in rounds. Intake, D1.

```text
PTRN 01  ->  PTRN 02  ->  LOOK 01  ->  ZTK ...  <->  PTRN fixes
```

---

## PTRN 02 — docs and examples

Model: Opus 5.5.

- `///` and `//!` on every `pub` declaration, per rules Part 3. The rendered
  page is checked.
  - A4: `Link(N).Node`, `kind`, `node_next_offset`, `Info(P).Node`,
    `nameOf`, `SLink`, `DLink`, the `AnyParent` fields, `TypeInfo._tag`.
- `README.md` replaces `WIP`.
- Examples in ztk style, each with a test wrapper and a generated page.
  - The design's two: a DLink Parent in a timeout list, and dispatch through a
    `TypeId -> handler` map.
  - Others Claude picks, from what is not shown yet. Intake, D8.
- `build_site.sh`, and `mkdocs build --strict` passes.
- From PTRN 01: `Link(N)`'s fields `node` and `anchor` get a `///`.

## LOOK 01 — the picture and the logo

Model: to be named by the owner. AUDT 01, T7. The stage name is a proposal.

- The mask picture from `paternitas-001.md`: the list sees the mask, the
  helper recognizes who is behind it.
- The logo idea: two masked Zig mascots and a thin thread.
- The README, the site, the favicon.

## ZTK — later

In the matryoshka-ztk repo. The owner names it.

- The plan, file by file: design 005, "ztk on paternitas", and the outside
  design's section it points to.
- The vocabulary: design 005, "ztk on paternitas". No mechanical rename.
- `ParentHelper` stays. Design 005.
- The checkpoint: run the whole ztk suite after the containers are moved, not
  before. Before that, Queue, stack, Mbox and Pool do not build.
- AUDT 01, A11: ztk reads the id as `anchor.typeId()`.
- The open questions: the intake, "Open for the ztk stage".

---

## Deferred

- **CI and Pages.** Accepted by the owner as they are, 2026-10-02. To look at
  again later.
- **`design/source/`.** It stays until after the ztk stage. Owner's ruling,
  2026-10-02. Then the owner removes it.
  - Reason: design 005 points to the outside design's ztk section in it.
  - It replaces intake D6, "after the paternitas work".
