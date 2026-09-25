# paternitas — Design (003)

The versioned design document: decisions, their reasons, and the owner's
rulings.

Change from 002: the decisions of ADPT 01, and the rules file is 003.

- Current state is not here. It is in [STATUS.md](STATUS.md).
- The narrative is not here. It is in [STATUS-LOG.md](STATUS-LOG.md).
- The rules are in [rules-003.md](rules-003.md).
- A big task gets its own versioned `.md` under `design/`, linked from here.

---

## Purpose

paternitas is the repo for ztk code that deserves special attention.

- All functionality is allowed here.
- A session works here without access to the ztk files.
- paternitas still knows about ztk, through the paths in **What paternitas
  keeps from ztk** below.
- What the package is, in the owner's words, is still open. The advice the
  owner collected is in `paternitas-001.md`. It is read after ADPT 01, not
  before.

---

## Decisions of INTR 15

INTR 15 moved the development process from next/ztk into paternitas. Owner's
rulings, 2026-09-25.

### Q1 — the rules file

- The rules file is a trimmed copy of `ZTK/design/rules-050.md`.
- Kept: Part 0 adapted, Zig style, comments and autodoc, banned words, writing
  documents.
- Dropped: the Master pattern, stories, dispatch, Matryoshka's invariants.
- Added: the git rules.
  - `git status` is the only git command a session runs.
  - A plain `mv` replaces `git mv`.
- It links back to the source rules, with a note that their version may have
  moved on.
- Reason: the process rules are what carries over. The Matryoshka-specific
  rules describe a toolkit paternitas is not.

### Q2 — the layout

- The same shape as next/ztk.
  - `build.zig`, `build.zig.zon`, module `paternitas`.
  - `src/`, `tests/`, `examples/`, each with a placeholder file.
  - `kitchen/` for the gate scripts, the site tools and the site sources.
  - `design/` for the documents.
- **No `negative/` and no gate 6 for now.**
  - Deferred to the first stage where paternitas refuses something: a compile
    error, or a panic in safe builds.
  - Reason: there is nothing to refuse yet. A gate with no cases proves
    nothing.

### Q3 — ztk knowledge

- paternitas keeps paths into the ztk sources, never copies.
- What it keeps is ztk's smell, process, mantra and intent. See the section
  below.
- Reason: a copy rots. A path points at the current text.

### Q4 — process audit

- Two passes.
  - INTR 15 does a quick pass before the first rules file is written. It fixes what
    is clearly wrong or outdated. The findings are in `STATUS-LOG.md`, under
    INTR 15.
  - ADPT 01 goes deeper and tunes the workflow.

### Q5 — the site

- The same structure as next/ztk: an mkdocs landing page, plus `zig build docs`
  for the API docs.
- Placeholder content.
  - Title "paternitas".
  - One line from the owner's text.
    - The line is "Paternitas". Owner's ruling, 2026-09-25.
    - It replaced a proposed sentence from `paternitas-001.md`.
  - A badge that links to `apidocs/`.
  - No logo yet.
- The API docs are generated from the placeholder sources.

### Q6 — CI

- Every `.github` workflow of matryoshka-ztk is copied: linux, mac, windows,
  docs (GitHub Pages).
- Each is adapted to paternitas' names and paths.
- The gates pass locally before the owner pushes, so CI starts green.

### The first sources are placeholders

- They exist to check that the scripts, the build, the tests and the doc
  generation work.
- They implement nothing.

### Kitchen tools changed on the way in

- `gen_examples_docs.sh` regenerates the whole of `kitchen/docs/examples/`.
  - Reason: next/ztk listed its own example groups by name, and mirrored
    `stories/`. paternitas has neither.

- `fix_md_hardbreaks.sh` fixes `kitchen/docs/` only, not every `.md` in the
  repo.
  - Reason: `paternitas-001.md` is kept untouched, and `STATUS-LOG.md` is never
    edited. A site build must not rewrite either.
