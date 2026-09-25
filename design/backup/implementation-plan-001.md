# INTR 15 — moving the development process to the paternitas repo

Number: INTR 15, the owner's ruling (2026-09-25). Nothing starts until the
owner says so.

## Content of INTR 15 (owner, 2026-09-25)
- Move our development process into
  `/home/g41797/dev/root/github.com/g41797/paternitas`.
- When INTR 15 is finished, a session starts in paternitas and carries on with
  development without needing access to the ztk files.
- Paternitas still knows about ztk. Every important ztk file and folder is
  recorded in one of paternitas' own files, because we will need to read that
  information from time to time.
- Development does not start right after the move.
- What INTR 15 delivers:
  1. The development process is moved to paternitas.
  2. Every required file gets content (today most of them are empty).
  3. The plan in paternitas names one new stage, **ADPT 01**, adaptation. ADPT
     tunes the workflow.
- The first sources are placeholder files only. They exist to check that the
  scripts, the build, the tests and the doc generation work. They implement
  nothing.
- **MUST: INTR 15 is recorded only in paternitas**, in
  `design/implementation-plan-NNN.md`, `design/STATUS.md` and
  `design/STATUS-LOG.md`. Nothing about INTR 15 is written into
  `next-status.md`, `next-log.md`, `next-staging-plan-*` or anything else under
  next/ztk. The owner doesn't want a mess in the next/ztk development.
- Q1 `rules-001.md` (owner): start from a trimmed copy of `rules-050.md`.
  Keep what isn't Matryoshka-specific: Part 0 adapted, Zig style,
  comments/doc/autodoc, banned words, writing documents. Drop Master, stories,
  dispatch and Matryoshka's invariants. Add the git rules (no git except
  `git status`, a plain `mv` for `git mv`). Link back to the source rules, with
  a note that their version may be updated.
- Q2 layout (owner): like next/ztk, with `build.zig`, `build.zig.zon`, module
  `paternitas`, and `src/`, `tests/`, `examples/`, each with a placeholder
  file. **No `negative/` and no gate 6 for now.** The plan records them as
  deferred to the first stage where paternitas refuses something (a compile
  error, or a panic in safe builds).
- Q3 ztk knowledge (owner): paths to the ztk sources, never copies. What
  paternitas keeps is ztk's smell, process, mantra and intent. It goes in
  `design/paternitas-design-001.md`.
- `paternitas-design-001.md` = the versioned design document: design
  decisions, with their reasons and the owner's rulings. Big tasks get a
  dedicated versioned .md under `design/`. Design decisions never go in STATUS.
- `STATUS.md` = the starting point, short. It holds current state only: where
  we are, the rules file, the sources of truth (links), open items, test counts,
  and the next stage with its model. It holds no design decisions, no narrative
  (that's STATUS-LOG) and no copies of facts that live elsewhere (pointers
  only). It is updated in place.
- `paternitas-001.md` = the advice different AIs gave after the owner's
  discussions with them. It may feed the README, the implementation and the
  start of the design. **Not used in INTR 15 or ADPT. It comes after ADPT.**
  Left untouched.
- Q4 process audit (owner: both). INTR 15 does a quick pass before
  `rules-001.md` is written: fix anything clearly wrong or outdated, and put the
  findings in STATUS-LOG. ADPT 01 then goes deeper and tunes the workflow.
- Q5 site (owner: a). Same structure as next/ztk (mkdocs landing page and
  `zig build docs`), with placeholder content: title "paternitas", one line from
  the owner's text, a badge to `apidocs/`, **no logo yet**. The generated docs
  come from the placeholder sources.
- Q6 CI (owner: a). Copy every `.github` workflow (linux, mac, windows,
  docs/Pages), adapted to paternitas' names and paths. The gates pass locally
  before the owner pushes, so CI starts out green.
- Parked, not part of INTR 15: the rulings on README-001 (O-1..O-5, P-27, B-1/B-2,
  the three small draft decisions, approval of the text). They are in
  `next/ztk/design/readme-creation-002.md` under *What the draft took*.

- Paternitas will have GitHub Pages. Its model is the new version (`next/ztk`),
  not the ztk root. After an audit, scripts and other files from `next/ztk` may
  be reused there (e.g. `kitchen/` gate and site tools, `mkdocs.yml`, `docs/`,
  `hooks/`).
- `/home/g41797/dev/root/github.com/g41797/matryoshka-ztk/.github` — the whole
  of it may be used in paternitas (owner, 2026-09-25).

## Owner's process (stated 2026-09-25) — follow it, don't use Claude memory
- State lives in the owner's .md files, not in Claude memory; that's what
  survives a clear.
- Versioned files: a new version gets the next suffix, and the old one is moved
  (`mv`) to `backup/`. The owner deletes from `backup/`.
- Status file = current state, and it stays short as the starting point.
- Log (`STATUS-LOG.md`) = all narrative, newest at the top. Only its head is
  read; new entries go at the top.
- Versioned rule files (format, banned words, etc.) govern. Here that's
  `rules-050.md`; in paternitas it's `design/rules-001.md` (renamed by the
  owner).
