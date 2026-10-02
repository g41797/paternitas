# paternitas — session log

Append-only. Newest entries at top. Only the head is read.

---

## 2026-10-02 — PTRN 02, the ruling after the gates

The owner asked why `nameOf` sat on the root API page, not on `Anchor`'s.
Opus 5.5.

- Autodoc shows a declaration where it is declared. `nameOf` was at file
  scope.
- No reason was recorded. It came from the outside design.

The owner's ruling: move it into `Anchor`, as `typeName()`, now.

- `src/paternitas.zig`: `Anchor.typeName`. Still not `inline`, as A7 had it.
  `wrongType` calls `found.typeName()`.
- Callers: two tests, example 004. The test is renamed "typeName of a stamped
  Anchor".
- Design 007, edited in place, since no stage ran after it was written.
- The audit report keeps `nameOf`. It records the finding as it was.

Checks.

- Six gates pass. 22 tests in all four modes.

---

## 2026-10-02 — PTRN 02, docs and examples

PTRN 02 is closed. Opus 5.5. Intent and the owner's answers:
[ptrn-02-intent-001.md](ptrn-02-intent-001.md).

**The owner's answers.**

1. The example set: accepted.
2. 003 uses `std.Io.Queue(*Anchor)`: accepted.
3. Flat layout. Fewer examples than ztk.
4. No install section in the README. Later.
5. The landing page: only the Examples button target changes.
6. The root `//!` gets a fenced usage block.

**Doc comments.** Most of A4 was done in PTRN 01. Added in this stage:

- `///` on `Link(N)`'s fields `node` and `anchor`.
- The root `//!`: a usage block.
- `AnyParent`: the bullets split. "A view, not a copy" added.
- `mustParentFromNode`, `parentFromNodeUnchecked`: a MUST line each.
- `TypeInfo.parent`: who it is for.

**Examples.** `examples/examples.zig` became a barrel. `print_version`'s
successor moved with `mv` to `001-stamp_and_recover.zig`.

- `001-stamp_and_recover`, `002-mixed_list`, `003-timeout_list`,
  `004-handler_map`, `005-anchor_in_union`, `006-anchor_chain`.
- One wrapper each in `tests/examples_tests.zig`.

**Site.** `mkdocs.yml` lists the six pages under "Examples". The landing
page's button points to `001`.

- Finding: `fix_md_hardbreaks.sh` broke a wrapped `//!` intro line in the
  middle of a sentence.
  - Fixed in the sources: one sentence or two per line. Design 007.

**README.** It replaces `WIP`. Its links go to
`g41797.github.io/paternitas`. Not checked: Pages is an open item.

**Checks.**

- Six gates pass. 22 tests in all four modes.
- `build_site.sh` and `mkdocs build --strict` pass.
- Headless Chrome: the landing page, `apidocs/` and two example pages.
  - No `RangeError`, no `Uncaught`.
  - The new `///` text renders on the root, `Link` and `AnyParent` pages.
- `sources.tar` has only `paternitas/` and `std/`.

| step | result |
|---|---|
| Post-stage cleanup | Explicit types on three array literals, in 003, 004, 005. `node.*.next` in 003. No behaviour change. Gates re-run: pass. |
| Banned-word scan | Gate 4 passes. Hand scan of "commit", "cut", `hands`, `holds`, "object": no hits. |
| Rules audit | Examples: entry point, no `std.testing`, no assert, imports last, `std` last. Clean after the cleanup row. |

**Documents.** Design 007, plan 009. 006 and 008 are in `backup/`.
References repointed. The intent's charter link points to
`backup/implementation-plan-008.md`.

---

## 2026-10-02 — PTRN 01, the rulings after the gates

The owner ruled on the three points of the PTRN 01 close. Opus 5.5.

1. `container.@"---nextFieldAt---"` becomes `container._nextFieldAt`.
   - The quoted name broke its autodoc link.
