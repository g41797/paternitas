# ZTK 00 — intent (001)

The stage: ztk on paternitas, set up and surveyed. Charter:
[implementation-plan-022.md](implementation-plan-022.md), "ZTK — later".
Design: [paternitas-design-015.md](paternitas-design-015.md), "ztk on paternitas".

Owner's ruling, 2026-10-22: the ZTK stages run in this repo. Writes to the
matryoshka-ztk repo are allowed, with the owner's permission each time.

Status: waiting for the owner's approval. No code moves before it.

---

## What is known

- The base: `design/source/paternitas-and-ztk/ztk`.
  - 2154 lines in `src/`, 19 test files, about 80 examples, negatives.
  - Its `build.zig.zon` points at `../paternitas`, the outside copy.
- Against this repo it fails on one line: `src/inner.zig:59`,
  `paternitas.AnyParent`. The name is `Any` now.
- With that one line changed, in a scratch copy: 198/199 tests pass, 1 skipped.
  Debug only. Other modes and negatives not run.
- `AnyParent` is still ztk's own name in five places: `src/inner.zig:59`, `:107`,
  `src/helper.zig:136`, `:143`, `:243`.
- `ztk/root` (intake F5) is not in this copy. Nothing to decide.
- No `Inner`, `OuterId`, `OuterInfo`, `AnyOuter` left in `src`, `tests`,
  `examples`.
- The NEXT tree in matryoshka-ztk moved on with the backport. It has no
  paternitas stage. The two have not been compared.

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

Survey: this copy against NEXT.

- Source: `matryoshka-ztk/design/secondary/lang/port/3tk-to-ztk/next/ztk/`.
- File by file: `src/`, `tests/`, `examples/`, `negative/`, `build.zig`.
- For each difference: what it is, and a proposal: take now, take later, drop.
- The outcome: `design/ztk-00-survey-001.md`. The owner decides per row.
- Read only. Nothing in matryoshka-ztk changes.

The outside plan.

- `design/source/paternitas-design.md`, "Matryoshka-ztk changes", line 1084.
- It predates NAME 01, AUDT 01, TYID. Its names are old.
- A current copy goes in `design/ztk-plan-001.md`: today's API names, and what
  the copy already did is marked done.

Status files.

- `STATUS.md`: a ZTK section. Current state and next only.
- Plan: `implementation-plan-023.md`. ZTK stages named. 022 to `design/backup/`.
- `STATUS-LOG.md`: one entry per stage, as now.
- matryoshka-ztk `next-status.md`: a pointer to this repo. The owner's write,
  or a session's with permission.

---

## Later stages, named here, not started

- **ZTK 01 — green.** The `AnyParent` decision for ztk. Green in all four modes
  and negatives.
- **ZTK 02 … — the plan.** `ztk-plan-001.md`, file by file. Rounds: ztk,
  paternitas fix, ztk.
- **ZTK — survey rows.** The NEXT changes the owner took.
- **ZTK — docs.** README, doc comments, site, ztk style.
- **ZTK — home.** ztk moves to matryoshka-ztk and is merged with NEXT there.
  Then the owner removes `design/source/` and `ztk/`.

---

## Questions

1. `ztk/` at the repo root — or another name or place?
2. ztk's own `AnyParent`: rename to `Any` in ZTK 01, or keep the ztk alias?
3. Survey depth: file list and summaries, or line diffs per file?
