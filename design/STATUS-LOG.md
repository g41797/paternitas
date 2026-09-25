# paternitas — session log

Append-only. Newest entries at top. Only the head is read.

---

## 2026-09-25 — INTR 15, the owner's answers

The owner answered the three questions left at the close of INTR 15. Opus 5.5.

- **The `.gitkeep` files: delete.** Removed from `kitchen/docs/` and
  `kitchen/tools/`.
- **The landing line: "Paternitas".** It replaces the proposed sentence from
  `paternitas-001.md`. The title and the line were one text, so the page shows
  it once, as the title. `mkdocs.yml` `site_description` is "Paternitas" too.
  - Not changed: the `//!` header of `src/paternitas.zig` still says "typed
    access to items kept in intrusive std linked lists". It is placeholder
    text, left for ADPT 01.
- **The banned heading: rename.** "Status file ownership" became "Status
  files — where each fact lives".

Versions written, since each change touched a versioned doc:

- `rules-002.md`, for the heading. 001 is in `backup/`.
- `paternitas-design-002.md`, for the Q5 ruling. 001 is in `backup/`.
- `implementation-plan-003.md`, with the answered items taken out. 002 is in
  `backup/`.
- Live references re-pointed in `STATUS.md`, the plan, the rules and the
  design doc. `check_docs.sh` now excludes any `rules-NNN.md` by pattern.

The owner also asked whether the continue prompt should begin with "Read". Yes:
a bare path names a file, and "Read" makes it an instruction. The path is
written absolute, so the prompt works from any directory.

### Post-stage cleanup

- Gates re-run after the changes. All five pass; 2/2 tests in each mode.
- `build_site.sh` and `mkdocs build --strict` pass.
- `rules-002.md` hand scan: `ownership` now appears only in the word list,
  the replacement table, and the change line that records its removal.

---

## 2026-09-25 — INTR 15

The owner named INTR 15 and said start. It ran on Opus 5.5, as the plan asked.
The plan is now 002, and 001 is in `backup/`.

**What INTR 15 is.** Moving the development process from next/ztk into
paternitas. A session here then works without the ztk files. The content of the
ruling, Q1 to Q6, is in `backup/implementation-plan-001.md`. The decisions are
in `paternitas-design-001.md`.

**Nothing under matryoshka-ztk changed.** Every write was in paternitas. It was
only read from.

**One departure from plan 001.** Its step 8 said to update
`implementation-plan-001.md` at close. By then 001 was no longer empty, so the
versioning rule applied: 002 was written, and 001 was moved to `backup/`.

### Quick process audit (Q4)

Read: `rules-050.md` Parts 0 and 6, `next-status.md` **Rules** and **The
gates**, the head of `next-log.md`.

The usual sequence, as practised. It is now `rules-001.md` Part 1.

1. The owner names the stage.
2. The model is stated, with the reason.
3. Intent is shown.
4. The owner approves, or rules.
5. Code.
6. Gates.
7. Post-stage cleanup, and the gates again.
8. Close across the three files.
9. The three-line continue prompt.

Findings. The ones marked *fixed* were fixed in paternitas only.

- `rules-050.md` Part 0 keeps superseded docs and lists them in
  `context.md`. The owner's process moves them to `backup/`, and the owner
  deletes from there. next/ztk already works that way. *Fixed:* `rules-001.md`
  follows the owner's process.
- `rules-050.md` says both "the three status files" and "four files carry
  project state". *Fixed:* `rules-001.md` names three.
- `rules-050.md` says the log is "not read by default". The owner reads its
  head. *Fixed:* `rules-001.md` says so.
- The model statement and the three-line continue prompt live only in
  `next-status.md`, not in the rules. *Fixed:* both are in `rules-001.md`
  Part 1.
- `rules-050.md` Part 0 says "No git", with no exception. `next-status.md`
  allows `git status`. *Fixed:* `rules-001.md` has the exception, and the plain
  `mv`.
- The docs workflow at `matryoshka-ztk/.github/workflows/docs.yml` pins Zig
  0.15.2. Both ztk trees declare `minimum_zig_version = "0.16.0"`, so the
  docs job cannot build them. *Fixed here:* 0.16.0. **Not fixed in ztk.**