2. Rules 005, Part 1 step 12: "`STATUS.md` holds that" becomes "has that".
3. `const testing = std.testing;` moves before `std` in the tests.
   - Rules 005, Part 2: an alias of `std` goes before it.

Edited in place, since no stage ran after they were written: rules 005,
design 006, plan 008, the intent file. `STATUS.md`, "Current state".

Checks.

- Six gates pass.
- The API page of `_nextFieldAt` loads.

---

## 2026-10-02 — PTRN 01, the code

PTRN 01 is closed. Opus 5.5. The outside paternitas replaces the placeholder.
Intent and the owner's answers: [ptrn-01-intent-001.md](ptrn-01-intent-001.md).

**The owner's answers.**

1. A15: the address step is `pub`, named `container.@"---nextFieldAt---"`.
2. The version stays `0.0.1`. Intake D9 said `0.0.0`.
3. `VERSION` leaves the API. `print_version` becomes `stamp_and_recover`.
4. SPDX headers in `src/`. Not in `tests/`, `negative/`, `examples/`.
5. `negative/` is not in the package paths.

**The code.**

- `src/paternitas.zig`, `src/container.zig`, ported to rules Part 2. A13.
- A1: a private `var tag: u8`, its address in `TypeInfo._tag`.
- A3: `Link(N)` is a compile error for any other `N`. `container` reuses
  `Link(N)`; its own `linkFor` is gone.
- A11: `Anchor._type_id`, read through `Anchor.typeId()`.
- T6: `is` takes `*const Node`.
- A15: `nextField` calls `@"---nextFieldAt---"`.
- Comments: banned words fixed. The full `///` pass is PTRN 02.

**Tests.** 16 in `tests/paternitas_tests.zig`, 1 example wrapper. 17 pass in
all four modes.

- The 9 outside tests. A test of the helper `Chain`, with its own `check`.
- A1: `tests/same_name/one/msg.zig` and `two/msg.zig`, two modules. Both
  names are `msg.Msg`.
  - The ids are compared at run time, through `doNotOptimizeAway`.
  - Proved in a scratch copy: with one shared tag the test fails in
    ReleaseSafe, ReleaseFast, ReleaseSmall. Debug passes, as in the audit.
- A5, A11, A15 tests.

**Negatives.** 9 programs: 5 compile, 4 run.

- A9: `wrong_node` matches "found '*DoublyLinkedList.Node'".
- New: `link_other_node.zig` (A3), `from_any_unstamped.zig` (A5).
  - `from_any_unstamped`: aborts in Debug and ReleaseSafe, exits 0 in
    ReleaseFast and ReleaseSmall.
- Gate 6: `kitchen/build_negative_all.sh`, four modes, the host. Gate 5
  checks `negative` too.

**Documents.** Rules 005: six gates, SPDX, quoted names in `src/`. Design 006:
the decisions of PTRN 01. 004 and 005 are in `backup/`. References repointed.
Report 003 now points to `backup/paternitas-design-005.md` for the design AUDT
01 wrote.

**Site.** `preview_site.sh` ran. Headless Chrome loaded the API pages. No
console errors. `sources.tar` has only `paternitas/` and `std/`.

- Finding: the autodoc link of `@"---nextFieldAt---"` is broken.
  - The quote ends the `href`. Its page says "Declaration not found".
  - Its row in the container page shows the full signature.
  - The same fault rules Part 2 names for examples. For the owner.

**Post-stage cleanup.**

| edit | behaviour |
|---|---|
| `: type` on type constants in `tests/`, `examples/`, `tests/same_name/` | none |

Gates re-run after cleanup: six pass.

**Banned-word scan.** Changed `.zig` and `.md`.

- All hits read. All are another sense: "hand-written", "hand-built", "by
  hand", "the offset holds", `addObject`.
- One real hit, from rules 004, unchanged: rules 005, Part 1 step 12,
  "`STATUS.md` holds that". For the owner.

**Rules audit.**

- Tests put `const testing = std.testing;` after `std`. The rule says `std`
  last. It came from the placeholder. For the owner.
