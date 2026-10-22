# ZTK 00 — intent and the owner's answers (003)

The stage: ztk on paternitas, set up and checked. Charter:
[implementation-plan-025.md](implementation-plan-025.md), "ZTK".
Design: [paternitas-design-017.md](paternitas-design-017.md), "ztk on paternitas".

Owner's ruling, 2026-10-22: the ZTK stages run in this repo. Writes to the
matryoshka-ztk repo are allowed, with the owner's permission each time.

Change from 002: the later stages moved to the plan,
[implementation-plan-025.md](implementation-plan-025.md), "ZTK". This file is
ZTK 00 only.

Change from 001, kept: the owner's answers. The NEXT survey shrinks to a light
check. `AnyParent` stays in ztk.

Status: closed by the owner, 2026-10-22.

---

## What is known

- The base: `design/source/paternitas-and-ztk/ztk`.
  - 2154 lines in `src/`, 19 test files, about 80 examples, negatives.
  - Its `build.zig.zon` points at `../paternitas`, the outside copy.
- Against this repo it fails on one line: `src/inner.zig:59`,
  `paternitas.AnyParent`. The name is `Any` now.
- With that one line changed, in a scratch copy: 198/199 tests pass, 1 skipped.
  Debug only. Other modes and negatives not run.
- `ztk/root` (intake F5) is not in this copy.
- No `Inner`, `OuterId`, `OuterInfo`, `AnyOuter` left in `src`, `tests`,
  `examples`.
- NEXT: the live ztk, `matryoshka-ztk/design/secondary/lang/port/3tk-to-ztk/next/ztk/`.
  - Newest file and last commit: 2026-09-21. The copy came after it.
  - 139 files differ. In `src/`, the move onto paternitas: `internal/info.zig`
    gone; `inner`, `helper`, `queue`, `stack`, `mbox`, `pool`, `matryoshka`
    changed.
- `Anchor.toAny` answers `?Any` now: null when `setTypeId` was never called.
  ztk's `anyFromSlot` builds, but it answers null in that case too.

---

## The owner's answers

1. The working folder: `ztk/` at the repo root.
2. `AnyParent` stays a ztk name. It is not renamed to `Any`.
   - Why: a ztk parent always has a TypedNode. ParentHelper refuses zero or
     two. paternitas `Any` covers any struct, with or without one.
   - Same struct, `{ ptr, type_id }`. A narrower promise.
   - No ztk call takes an `AnyParent` into a container. A wrapper struct waits
     until one does.
3. The NEXT survey becomes a light check. NEXT did not move after the copy.

---

## The intent

Working folder.

- New folder `ztk/` at the repo root. A copy of
  `design/source/paternitas-and-ztk/ztk`.
- `design/source/` is not edited. It stays, owner's ruling 2026-10-02.
- `ztk/` does not ship: paternitas `build.zig.zon` `.paths` lists only
  `build.zig`, `build.zig.zon`, `src`.
- `ztk/build.zig.zon`: the paternitas dependency becomes `.path = ".."`.
- Not copied: stale site output, `docs/` and `kitchen/docs/` build leftovers
  (intake F6). The list is shown before the copy.

Gates.

- New `kitchen/ztk_gates.sh`. Separate from `kitchen/gates.sh`.
  - Build and test, all four modes.
  - `zig build negative`, all four modes.
  - fmt.
- A paternitas fix during ZTK: both scripts pass.
- `kitchen/gates.sh` does not look into `ztk/`. Checked, fixed if it does.

The NEXT check.

- Record: NEXT unchanged since 2026-09-21. The copy has all of it.
- The list of differing files. Each one marked: the paternitas move, or other.
- "Other" goes to the owner.
- No line diffs. No take / later / drop.
- The outcome: a section in the ZTK 00 log entry. No separate file.
- Read only. Nothing in matryoshka-ztk changes.
- Before ZTK — home: check NEXT's date again. If it moved, compare again.

The outside plan.

- `design/source/paternitas-design.md`, "Matryoshka-ztk changes", line 1084.
- It predates NAME 01, AUDT 01, TYID. Its names are old.
- A current copy goes in `design/backup/ztk-plan-002.md`: today's API names, and what
  the copy already did is marked done.

Status files.

- `STATUS.md`: a ZTK section. Current state and next only.
- Plan: [implementation-plan-025.md](implementation-plan-025.md). One line under "Completed stages" when ZTK 00 closes.
- `STATUS-LOG.md`: one entry per stage, as now.
- matryoshka-ztk: the next-status and next-log files, pointer written,
  2026-10-22, with the owner's permission.

---

## After ZTK 00

The next stages are in the plan,
[implementation-plan-025.md](implementation-plan-025.md), "ZTK".