- Repo layout: `matryoshka-ztk` root = the previous version (its folders and
  files). `design/secondary/lang/port/3tk-to-ztk/next/ztk` = the new version,
  so some of its files don't carry the old names. When development is finished,
  the new version is promoted to the root. The `next-*` names are temporary; the
  owner will give the exact file names later.
- The paternitas repo is for ztk code that deserves special attention. All
  functionality is allowed there. The only git command allowed is `git status`;
  use a plain `mv` instead of `git mv`. Its tree follows the root's shape:
  `design/` (STATUS.md, STATUS-LOG.md, rules-001.md, implementation-plan-001.md,
  paternitas-001.md, backup/), `kitchen/{docs,tools}`, empty `src/`, README.md,
  LICENSE.
- Audit (later, or planned now): a short audit of the usual order in which the
  owner and Claude work together.

## Steps (all writes in paternitas; nothing under matryoshka-ztk changes)
Model: Opus 5.5. The source tree is `matryoshka-ztk/design/secondary/lang/port/3tk-to-ztk/next/ztk` ("next/ztk").
In paternitas, filling an empty file is not overwriting, so the empty
`implementation-plan-001.md`, `STATUS.md`, `STATUS-LOG.md` and `rules-001.md`
are filled at their current names.

1. **Quick process audit.** Read rules-050 Part 0 and Part 6, next-status
   *Rules* and the head of next-log. Write down the usual sequence: the stage
   is named, the model is stated, intent is shown, the owner approves, code,
   gates, cleanup, then closing across the three files and the three-line
   continue prompt. Mark anything clearly wrong or outdated. Findings go into
   the STATUS-LOG entry, and the sequence goes into `rules-001.md`.
2. **`design/rules-001.md`**, trimmed from rules-050 per Q1, with the git rules
   and a link to the source rules plus a note that their version may be updated.
3. **`design/paternitas-design-001.md`**: purpose, the decisions made in INTR
   15 (Q1–Q6 and the deferred `negative/`), and "What paternitas keeps from
   ztk". That last part carries the smell, process, mantra and intent, each as a
   path into matryoshka-ztk (next-status, rules-050, 3tk-to-ztk-007,
   next/ztk/src, kitchen, .github, and the root `design/`). Paths only, never
   copies.
4. **Project skeleton**, adapted from next/ztk `build.zig` and `build.zig.zon`
   (read in full first). Module `paternitas`. `src/paternitas.zig` gets a `//!`
   header and one trivial pub declaration. `tests/paternitas_tests.zig` gets one
   test. `examples/examples.zig` gets one placeholder example, plus a test that
   runs it. Build steps: test, examples, docs. No `negative` step.
5. **kitchen**. Audit each file (read it) before copying:
   - the three gate scripts: `build_and_test_debug`, `build_and_test_all`,
     `build_cross_debug`
   - tools: `build_site`, `docs_zig`, `preview_site`, `preview_apidocs`,
     `gen_examples_docs`, `count_src_loc` with `src_loc.py`, `fix_md_*`,
     `count_readme_loc`
   - `hooks/count_lines.py`
   - `check_next_docs.sh` becomes `check_docs.sh`: dead references plus banned
     words, with the retired-word list dropped or left empty
   - `mkdocs.yml`, a placeholder `docs/index.md` (title, one line, badge to
     `apidocs/`, no logo), `stylesheets/extra.css` and a favicon
   - not copied: generated output (`apidocs/`, `site/`), the ztk example pages,
     ztk's logo and diagrams
   - remove the `.gitkeep` files once real files exist in those folders; ask
     the owner first, because it's a deletion
6. **`.github/workflows`**: linux, mac, windows and docs, from matryoshka-ztk,
   adapted to paternitas' paths and names.
7. **`.gitignore`**: check it against `.zig-cache`, `zig-out` and the site
   output.
8. **Close INTR 15** in paternitas only:
   - `STATUS.md`: current state, sources of truth, open items, next = ADPT 01
     and its model
   - `STATUS-LOG.md`: the INTR 15 entry at the top, including the audit findings
     and a post-stage cleanup row
   - `implementation-plan-001.md`: a completed-stages line for INTR 15; ADPT 01
     in full (tune the workflow, the deeper process audit, the site and CI
     check-up); deferred items (`negative/` and gate 6, `paternitas-001.md`
     after ADPT, README text)
   - end the message with the three-line continue prompt: STATUS file, stage,
     model
9. `README.md` stays at the owner's `WIP` until ADPT, unless the owner says
   otherwise.

## Verification (run from paternitas, output to `zig-out/` logs)
Gates: `build_and_test_debug.sh`, `build_and_test_all.sh`,
`build_cross_debug.sh`, `check_docs.sh`, and `zig fmt --check src tests examples
build.zig`. Also `build_site.sh` and `preview_site.sh` to confirm the landing
page and the API docs render. A banned-word scan over the new `.md` files is
reported to the owner. The owner pushes and watches CI.