- `Link(N)`'s fields `node` and `anchor` have no `///`. PTRN 02, A4.

**Gates.** Six pass.

---

## 2026-10-02 — AUDT 01, ChatGPT's review of design 004

The owner brought ChatGPT's review of design 004. Claude analysed it against
design 004 and the outside design. Opus 5.5.

- ChatGPT approves the design.
- Already decided: `Parent` in the ztk API, "outer" in the model only, the
  boundary, `*Anchor` as the currency, no `Inner` alias, the `DLink`
  scenarios, what a TypeId does not prove.
  - It said design 004 "still says" `Outer`. Design 004 names those words once,
    as leaving the API.
  - It argued against a `ParentInfo` that no design has.
- The owner's rulings, on Claude's four questions.
  1. A15, new: the fallback branch of `nextField` never runs on a tested
     target, and no test reaches it. PTRN 01 makes the address step a private
     function that takes the offset, and tests it with the stored offset.
  2. `AnyParent` is named as the replacement of `AnyOuter`.
  3. ztk notes: no mechanical rename; "outer" only in the model; the ztk
     checkpoint after the containers. ChatGPT's checkpoint after step 8 of 16
     cannot pass: Queue, stack, Mbox and Pool chain through `Inner`.
  4. `ParentHelper` stays. It carries ztk policy: the Slot calls, `create`,
     `destroy`, `isLinked`, `stamp`.
- Design 005 and plan 007. 004 and 006 are in `backup/`. `STATUS.md`, the
  rules, the intake and report 003 point at them.

## 2026-10-02 — AUDT 01, a ruling after the close

- `design/source/` stays until after the ztk stage. Then the owner removes
  it. It replaces intake D6, "after the paternitas work".
  - Reason: design 004 points to the outside design's ztk section in it.
- Recorded in `STATUS.md`, "Open items", and in plan 006, "Deferred".
  - Plan 006 was edited in place for this item only. No stage ran since it
    was written.

---

## 2026-10-02 — AUDT 01, audit and design

AUDT 01 is closed. Opus 5.5. No code changed in this repo.

**The build.** The outside paternitas, in a scratch copy, Zig 0.16.0.

- `zig build test`: 9/9 in all four modes.
- `zig build negative`: 11/11 steps in all four modes. The 11 is build steps.
  There are 7 programs: 4 compile, 3 panic. Intake F2.

**The probes**, in the scratch copy.

- Two modules, each with a root file `msg.zig` and a type `Msg`. Both type
  names are `msg.Msg`.
  - Zig merged their equal descriptors in ReleaseSafe, ReleaseFast and
    ReleaseSmall. One TypeId for two types. `Info(A).fromAnchor` returned a
    `B`.
  - A `var` descriptor fixed it. The owner refused it: a `var` can be changed.
  - The owner's idea, a private `var` tag with its address in the `const`
    descriptor, fixed it in all four modes. 9 tests and 7 negatives pass.
- `Link(MyNode).kind` is `.double`.
- An `Info` that refers to its own Parent type works.
- A hand-built `AnyParent` panics in Debug and passes in ReleaseFast, as
  designed.

**The report.** Findings A1 to A14, and T1 to T7 from `paternitas-001.md`.

- 001: the findings and the questions.
- 002: the owner's rulings, and Claude's advice on A1 and A11.
- 003: the owner approved both. No question is open.
- 001 and 002 are in `backup/`.

**The owner's main rulings.**

- A1: the private tag. A3: `Link` stays `pub`, other Nodes are a compile
  error. A6: no. A11: `_type_id` and `Anchor.typeId()`.
- T1 to T3 into the design. T4 `unstamp`, T5 `init`: out. T6: `is` takes
  `*const Node`. T7: a stage of its own, proposed as LOOK 01.

**Design 004.** The outside design rewritten in rules style, with the
approved fixes. It keeps all that 003 recorded. 003 is in `backup/`.

- The ztk plan, file by file, stays in `design/source/`. Design 004 points to
  it. The plan's "Deferred" says so.