- The same workflow skips `fix_md_hardbreaks.sh`, which `build_site.sh` runs.
  The site that CI builds differs from the local one. *Fixed:* the step is added.
- `fix_md_hardbreaks.sh` rewrote every `.md` in the repo, append-only logs
  included. *Fixed:* it touches `kitchen/docs/` only.
- `fix_md_hardbreaks.sh` and `fix_md_lists.sh` rewrote the landing page's
  front matter in next/ztk. `kitchen/docs/index.md` there shows it: `---  ` and
  a blank line inside `hide:`. *Fixed:* both skip a leading front matter block.
- `src_loc.py` names `design/src-loc-counter-001.md` in its docstring. That
  file exists nowhere in matryoshka-ztk. *Fixed:* the docstring says what uses
  the module.
- `gen_examples_docs.sh` hard-coded ztk's example groups and mirrored
  `stories/`. *Fixed:* it regenerates the whole of `kitchen/docs/examples/`.
- `check_next_docs.sh`'s banned list omits some words of `rules-050.md` Part
  5: fed, arm, leg, fires, faces, pitch, and the multi-word entries. *Not
  fixed.* `check_docs.sh` keeps the same list. Carried to ADPT 01.
- A passing Zig 0.16 test that writes to stderr is printed under a
  `failed command:` line. next/ztk's logs show the same. *Not fixed.* Carried
  to ADPT 01.

### What was written

- `design/rules-001.md` — trimmed from `rules-050.md`, per Q1.
- `design/paternitas-design-001.md` — purpose, the decisions of INTR 15, and
  what paternitas keeps from ztk, as paths.
- `build.zig`, `build.zig.zon` — adapted from next/ztk. Module `paternitas`.
  Steps: install, `test`, `examples`, `docs`. No `negative`. A new
  fingerprint, the one `zig build` suggested.
- `src/paternitas.zig` — a `//!` header, `_doc_stub`, and `VERSION`.
- `tests/paternitas_tests.zig` — one test.
- `examples/examples.zig` — `print_version`. `tests/examples_tests.zig` runs
  it.
- `kitchen/` — the three gate scripts, byte-for-byte. The tools, the hook,
  `mkdocs.yml`, `stylesheets/extra.css`, the favicon, each read before it was
  copied. `check_docs.sh` is new, from `check_next_docs.sh`.
- `kitchen/docs/index.md` — title, one line, a badge to `apidocs/`, no logo.
  The line is the first sentence of `paternitas-001.md`. That is the only use of
  that file, and it is a proposal.
- `.github/workflows/` — linux, mac and windows unchanged. docs adapted.
- `.gitignore` — ztk's eight generated example folders became one line,
  `/kitchen/docs/examples/`. `.zig-cache`, `zig-out`, `/docs/` and `site/` were
  already covered.
- `README.md` — not touched.

### Gates

All logs are in `zig-out/`.

1. `build_and_test_debug.sh` — pass. 2/2 tests.
2. `build_and_test_all.sh` — pass. 2/2 tests in each of the four modes.
3. `build_cross_debug.sh` — pass, three targets.
4. `check_docs.sh` — clean, once 001 moved to `backup/`. Before that it
   flagged 001's own references to ztk files, and one banned word in it.
5. `zig fmt --check src tests examples build.zig` — clean.

Site.

- `build_site.sh` — pass. `mkdocs build --strict` — pass.
- `preview_site.sh` — serves on port 8000.
- Rendered in headless Chrome: the landing page, `apidocs/`, and the example
  page. No `RangeError`, no `Uncaught`. `VERSION` renders on the API page.
- `sources.tar` holds `paternitas/paternitas.zig` and std only.

### Post-stage cleanup

- Reviewed every new file. Two hits in `paternitas-design-001.md` from the
  first `check_docs.sh` run were fixed: a banned word, and a bare
  `rules-050.md` that now reads `ZTK/design/rules-050.md`.
- Comments carried over from ztk that named `examplesdocs`, a target
  paternitas does not have, were corrected in `docs_zig.sh` and
  `preview_apidocs.sh`.
- The gates were re-run after the cleanup. All five pass.

### Left for the owner

- The `.gitkeep` files in `kitchen/docs/` and `kitchen/tools/`. A deletion.
- GitHub Pages, set to deploy from GitHub Actions.
- The push, and reading the first CI runs.