- `fix_md_hardbreaks.sh` and `fix_md_lists.sh` skip a page's leading front
  matter block.
  - Reason: in next/ztk they rewrote the landing page's front matter. The `---`
    line got trailing spaces, and a blank line appeared inside the `hide:` list.
- `check_next_docs.sh` became `check_docs.sh`.
  - Checks kept: dead references, banned words.
  - Dropped: the retired-word list, and the plan-version check against the log.

---

## Decisions of ADPT 01

ADPT 01 tuned the workflow before any real code. Owner's rulings, 2026-09-25.
The process rulings are in the rules file. The list is in
[adpt-01-intent-002.md](adpt-01-intent-002.md).

### The gates

- `kitchen/gates.sh` runs the five gates, with fixed log names.
  - Reason: the gates cost round trips, and the log names changed per stage.
- `check_docs.sh` enforces every entry of the banned list: the words, their
  other forms, the phrases.
  - Reason: `grep -w` matches whole words only. A banned word with an `-ed`
    ending passed the gate.
  - The words whose meaning decides stay a hand scan.
- The test wrappers keep `std.testing.log_level = .debug`.
  - Reason: the owner wants all four levels in the test output.
  - Cost: Zig 0.16 prints it under a `failed command:` line. Accepted.

### The site

- The favicon stays ztk's until paternitas has a logo.
  - Reason: the same as the placeholder sources. Nothing to show yet.
  - The duplicate `kitchen/docs/favicon.ico` was deleted, with the owner's
    approval.
- The landing page hides the navigation. An "Examples" button sits beside the
  lines-of-code badge.
  - The nav entry stays, for every other page.
- `fix_md_hardbreaks.sh` skips raw HTML.
  - Reason: it added trailing spaces inside the landing page's `<style>`
    block and hero `<div>`. They meant nothing there.

---

## What paternitas keeps from ztk

Paths only. The ztk repo root is
`/home/g41797/dev/root/github.com/g41797/matryoshka-ztk`, written `ZTK` below.
`NEXT` is `ZTK/design/secondary/lang/port/3tk-to-ztk/next`.

A path here may go stale when ztk moves a file. When it does, fix the path in a
new version of this document.

### Smell — how the code looks

- The rewritten toolkit: `NEXT/ztk/src/`.
  - The module root: `NEXT/ztk/src/matryoshka.zig`.
  - Code hidden from the docs: `NEXT/ztk/src/internal/`.
- The tests and examples: `NEXT/ztk/tests/`, `NEXT/ztk/examples/`.
- What the toolkit refuses: `NEXT/ztk/negative/`, and its `README.md`.
- The build: `NEXT/ztk/build.zig`.

### Process — how the work is done

- The full rules: `ZTK/design/rules-050.md`.
- The state file of the new tree: `NEXT/next-status.md`.
  - Its **Rules** and **The gates** sections are the source of Part 0 and
    Part 1 of the rules file.
- The narrative of the new tree: `NEXT/next-log.md`.
- The stage menu: `NEXT/next-staging-plan-NNN.md`, the highest number.
- The old tree's state and narrative: `ZTK/design/STATUS.md`,
  `ZTK/design/STATUS-LOG.md`.
- The gate scripts and site tools: `NEXT/ztk/kitchen/`.
- CI: `ZTK/.github/workflows/`.

### Mantra — what ztk holds to

- An item sits in exactly one place, in exactly one state, at any moment.
  - `ZTK/design/rules-050.md`, Part 4, **Exclusive access, in comments**.
- Observable by human: a coordinator plus named steps.
  - `ZTK/design/rules-050.md`, Part 1.
- Staccato, everywhere text is written.
  - `ZTK/design/rules-050.md`, Part 6.

### Intent — why ztk is shaped the way it is

- The backport rulings: `ZTK/design/secondary/lang/port/3tk-to-ztk/3tk-to-ztk-007.md`.
  - Section **BKP 2 — the rulings**.
  - Section **The direction change**.
  - Section **The documentation direction**.
- The old tree's design folder: `ZTK/design/`.
  - Index: `ZTK/design/context.md`.
  - Concepts: `ZTK/design/matryoshka-concepts-003.md`.
