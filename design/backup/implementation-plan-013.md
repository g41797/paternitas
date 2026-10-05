# paternitas — Implementation plan (013)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-013.md](rules-013.md).
- Design: [paternitas-design-012.md](paternitas-design-012.md).
- The audit and the owner's rulings:
  [audit-01-report-003.md](audit-01-report-003.md).
- The outside work: [paternitas-intake-001.md](paternitas-intake-001.md).
- Change from 012: LOOK 01 is closed, and its section is gone. Its account
  is in [STATUS-LOG.md](STATUS-LOG.md). The four user-first passes of
  2026-10-04 get one line under "Completed stages".
- Change from 011, kept: EXPL 02 is closed. Its account is in
  [STATUS-LOG.md](STATUS-LOG.md).
- Change from 010, kept: EXPL 01 is closed. Its account is in
  [STATUS-LOG.md](STATUS-LOG.md).
- Change from 009, kept: NAME 01 is closed.
- Change from 008, kept: PTRN 02 is closed.
- Change from 007, kept: PTRN 01 is closed.
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
- PTRN 02 (2026-10-02, Opus 5.5) — the `///` pass, a usage block in the root
  `//!`, six examples, the README. 22 tests in all four modes. Six gates
  green. `mkdocs build --strict` passes.
- NAME 01 (2026-10-03, Opus 5.5) — names that say what each thing is: `Link`
  is now `TypedNode`, and `stamp` is now `setTypeId`. Design 011, rules 007.
  The ztk copy follows. 22 tests in all four modes. Six gates green.
- EXPL 01 (2026-10-03, Opus 5.5) — the README and the module header say
  what "intrusive" and "type-erased" mean, and the README says when you
  need paternitas. Four examples get one line each. Six gates green.
- EXPL 02 (2026-10-03, Opus 5.5) — the README names the two uses. The
  second one passes an `AnyParent`. `*Anchor` goes to container authors.
  003, 004 and 005 carry `AnyParent`. Design 011. Six gates green.
- User-first text (2026-10-04, Opus 5.5) — a new README from the owner's
  draft. The comments in `src/paternitas.zig` and `src/container.zig`, and
  the headers of examples 001 to 006, were rewritten for the user. Not a
  named stage. Six gates green.
- LOOK 01 (2026-10-04, Opus 5.5) — the logo, the mask picture and the
  favicon, from Zero and Ziggy, with
  [ATTRIBUTION.md](../kitchen/docs/assets/logo/ATTRIBUTION.md). The README
  and the landing page show them. Run by Claude alone, at the owner's request.
  Design 012. Six gates green.

---

## Order

paternitas first, until it is done. Then ztk, built on it. The ztk stage may
need paternitas fixes; the work then goes in rounds. Intake, D1.

```text
PTRN 01  ->  PTRN 02  ->  NAME 01  ->  EXPL 01  ->  EXPL 02  ->  LOOK 01  ->  ZTK ...  <->  PTRN fixes
```

---

## ZTK — later

In the matryoshka-ztk repo. The owner names it.

- The plan, file by file: design 005, "ztk on paternitas", and the outside
  design's section it points to.
- The vocabulary: design 005, "ztk on paternitas". No mechanical rename.
- NAME 01 gave the ztk copy in `design/source/` the new names: `TypedNode`,
  `setTypeId`, `_tnode`. The ztk repo needs the same change.
- NAME 01 also changed `paternitas.Info` to `Typed` in the copy's
  `src/helper.zig`, at the owner's request.
- At the owner's request, NAME 01 also brought the copy up to the current
  API, so it builds against this repo.
  - Each read of `anchor.type_id` is now `anchor.typeId()`. AUDT 01, A11.
  - `paternitas.nameOf(found)` is now `found.typeName()`, in
    `src/helper.zig`.
  - It builds and passes in all four modes, with `../paternitas` linked to
    this repo in a scratch copy. 198 of 199 tests pass in each mode. One
    skips by design.
  - `zig build negative` passes in all four modes: 5 compile and 14 panic
    programs. The `safe_only` panic cases run in Debug and ReleaseSafe
    only, as ztk's `build.zig` says.
  - The cross build passes in Debug: x86_64-macos, aarch64-macos,
    x86_64-windows.
- The copy's `build.zig.zon` points at `../paternitas`, the outside copy,
  not at this repo.
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