**Plan 006.** PTRN 01 carries the fixes, the new tests and the new negatives.
LOOK 01 added. 005 is in `backup/`.

**Live references.** `STATUS.md`, the intake and the report point at plan
006. `rules-004.md` points at design 004; it was edited in place for this
link only.

**Gates.** All five pass.

### Post-stage cleanup

- `audit-01-report-001.md`: two forward links to files not yet written
  became plain text, so the dead-link check passed.
- This entry: the `---` line before the ADPT 01 entry, left out at first.
- Design 004, "Mantra": "what ztk holds to" from 003 became "what ztk keeps
  to". The custody sense of a Part 4 word.
- Re-ran the gates after cleanup: all five pass.

### Banned-word scan and rules audit

- The gate: clean.
- Hand scan of design 004, plan 006, report 003, `STATUS.md` and this entry.
  - "holds" in design 004 means "is true", for the uniform offset. Not the
    custody sense.
  - Report 003, A14, names "object" as the word it counts. Left for the owner.
- Rules audit.
  - Design 004 describes in the present tense what PTRN 01 builds: `_tag`,
    `_type_id`, the new tests and negatives. It is the design; the plan
    carries the work.
  - Some lines are longer than 80 characters: URLs, code, table rows. As
    before.

---

## 2026-10-02 — ADPT 01, close; intake of the outside work

ADPT 01 is closed. Opus 5.5. The plan is now 005; 004 is in `backup/`.

**Parts 1 and 2** were done on 2026-09-25: rules 003, design 003,
`kitchen/gates.sh`, the full banned list in `check_docs.sh`, the hard-break
fixer, the Examples button, the favicon duplicate. The rulings are in
`backup/adpt-01-intent-002.md`.

**Part 3, CI.** Not checked by Claude. `gh` answered `401 Bad credentials`.
The owner accepted CI and Pages as they are, and may come back to them.

**The outside work.** The owner worked several days on another computer, with
Claude and ChatGPT: a new design for paternitas and ztk, the paternitas code,
and ztk moved onto it.

- Scanned, read-only: the design, all paternitas sources and negatives, the
  ztk build, `inner.zig`, `helper.zig`, README and negatives. The ztk copy was
  compared with the local NEXT tree.
- Findings F1 to F11, the rulings D1 to D10, and the questions left for ztk:
  `paternitas-intake-001.md`.
- The owner's main rulings.
  - paternitas first, ztk after it, in rounds when ztk needs fixes.
  - The outside design comes first; `paternitas-001.md` adds what it lacks.
  - Stages AUDT 01, PTRN 01, PTRN 02. All on Opus.
- All of `~/Downloads/paternitas-ztk-parent/` copied to `design/source/`, as
  is. `diff -rq` against the original: no difference. The owner removes it
  later.

**Rules 004.** 003 is in `backup/`.

- No remote git, no `gh`. The owner's other repos are read, never run in.
- Every stage saves all it learns in the owner's files, and ends with the
  continue prompt and the model.
- The banned-word check skips `design/source/`.

**Gate change.** `check_docs.sh` passes `--exclude-dir=source` to the word
scan. Approved with the plan.

**Live references.** `STATUS.md` and `paternitas-design-003.md` point at
rules 004 and plan 005. The design's link to the ADPT 01 rulings points into
`backup/`. The design doc was edited in place for these two links only.

**Gates.** All five pass. 2/2 tests in each mode.

### Post-stage cleanup

- `implementation-plan-005.md`: two forward links written as `-NNN`, so the
  dead-link check does not count files that AUDT 01 writes. Long lines
  rewrapped.
- Re-ran the gates after cleanup: all five pass.

### Banned-word scan and rules audit

- The gate: clean.
- Hand scan of the changed files: no hits in the new text. In rules 004,
  "`STATUS.md` holds that" is carried over from 003; it means "contains".
  Left for the owner.
- Rules audit: no violations found. `STATUS.md` table rows are longer than 80
  characters, as before.

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
