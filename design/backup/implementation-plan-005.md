# paternitas — Implementation plan (005)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-004.md](rules-004.md).
- Design decisions: [paternitas-design-003.md](paternitas-design-003.md).
- The outside work and the owner's rulings of 2026-10-02:
  [paternitas-intake-001.md](paternitas-intake-001.md).
- Change from 004: ADPT 01 is closed. The stages for the outside paternitas
  code are added: AUDT 01, PTRN 01, PTRN 02.

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

---

## Order

paternitas first, until it is done. Then ztk, built on it. The ztk stage may
need paternitas fixes; the work then goes in rounds. Intake, D1.

```text
AUDT 01  ->  PTRN 01  ->  PTRN 02  ->  ZTK ...  <->  PTRN fixes
```

---

## AUDT 01 — audit and design

Model: Opus 5.5. The stage writes the design every later stage runs on.

No code changes in this repo.

- Build and run the outside paternitas:
  `design/source/paternitas-and-ztk/paternitas`.
  - In a scratch copy, not in `design/source/`.
  - All four modes. Steps `test` and `negative`.
- Check the outside design against its code.
  - Start from intake findings F2, F3, F8, F9.
  - Every API entry: present, as described, tested.
  - Every claim of the design: true of the code.
- Read `paternitas-001.md`. Take only what the outside design lacks. Intake,
  D3.
- Output.
  - `design/audit-01-report-NNN.md`, from 001.
    - The findings, ranked, each with a proposed fix.
    - The owner rules on each.
  - `paternitas-design-NNN.md`, the next version, in rules style.
    - It absorbs the outside design.
    - It keeps what design 003 records. 003 moves to `backup/`.

## PTRN 01 — the code

Model: Opus 5.5.

- `src/paternitas.zig` and `src/container.zig` from the outside code, with the
  fixes the owner approved in AUDT 01. They replace the placeholders.
- The inline tests move to `tests/`, with `std.testing.log_level = .debug`.
- `negative/compile/` and `negative/panic/`, and the `negative` build step.
  - Gate 6 in `kitchen/gates.sh`, in all four modes.
  - Rules: Part 0 lists six gates.
- `build.zig.zon` keeps this repo's fingerprint and version `0.0.0`. Intake,
  D9.
- All gates pass, cross-compile included.

## PTRN 02 — docs and examples

Model: Opus 5.5.

- `///` and `//!` on every `pub` declaration, per rules Part 3. The rendered
  page is checked.
- `README.md` replaces `WIP`.
- Examples in ztk style, each with a test wrapper and a generated page.
  - The design's two: a DLink Parent in a timeout list, and dispatch through a
    `TypeId -> handler` map.
  - Others Claude picks, from what the audit shows is not shown yet. Intake,
    D8.
- `build_site.sh`, and `mkdocs build --strict` passes.

## ZTK — later

In the matryoshka-ztk repo. The owner names it. The open questions are in the
intake file, "Open for the ztk stage".

---

## Deferred

- **CI and Pages.** Accepted by the owner as they are, 2026-10-02. To look at
  again later.
- **`design/source/`.** The owner removes it after the paternitas work.
