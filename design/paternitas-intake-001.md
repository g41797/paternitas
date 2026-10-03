# paternitas — intake of the outside work (001)

The owner worked several days on another computer, with Claude and ChatGPT.
This file records what came back, what the scan found, and the owner's rulings
of 2026-10-02. It is the state for the stages after ADPT 01.

- Rules: [rules-012.md](rules-012.md).
- Plan: [implementation-plan-012.md](implementation-plan-012.md).

---

## The material

A copy of all of it is in `design/source/`, as it came. The owner removes it
after the paternitas work is done. The originals stay in
`~/Downloads/paternitas-ztk-parent/`.

- `design/source/paternitas-design.md` — the new design.
  - paternitas: Anchor, TypeInfo, Link, `Info(P)`, AnyParent.
  - ztk built on paternitas: the "Matryoshka-ztk changes" section.
- `design/source/paternitas-and-ztk/paternitas/` — the code.
  - `src/paternitas.zig`: 415 lines, 9 inline tests.
  - `src/container.zig`: 95 lines. `TypeInfo`, `NodeKind`,
    `uniform_next_offset`.
  - `build.zig`: steps `test` and `negative`.
  - `negative/compile/`: 4 programs. `negative/panic/`: 3 programs.
  - No README, docs, examples, kitchen or CI.
- `design/source/paternitas-and-ztk/ztk/` — matryoshka-ztk's NEXT tree,
  moved onto paternitas.
  - Depends on paternitas by `.path = "../paternitas"`.
  - Not used before the ztk stage.

---

## Scan findings

Facts from the first read. The audit (AUDT 01) checks each one.

- **F1. Two halves.**
  - This repo has the skeleton: kitchen, mkdocs, CI, five gates, placeholder
    sources.
  - The outside paternitas has real code and none of the skeleton.
- **F2. Negative count.** The design says `zig build negative` passes 11/11.
  The tree has 7 programs: 4 compile, 3 panic.
- **F3. Tests are inline** in `src/paternitas.zig`. Here, tests live in
  `tests/` with `std.testing.log_level = .debug`.
- **F4. Two ztk copies differ.**
  - The outside ztk is moved onto paternitas.
  - The local `ZTK/design/secondary/lang/port/3tk-to-ztk/next/ztk` is not.
  - The local one has newer docs the outside one lacks:
    `comments-creation-002`, `readme-creation-002`, `README-001`,
    `design/backup/`.
- **F5. `ztk/root`** is a 5.9 MB data file. The local git shows it deleted in
  NEXT.
- **F6. Stale site output in ztk.** `docs/` and `kitchen/docs/` still have
  `examples/items/`. The sources moved to `examples/parents/`.
- **F7. Rules language.** The new design uses words that Part 4 of the rules
  bans or flags. In `design/` it is rewritten in rules style.
- **F8. Small API points.**
  - `Link(N)` is public and accepts any `N`. Its `kind` is `.double` for any
    type that is not the singly linked Node.
  - The design's API block says `fn`. The code says `inline fn`.
  - The design names `src/paternitas.zig` as the source of truth.
    `container.zig` is not named.
- **F9. Panic checks differ.**
  - paternitas' panic programs check the stderr text.
  - ztk's check only the abort signal.
- **F10. `paternitas-001.md`**, the advice the owner collected, 1545 lines. Not
  read yet. AUDT 01 reads it.
- **F11. ADPT 01** was open: part 3, CI, and the close. Closed on 2026-10-02,
  per D4.

---

## Owner's rulings, 2026-10-02

- **D1. Order.** paternitas only, until it is done.
  - Then ztk, built on it.
  - The ztk stage may need paternitas fixes. The work goes in rounds: ztk,
    paternitas fix, ztk.
  - The ztk questions wait for that stage. See "Open for the ztk stage".
- **D2. Where.** The outside paternitas replaces the placeholders in this
  repo. It is merged into the skeleton.
- **D3. Design sources.** Both are reconciled.
  - The outside design comes first.
  - From `paternitas-001.md`, take only what the outside design lacks.
- **D4. ADPT 01.** Closed now.
  - CI and CD are accepted as they are. They may be looked at again later.
  - Part 3 is closed as "accepted by the owner, not checked by Claude".
- **D5. No remote git.** Rules 004, Part 0.
  - No git command that reaches a remote.
  - No `gh`: no runs, no PRs, no issues, no API.
  - Claude reads sources in the owner's local repos. It runs no commands there.
  - Plain `git status` in this repo stays the one exception.
- **D5a. State in the owner's files.** Rules 004, Part 0 and Part 1 step 12.
  - Every stage saves all it learns in the owner's `.md` files: findings,
    answers, decisions, plans, open questions.
  - Never in Claude memory.
  - The intent file is written when the answers arrive, not at close.
  - Every stage ends with how to continue after a clear, and the model to use.
- **D6. The copy.** All of `~/Downloads/paternitas-ztk-parent/` goes to
  `design/source/`, as is.
  - The gate's banned-word check skips `design/source/`.
  - The owner removes the folder after the paternitas work.
- **D7. The stages.** AUDT 01, then PTRN 01, then PTRN 02. Charters in the
  plan.
- **D8. Examples.** ztk style. Claude picks which missing examples to add.
- **D9. `build.zig.zon`.** This repo's fingerprint and version `0.0.0` stay.
- **D10. Model.** Opus for every stage. Fable only if a design step asks for
  it.

---

## Open for the ztk stage

- Which ztk copy is the base: the outside one, the local NEXT one, or the
  outside one with the local `-002` docs merged in.
- Where ztk lives: the matryoshka-ztk repo root, or NEXT for now.
- The dependency form: a local path while fixes go in rounds, a URL with a
  hash later. The relative path on disk.
- `ztk/root`: remove, with the owner's approval.
- The stale site output, F6.
