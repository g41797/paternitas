# paternitas — Implementation plan (006)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-004.md](rules-004.md).
- Design: [paternitas-design-004.md](paternitas-design-004.md).
- The audit and the owner's rulings:
  [audit-01-report-003.md](audit-01-report-003.md).
- The outside work: [paternitas-intake-001.md](paternitas-intake-001.md).
- Change from 005: AUDT 01 is closed. PTRN 01 carries the approved fixes. The
  picture and the logo get a stage of their own, after PTRN 02.

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

---

## Order

paternitas first, until it is done. Then ztk, built on it. The ztk stage may
need paternitas fixes; the work then goes in rounds. Intake, D1.

```text
PTRN 01  ->  PTRN 02  ->  LOOK 01  ->  ZTK ...  <->  PTRN fixes
```

---

## PTRN 01 — the code

Model: Opus 5.5. It writes the code every later stage runs on.

The port.

- `src/paternitas.zig` and `src/container.zig` from the outside code. They
  replace the placeholders.
- The code meets rules Part 2. Report A13.
  - Imports at the bottom, `std` last.
  - Explicit types. `ptr.*.field`.
- `build.zig.zon` keeps this repo's fingerprint and version `0.0.0`. Intake,
  D9.

The approved fixes. Report 003, design 004.

- A1: `Info(P)` has a private `var tag: u8`. `TypeInfo` gets `_tag: *const
  u8` as its first field. The descriptor stays `const`.
- A3: `Link(N)` is a compile error for any `N` other than the two std Nodes.
- A11: `Anchor.type_id` becomes `_type_id`. `Anchor.typeId()` reads it.
  - The `///` of `_type_id` and `AnyParent` say who writes them.
- T6: `Info(P).is` takes `*const Node`.

Tests.

- The 9 inline tests move to `tests/`, with `std.testing.log_level = .debug`.
  - The test helper `Chain` gets its own check. `check` is not `pub`.
- The tests that AUDT 01 adds. Design 004, "Tests".
  - A1: two modules with the same root file name and type name. The build
    gets two small test modules for it.

Negatives.

- `negative/compile/` and `negative/panic/`, and the `negative` build step.
- The seven outside programs, with A9: `wrong_node` matches only
  "found '*DoublyLinkedList.Node'".
- Added: A3 compile negative; A5 `fromAny` panic negative that knows the
  mode.
- Gate 6 in `kitchen/gates.sh`: `negative`, in all four modes, on the host.
  - Rules: Part 0 lists six gates.

All gates pass, cross-compile included.

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

## LOOK 01 — the picture and the logo

Model: to be named by the owner. AUDT 01, T7. The stage name is a proposal.

- The mask picture from `paternitas-001.md`: the list sees the mask, the
  helper recognizes who is behind it.
- The logo idea: two masked Zig mascots and a thin thread.
- The README, the site, the favicon.

## ZTK — later

In the matryoshka-ztk repo. The owner names it.

- The plan, file by file: design 004, "ztk on paternitas", and the outside
  design's section it points to.
- AUDT 01, A11: ztk reads the id as `anchor.typeId()`.
- The open questions: the intake, "Open for the ztk stage".

---

## Deferred

- **CI and Pages.** Accepted by the owner as they are, 2026-10-02. To look at
  again later.
- **`design/source/`.** It stays until after the ztk stage. Owner's ruling,
  2026-10-02. Then the owner removes it.
  - Reason: design 004 points to the outside design's ztk section in it.
  - It replaces intake D6, "after the paternitas work".
