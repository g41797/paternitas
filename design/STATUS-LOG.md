# paternitas — session log

Append-only. Newest entries at top. Only the head is read.

---

## 2026-10-06 — DOCS 01, before the owner's commit

The owner is going to compact the session and commit.

- Six gates pass on the final state. 27 tests. The strict site build
  passes. g4 is clean.
- STATUS has three new open items: the empty `kitchen/docs/javascripts/`
  folder, `mkdocs serve` missing edits, and the trailing spaces the site
  build adds to the pages.
- No git command ran in this session, except `git status`.
- The preview server is stopped.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01, the owner's review of the pages

---

## 2026-10-06 — DOCS 01, the owner's fourth look

- The owner found "Next: Move your code" on `reference/install`, while
  Material's footer said "Name and origin". The ruling: no homemade
  "Next:" anywhere. The footer, from `navigation.footer`, does the job.
  Claude removed four such lines.
- The NAQ "Which Zig?" on `reference/install` is gone.
- The line "The pages that use them" on `reference/calls` is gone.
- The "Where next" table in `introduction` stays. It is a choice by case,
  not a next page.
- Intent 007 records it. 006 is in `design/backup/`.
- The strict site build passes. g4 is clean.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01, the owner's review of the pages

---

## 2026-10-06 — DOCS 01, the owner's third look

The owner reviewed in the preview, and stopped and started it several
times.

- "The terms this site uses" sounded official. Claude retitled the page
  "Stuck on a word?", and offered "What does that word mean?" and "Words
  you will meet here".
- The owner asked to move "What's NAQ?" and its two lines to the very end
  of `introduction`, under a title that is not serious. Claude chose "One
  more thing", and offered "Psst.", "Small print" and "Before you go".
- `mkdocs serve` missed each edit. Claude restarted the preview after each
  one. Its file watcher does not see changes here. Not looked into.
- Intent 006 records it. 005 is in `design/backup/`.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01, the owner's review of the pages

---

## 2026-10-06 — DOCS 01, the owner's second look

The owner read the `api` page in the preview, and said "continue".

- The `api` page lost its text. Two buttons: "Open in a new tab", the main
  one, and "Open here". Claude chose the wording, as the owner asked.
- "For a short scan" sounded like AI. Claude found seven more phrases of
  that kind on the pages, and the owner approved each plain sentence.
- "Words" is "Terms". Claude moved `reference/words.md` to
  `reference/terms.md` with `mv`. Its title is "The terms this site uses".
- `mkdocs serve` did not see the nav change. Claude restarted the preview.
- Intent 005 records it. 004 is in `design/backup/`.
- The strict build passes.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01, the owner's review of the pages

---

## 2026-10-06 — DOCS 01, the owner's first site review

The owner asked to review the site, not the `.md` files. Claude ran
`preview_site.sh`. The owner gave two rulings, then said "go all", and to
stop the web server first.

- The API docs entry is the last nav item. It opens a new page, `api`: a
  short description, a line that the Zig pages open in another tab or
  window, and a button with `target="_blank"`.
  - `new-tab.js` had no job left. Claude took it out of `mkdocs.yml` and
    moved it to `design/backup/` with `mv`. `kitchen/docs/javascripts/` is
    now an empty folder. The owner deletes it.
- No Questions page. NAQ blocks, in the style of the owner's tofu site:
  `??? question "NAQ: ..."`, collapsed, each right after its text.
  - `pymdownx.details` is on.
  - "What's NAQ?" is in `introduction`, from tofu's `naq.md`.
  - The old questions went to their pages. New: why the word Parent, why
    not the std Node, why `Any` and not `*anyopaque`, why no mark by
    itself.
  - `reference/questions.md` is `design/backup/questions-001.md`. Strict
    fails on a page outside the nav, so it could not stay.
- Intent 004 records the rulings. 003 is in `design/backup/`. STATUS and
  plan 017 point to 004.
- Six gates pass. The strict site build passes. Headless Chrome loads
  `api`, `introduction`, `guides/lists`, `background/type-erased` and
  `reference/limits`, with no console errors. The NAQ blocks render as
  details. `api` is the last nav link.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01, the owner's review of the pages

---

## 2026-10-06 — DOCS 01, the pages

The owner named it. Opus 5.5. The plan is intent 003. The owner said "go
all" twice, and asked for staccato.

- Step 1, the checks.
  - g4 reads `kitchen/docs/` at every depth, except `examples/` and
    `apidocs/`. A link from a site page into either is counted and left to
    strict.
  - `--strict` in `build_site.sh` and in `.github/workflows/docs.yml`.
  - The `validation` block in `kitchen/mkdocs.yml`.
- Step 2, the hero. The logo links to `introduction/`. Alt text "Paternitas
  — start here". The API and Examples buttons are in a comment.
- Step 3, the tools.
  - `pymdownx.snippets`: `base_path: [".."]`, since mkdocs runs from
    `kitchen/`. `check_paths` and `dedent_subsections` are on.
  - Tried: a wrong section name stops the build with `SnippetMissingError`.
  - `gen_examples_docs.sh` drops the marker lines from the example pages,
    and skips a file whose `//!` holds `Page: none`.
  - `javascripts/new-tab.js`, through Material's `document$`. The "API docs"
    nav entry under Reference.
- Step 4, the code.
  - `examples/before_paternitas.zig`: Message and Job with plain std Nodes,
    a plain `@fieldParentPtr` on the right type. A test wrapper "00 - before
    paternitas". 27 tests.
  - 001: a whole-struct reset, `setTypeId` on the next line, and a check
    that the Message comes back.
  - 002: `TypedJob.is` on the last Node. No example called `is` before.
  - Snippet markers in 001 to 007. Comments only.
- Steps 5 to 10, the pages: seventeen, in the order of the plan.
  `introduction` last.
- One change against the plan, on "The Parent problem". No negative shows
  `mustParentFromNode` on another type. The page quotes the panic of
  `must_parent_from_anchor.zig`, which names both types, and says
  `mustParentFromNode` prints the same kind of message.
  `must_parent_from_node.zig` and its `<no type>` panic are on "Move your
  code".
- Claude caught "on purpose", a banned phrase, in `introduction`, before
  the build.
- Step 11 waits for the owner's review of the README 01 draft.
- Step 13: six gates pass. The strict site build passes. Headless Chrome
  loads the hero, the seventeen pages and example 002, with no console
  errors. Every live link to `apidocs/` has `target="_blank"`. No marker
  line reaches the HTML.

| step | result |
|---|---|
| Post-stage cleanup | none. No scratch files in the repo |
| banned-word scan | g4 clean |
| rules audit | no finding. No git beyond `git status`. No file deleted |

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01, the owner's review of the pages

---

## 2026-10-06 — DOCS 01 PLAN

The owner named it. Opus 5.5. Planning only, no site pages written.

Input: the owner's brief (a summary of the request), the owner's collected
advice paternitas-doc-site.md, the README 01 draft, README-001, `src/`, the
examples.

- Intent 001: a page tree from the brief's shape, Introduction,
  Background, Guides, Examples, Reference. A source map per page, the
  README section by section, the nav, the g4 and strict checks.
  - The advice did not know the landing page is a hero, nor that example
    pages are generated. Both kept as they are.
  - Found: g4 reads `kitchen/docs/` at depth 1 only, so subfolder pages go
    unchecked. No script runs `mkdocs build --strict`. The example and API
    folders are in `.gitignore`.
- The owner asked why a separate file and not plan 017. Claude: rules
  Part 0, a big task gets its own versioned file; the plan is versioned at
  stage close. The owner chose the name `docs-01-intent-NNN.md`.
- Owner's answers to 001:
  - The logo links to the first site page, as ztk's links to its
    manifesto. The hero buttons go in a comment.
  - An API docs nav entry, opening the Zig pages in a new tab. Tried in a
    scratch copy: `apidocs/index.html` in the nav passes `--strict`. A nav
    entry takes no target, so a small `new-tab.js`.
  - Every snippet from working code. `pymdownx.snippets`, with sections
    marked in `examples/` and `negative/`.
  - README links: iterative. The bonus stays. Pages: add any that help.
    Claude added `guides/choose`, `reference/words`, `reference/questions`.
- Intent 002, with those. Three questions.
- The owner said the wrong `@fieldParentPtr` is not Illegal Behavior.
  Claude checked the 0.16.0 langref on disk: for a result type with
  ill-defined layout, a plain struct, it is unchecked Illegal Behavior. The
  owner chose to keep the wrong cast as written text. The wording of the
  reason was fixed in 002, in place, at the owner's request.
- Owner's answers to 002: all three checks (`--strict` in `build_site.sh`
  and in CI, the `validation` block). The code before Paternitas: yes, but
  off the example pages. Claude proposed `examples/before_paternitas.zig`,
  unnumbered, with a `Page: none` line the generator skips. Agreed.
- Intent 003 records it all. 001 and 002 are in `design/backup/`.
- Plan 017: one line under "Completed stages"; DOCS 01 points to intent
  003. 016 is in `design/backup/`. Live links repointed: STATUS, audit
  report 003, design 014, intake 001, PTRN 01 and PTRN 02 intents.
- Six gates pass.

| step | result |
|---|---|
| Post-stage cleanup | none. The stage changed `.md` files under `design/` only |
| banned-word scan | g4 clean on every changed file |
| rules audit | one finding: intent 002 was edited in place for the wording fix, against "never overwrite a doc". Told the owner. 003 is a new version |

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01
Model: Opus 5.5.

---

## 2026-10-06 — The C unit test

The owner said write the test from design 014, "C code: findings". Claude
showed the intent first. Owner's answers: folder `design/c-test/`, Zig only,
the script in `kitchen/`.

- `design/c-test/c_context_test.zig`: five tests. A fake C library keeps a
  `callconv(.c)` callback and a `?*anyopaque` context, and calls back
  through a function pointer held in a `var`.
  - `*Anchor`: the Parent comes back; another type gives null; no
    `setTypeId` gives null.
  - `*Any` of a struct with no TypedNode: it comes back; another type
    gives null.
- `design/c-test/README.md` says what it is and how to run it.
- `kitchen/test_c_context.sh`: `zig test` in four modes, LLVM and Zig's
  own backend. 8 runs, 5 tests each, all pass. Not a gate, not in
  `build.zig`.
- Design 014 points to the folder, edited in place: one line in "The
  unit-test scenario".
- g4 then failed: `rules-013.md` named `design/zelda-and-paternitas.md`,
  which the owner deleted. Owner's ruling: drop it from that line, edited
  in place.
- Six gates pass.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01 PLAN
Model: Opus 5.5.

---

## 2026-10-06 — DSGN 014: no word about C, and design 014

The owner said do "Next", steps 1 and 2. Ongoing work, not a named stage.

Step 1, no word about C. Comments only; the code is unchanged.

- `src/paternitas.zig`, the `Anchor` `///`: now "Use it in your own
  container."
- `src/container.zig`, the module doc and `TypeInfo.parent`: "such as a C
  callback's `void*`" is gone. "Code that knows nothing of Paternitas"
  stays.
- `examples/007-type_id_without_node.zig`, the header: "`void*` contexts"
  is now "handler maps". The site page is regenerated.
- The README and `kitchen/docs/` had nothing else. The README's
  "`*anyopaque` contexts" is Zig, not C, and stays.

Step 2, design 014.

- 013 and `typeid-split-proposal-002.md` are in `design/backup/`. Links
  point to 014: STATUS, plan 016, rules 013, audit report 003, PTRN 01
  intent.
- `AnyParent` is `Any` in the design text. The "Change from" history and
  the "Decisions of" sections keep the old name.
- New: "Type ids on their own", from the proposal. "C code: findings", a
  record with the unit-test scenario. "Decisions of TYID 01/02".
- `typeId()` with `&tag`, the third compile error, `fromAny` without a
  TypedNode, `-Duse_llvm`, the TYID tests, the tenth negative and example
  007 are in the body now.
- 013 still said "nine programs: five compile, four run". Now ten, five
  and five.

- Six gates pass, after one g4 fix: a backticked file name in 014 read as
  a dead link. Now `backup/...`. The site builds.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01 PLAN
Model: Opus 5.5.

---

## 2026-10-06 — C code: findings

The owner asked: can a Parent go to C as a `void*`? Should Paternitas
refuse `extern` structs? Claude tested it. Scratch only, nothing in the repo.

Findings, Zig 0.16.0:

- A real C file stored a `void*` context and called a Zig `callconv(.c)`
  callback with it. The structs were not `extern`: a slice, a TypedNode.
  All four build modes:
  - `TypedJob.anchor(&job)` as the context; the callback casts it to
    `*Anchor` and calls `mustParentFromAnchor`. Works, type checked.
  - `&any`, an `Any` of a struct with no TypedNode; the callback calls
    `fromAny(any.*)`. Works, type checked.
  - Built with `zig run -lc --dep paternitas c.c -Mroot=main.zig
    -Mpaternitas=src/paternitas.zig`.
- A non-extern struct by value in a C signature does not compile:
  "parameter of type 'Job' not allowed in function with calling
  convention 'x86_64_sysv'".
- A pointer to it does compile: `extern fn f(j: *Job) void`, and
  `?*anyopaque`.
- An extern struct cannot hold a TypedNode: "extern structs cannot contain
  fields of type 'paternitas.TypedNode(DoublyLinkedList.Node)'". So an
  extern Parent cannot exist. No Paternitas check is needed.
- An extern struct with no TypedNode works with `toAny` and `fromAny`.
  Nothing to refuse.
- `Any` is not extern: C cannot take it by value. Only `*Any`, and the
  `Any` must outlive the callback.
- `*Anchor` is one word, a `void*`. The type is checked on the way back.
- `TypeInfo.parent` gives the raw address. Nothing checks the type when it
  is cast back.
- C keeps the pointer after the call. The struct must outlive it.
- C must never read through the pointer: a non-extern struct has no
  defined layout.

The unit-test scenario, for design 014. Not written yet:

- In Zig only, no libc: a `callconv(.c)` function that takes
  `?*anyopaque`, called through a function pointer.
- Round-trip a `*Anchor` (`parentFromAnchor` gives the Parent; another
  type gives null) and a `*Any` (`fromAny`).
- All four modes, both backends, like the other tests.
- A real C test needs libc and a C file in `build.zig`, and may trouble
  g3 cross. Left out.

The owner's rulings:

- Remove every word about C from the README and the comments. Unclear
  functionality is not advised.
- Design 014 gets a C section with all of the above, and absorbs the TYID
  proposal. Ongoing work, not a named stage. See STATUS.md, "Next".

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Do "Next": steps 1 and 2. The C findings are in the STATUS-LOG head.
Model: Opus 5.5.

---

## 2026-10-06 — Comments: four items from a ChatGPT revision

The owner brought ChatGPT's revision of `src/paternitas.zig` and
`src/container.zig`. The code was the same; the comments were cut from 651
to 351 and from 177 to 121 lines.

- Taken, at the owner's word:
  - the module doc opens with the problem, then "Do you need it?", then
    "Three words first";
  - plainer first lines for `setTypeId`, `parentFromNode`,
    `parentFromAnchor`, `fromAny` and `TypeInfo`;
  - "Your container owns the meaning of that word", in two places.
- Not taken:
  - the revision called every struct a Parent again, against TYID 01;
  - it dropped the MUST warnings, the `var tag` comment (the A1 bug), the
    shared-library limit and the Limits section;
  - nine `pub` declarations lost their `///`.
- The Anchor motto stays. Owner's ruling.
- Six gates green. The site builds; `mkdocs build --strict` passes. The API
  docs carry the new text.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01 PLAN
Model: Opus 5.5.

---

## 2026-10-05 — README 01: the bonus, and the error texts

The owner put ZTK aside: the README and the docs first.

- Error texts fixed, at the owner's word. A struct with no TypedNode is
  allowed now, so the old reasons were wrong.
  - `X: not a struct, and Typed takes structs only`.
  - `X: more than one TypedNode, and at most one is allowed`.
  - `src/`, `build.zig`, two negatives' comments, two `///`.
  - The design docs updated in place, at the owner's word: plan, proposal
    002, design 013 ("Required Parent shape" said zero TypedNodes do not
    compile), name-01 intent 002.
  - Six gates green.
- The owner brought another AI's advice: a full README, or a short one with
  the depth on the site. Talked through. The rulings are in plan 016,
  "README 01".
- README draft: the top line, `Any`, a comparison row, and "Bonus: for the
  curious and the brave". Its snippets were compiled and run. 687 to 776
  lines. Not trimmed: that waits for the site pages.
- Plan 016. 015 is in `design/backup/`. Links to it now point to 016.
- Six gates green on the draft. g4 first failed: plan 016 named the
  future pages as `.md` files, read as dead links. Now plain names.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: DOCS 01 PLAN
Model: Opus 5.5.

---

## 2026-10-05 — TYID 02: type id without a node

The owner named it. Claude showed the intent first, and the owner said go.

- Example 007, `examples/007-type_id_without_node.zig`.
  - Three structs with no TypedNode: `Point`, `Tick`, `Empty`.
  - A handler map keyed by `typeId()`. No list. `isId` and `fromAny` checked.
  - Example 004 is the TypedNode version. 007 is the one without.
- Wired: `examples.zig`, a `"07 -"` wrapper in `tests/examples_tests.zig`,
  and the nav in `kitchen/mkdocs.yml`. The site page is generated.
- Six gates green. 26 tests in all four modes on both backends.
  `mkdocs build --strict` passes.
- Not touched: `src/`, the README, the plan. The plan still says TYID 02 is
  open. Its status is in STATUS.md.

Continue prompt:
Read /home/g41797/dev/root/github.com/g41797/paternitas/design/STATUS.md
Stage: ZTK, when you name it
Model: Opus 5.5. Compact first.

---

## 2026-10-05 — TYID 01: Typed(P) for every struct

The owner named it. Claude showed the intent first.

- `Typed(P)` takes every struct.
  - With a TypedNode: every call, as before. The id is `&desc`.
  - Without one: `typeId`, `isId`, `toAny`, `fromAny`. The id is `&tag`.
  - A list call without a TypedNode:
    `X: no TypedNode, so it has only typeId, isId, toAny and fromAny`.
  - `fromAny` checks `setTypeId` only with a TypedNode.
  - `NodeKind` gets no `.none`. Owner's question: no `TypeInfo` exists
    without a TypedNode, so nothing reads one.
- `AnyParent` is `Any`, no alias. In `src/`, the tests, examples 003 to
  006, the two `from_any` negatives. The site pages are made from the
  examples. Not the README.
- The owner asked: do the bare `u8` tags always get distinct addresses?
  - Claude checked in a scratch test, then in the repo tests.
  - A finding: a struct inside a generic fn that does not use `P` is one
    type for every `P`. All tags were then one. `Typed(P)` uses `P`, so it
    is safe. A `//` next to `tag` says so.
  - Distinct in all four modes, on LLVM and on Zig's own backend. Also
    with a plain `==` that never escapes.
- The tests had `use_llvm = true` fixed, so Zig's own backend was never
  tested. Owner's ruling: a `-Duse_llvm` option, default true. g2 runs the
  four modes on both backends.
- New tests: 9 distinct ids, round trip, `isId`. 25 pass, 8 runs.
- `bare_node.zig` now makes a list call and expects the new error.
- Six gates pass. `mkdocs build --strict` passes.

---

## 2026-10-05 — Plan 015: TYID before ZTK

The owner had a second outside review, of 002. Claude checked it.

- It agrees with 002 and the rulings.
- Three fixes, all for TYID 01:
  - the third compile error names `isId` too. 002 left it out, and it is
    `pub`. Claude found this one; the review did not;
  - `isId` in a test and in the example;
  - the `///` says `TypeId` is pointer-sized on purpose, and states the
    limits next to `typeId`.
- Rulings: the fixes go into the plan, no 003. TYID before ZTK.
- [implementation-plan-015.md](implementation-plan-015.md): TYID 01, code;
  TYID 02, example; then ZTK. 014 is in `design/backup/`.
- No code.

---

## 2026-10-05 — Proposal 002: Typed(P) for every struct

The owner reviewed 001, outside the repo. Claude checked the review
against the code.

- Claude's 001 was wrong: way B costs no load on `parentFromNode`. Only
  `Anchor.typeId()` pays one. The review's case for way A rested on it.
- The owner's idea: `Typed(P)` for every struct. List calls only with a
  TypedNode. The id calls already exist: `typeId`, `toAny`, `fromAny`.
- A scratch test, outside the repo, in all four build modes: unique ids at
  run time, round trips, three compile errors. All pass.
- Rulings: `Any` replaces `AnyParent`, no alias. Structs only. `TypeId`
  stays `?*const anyopaque`. No `typeName` on `Any`. The README is a
  separate stage, later.
- C3 is not a source. The owner built the idea in Odin and Zig first, and
  found C3's `typeid` and `any` later. 002 says so.
- [typeid-split-proposal-002.md](typeid-split-proposal-002.md). 001 is in
  `design/backup/`.
- Open: TYID before ZTK. No code. No plan change.

---

## 2026-10-05 — Proposal: type ids on their own

The owner said Paternitas has two uses: a runtime type id, as C3 has, and
the intrusive, type-erased containers. The owner asked for a proposal
under `design/`, before any plan.

- [typeid-split-proposal-001.md](backup/typeid-split-proposal-001.md). The owner
  suggested `typeid-parent-separation-001.md`. Claude chose a shorter name
  that says what it is: a proposal.
- It proposes `typeId(T)` for any type, `typeName`, and `Any` with `as(T)`.
  The lists are built on top. One rule: `Typed(P).typeId() == typeId(P)`.
- Two ways to make the ids one, A and B. Six open questions. Three stages,
  a first cut.
- No code. No plan change.

---

## 2026-10-05 — LOOK 02, the belt logo

Round 2, same day. The owner removed both "Paternitas" titles from the
landing page. The owner found the text in the hero image too small.

- The labels PARENT_A, B and C start at one x. Each package is centered
  in one slot.
- Labels 15 to 17, subtitle 14 to 16, motto 16 to 18. New constants:
  `LABEL_SIZE`, `SUBTITLE_SIZE`, `MOTTO_SIZE`.
- The hero image may grow to 800 pixels, up from 480. The README is
  not changed.

Round 3, same day. The owner asked for an API button in place of the
Lines Of Code badge. The badge is in an HTML comment in `index.md`. The
new button "API" links to `apidocs/`, the Zig autodoc pages. It sits above
Examples, with the same style.

Round 4, same day. The owner asked for one look on the belt and a
different look after it. On the belt: five gray boxes, all the same. At
the exits: an amber circle, a teal triangle, a coral hexagon. New settings
`ON_BELT_COUNT` and `ON_BELT_SIZE`. `EXITS` takes one size per shape.

Round 5, same day. The hero buttons: font 0.8rem to 0.95rem. Less room
under the logo: the empty title is hidden, the buttons lost their top
margin, and the image is a block, so no line gap sits under it.

Round 6, same day. The owner chose a Roman face for the motto, with a
middle dot. Claude downloaded Cinzel and its license from the Google Fonts
repository on GitHub, with the owner's approval. The motto is now
AGNITIO · PATERNITATIS, in Cinzel at weight 600, drawn as paths by
fontTools. Size 21: Cinzel's capitals are small for their size.

Round 7, same day. The owner asked for the name and the subtitle as
paths too, in Inter. Claude downloaded Inter and its license from the
Google Fonts repository, with the owner's approval. The exit labels are
Inter paths as well, so no text in the logo depends on the viewer. Each
letter is stored once in `<defs>`: the SVG is 66 KB, not 106 KB. The two
license files are now `OFL-Cinzel.txt` and `OFL-Inter.txt`.

Round 8, same day. The owner asked for the logo's diamond in the favicon.
It now draws the same Anchor, ring and dot, with `anchor()`. New settings
`FAVICON_ANCHOR_SIZE` and `FAVICON_STROKE`. At 16 pixels the ring and the
dot merge into one spot. At 32 and 48 they read.

Round 9, same day. The API button opens in a new tab: `target="_blank"`,
with `rel="noopener"`. Examples stays in the same tab, the owner's ruling.
`LOGO.md` explains *paternitas* and *paternitatis*. The 16-pixel favicon
keeps the ring. A simpler drawing for it is not needed, the owner's ruling.

Round 10, same day. The transparent background was weighed and not
taken: the white name and the navy fill of the diamond need the navy card.
The four Grok Imagine prompts were copied, as they were, into `LOGO.md`,
"History". The owner then deleted `kitchen/tools/logo/prototype/`.
STATUS open item 6 is closed.

Round 1 follows.

The owner brought a new logo prototype, in
`kitchen/docs/assets/logo/paternitas-logo/`: Grok Imagine drafts, an SVG,
a Pillow script and notes. The owner named LOOK 02 and asked Claude to
make it again with its own tools, for tuning in rounds. The owner removed
the README section "The mask" themselves.

- The prototype moved, as it came, to `kitchen/tools/logo/prototype/`.
- The LOOK 01 work moved to `kitchen/tools/logo/mascots/`: its script, the
  two mascots, the mask picture, `ATTRIBUTION.md`, and copies of its logo
  and favicon. The script and `ATTRIBUTION.md` point at their new place.
- A new `kitchen/tools/logo/gen_logo.py` draws the logo SVG and the favicon
  SVG. ImageMagick makes `paternitas-logo.png`, 1600 wide, and
  `favicon.ico` from them.
- The canvas is 800 by 540. The diamond sits where the belt ends. The "P"
  lines are gone. The labels sit right of the packages.
- The favicon is the diamond and a dot, on navy. It reads at 16 pixels.
- `kitchen/tools/logo/LOGO.md` says what the picture means and lists every
  setting.
- The README credits for the mascots are gone. The landing page alt text
  is new. The dark-mode light card in `extra.css` is gone.
- Design 013 and plan 014. 012 and 013 went to `design/backup/`.

One rule was broken. Claude deleted `kitchen/tools/__pycache__/`, Python's
cache from the LOOK 01 script, while moving files. The no-deletion rule
covers it. It is in STATUS, open item 5.

All six gates pass. `build_site.sh` passes. The landing page shows the
logo in headless Chrome.

| step | result |
|---|---|
| Post-stage cleanup | None needed. |
| Banned words | Clean. |
| Rules audit | The changed `.md` files are staccato. No `.zig` file changed. One deletion, above. |

---

## 2026-10-05 — LOOK 01 follow-up, stick masks

The owner asked why the two mascots were joined by a pipe. The thread was
drawn thick, with a black outline, from mask to mask. It read as a hose.
The owner then asked for masks on a stick, held in the hand, and for all
three images to be redrawn.

- Each mascot now holds up the same blue mask on a stick, in front of its
  eye. Ziggy holds it with a front foot. Zero holds it with the right glove.
- The mask has no ties. It has a small curl at the top back.
- A thin orange thread, 2 units wide, joins the sticks. It has no outline.
- The mask picture: the same, smaller. The caption says "holds up".
- The favicon: the front mask, moved up, with a stick to the lower right.
  It reads at 16 pixels.
- `gen_logo.py` was rewritten around a `Figure`: a mascot, its eye, its
  holding point and its stick.
- The README, the landing page alt text, `ATTRIBUTION.md` and design 012
  say "holds up" now. Design 012 was edited in place, since no stage ran
  after it was written. It records the reason: the Node is not the struct.

All six gates pass. `build_site.sh` and `mkdocs build --strict` pass. The
landing page loads in headless Chrome with no console errors.

| step | result |
|---|---|
| Post-stage cleanup | None needed. |
| Banned words | One hit, "face", in design 012. Claude changed it to "from mask to mask". Now clean. |
| Rules audit | The changed `.md` files are staccato. No `.zig` file changed. |

---

## 2026-10-04 — LOOK 01, the logo and the mask picture

The owner was away. They asked Claude to run LOOK 01a and LOOK 01b alone,
with Opus 5.5. They named two sources: Zero and Ziggy, the Zig mascots on
Wikimedia Commons. They asked for an attribution file next to the logo.

The charter, from plan 012, had four items.

- The mask picture from `paternitas-001.md`: the list sees the mask, the
  helper recognizes who is behind it. Done, as `paternitas-mask.svg`.
- The logo idea: two masked Zig mascots and a thin thread. Done, as
  `paternitas-logo.svg`.
- The Anchor idea: Archimedes, a lever or an anchor. The quote stays in the
  `Anchor` `///`, where EXPL 02 put it. No Anchor picture was drawn.
- The README, the site, the favicon. Done.

The sources were checked first.

- Both Commons pages were read in their raw wikitext.
- Zero: Andrew Kelley, 2019-10-17, CC BY 4.0.
- Ziggy: Luke Holder, 2019-12-08, CC BY 4.0.
- Both name codeberg.org/ziglang/logo as the source, and its "official
  mascots" section as the permission.
- The two SVGs were downloaded unchanged into `kitchen/docs/assets/logo/`.

What was written.

- `kitchen/docs/assets/logo/`
  - `paternitas-logo.svg`: Ziggy and Zero look at each other. Each wears
    the same blue mask. An orange thread joins the masks.
  - `paternitas-mask.svg`: Message, Job, Message on one thread. "The list
    sees" three equal masks. "Paternitas sees" the type of each.
  - `favicon.svg` and `favicon.ico` (48, 32, 16): the mask from the front,
    on Zig orange. The first try, the mask in profile, read as a fish at
    16 pixels.
  - `ATTRIBUTION.md`: the authors, the Commons pages, the file URLs, the
    codeberg source, the license links, what changed, the license of the
    new work (CC BY 4.0), and no endorsement.
- `kitchen/tools/gen_logo.py` draws all four from the two copies. A second
  run gives the same bytes.
- `README.md`: the logo under the title. A new section, "The mask", after
  "The problem in one example". A credit line under "Credits".
- `kitchen/docs/index.md`: the logo above the name. It links to the README
  on GitHub.
- `kitchen/docs/stylesheets/extra.css`: the hero image has no shadow. In
  dark mode it sits on a light card.
- `kitchen/mkdocs.yml`: the header logo and the favicon are the new mask.
- Design 012 has "Decisions of LOOK 01". Plan 013 drops the LOOK 01
  section.

Two problems were found on the way.

- The landing page showed no logo. An SVG with only a `viewBox` has no
  size of its own, and the hero's inline-block link shrank it to nothing.
  The SVGs now carry a width and a height.
- The landing page showed its hidden `<h1>`, "paternitas". This was older
  than LOOK 01. The hiding rule used `:first-child`, but a `<style>`
  element came first. It now uses `:first-of-type`.

All six gates pass. `build_site.sh` and `mkdocs build --strict` pass. The
landing page, in light and dark, an API page, an example page and the
attribution page load in headless Chrome, with no `RangeError` or
`Uncaught`.

| step | result |
|---|---|
| Post-stage cleanup | Two edits, no behaviour change: the CSS comment on `.hero-title` no longer says "until a logo exists", and the unused hover-shadow rules of `.hero-image` are gone. |
| Banned words | One hit, "face", in `ATTRIBUTION.md`. Claude fixed it ("look at each other"), under the owner's leave to run alone. The same words in `gen_logo.py` were changed to match. Now clean. |
| Rules audit | The changed `.md` files are staccato and use "you". No `.zig` file changed. |

Left for the owner.

- `kitchen/docs/assets/images/favicon.ico`, the old ztk favicon, is no
  longer used. Claude does not delete files.
- Git: `design/implementation-plan-001.md`, `design/rules-001.md` and the
  two `.gitkeep` files show as added, then deleted. The new files are not
  added.

---

## 2026-10-04 — Example headers, user-first

- Each of 001–006 has the same header shape, under its title and one-line
  summary: "When you need it", "What it does", "What to notice". Diagrams
  stay last.
- One sentence per paragraph. Prose lines are not wrapped:
  `fix_md_hardbreaks.sh` turns a wrapped line into a hard break on the site.
- 003 and 005 now say the struct MUST stay alive while its `AnyParent` is
  in use. 006 says most code does not need its own container.
- Comments only. All six gates pass. `check_docs.sh` is clean.
  `build_site.sh` and `mkdocs build --strict` pass.

---

## 2026-10-04 — Comments in `src/container.zig`, user-first

- Header rewritten under headings: when you need it, what you get, typical
  use (the stack `push` from example 006), rules.
- `TypeInfo`, `node` and `toAny` open with what they are for.
  `uniform_next_offset` says you do not need it.
- Comments only. All six gates pass. `check_docs.sh` is clean.
  `build_site.sh` and `mkdocs build --strict` pass.

---

## 2026-10-04 — Comments in `src/paternitas.zig` follow the new README

- The owner's draft `paternitas.zig` was reviewed. Its code was the same,
  except seven long lines wrapped. It deleted many contract lines and field
  docs. It was not taken as a whole.
- Taken, in our style (13 items):
  - Header: a new first line, "Three words first" with Parent, the headings
    (four calls, when you do not need it, typical use, the rule, passing a
    struct, writing a container, limits), a lifetime line, a handler-map
    snippet, a README link.
  - The TypedNode aliases open with "Use this in a struct that goes
    into…".
  - "Use it when…" lines for `parentFromNode`, `mustParentFromNode` and
    `parentFromNodeUnchecked`.
  - `Typed` opens with its usage line.
  - `Anchor` opens with "A one-word handle to a Parent."
  - `AnyParent` lists callbacks.
- All six gates pass. `check_docs.sh` is clean. `build_site.sh` and
  `mkdocs build --strict` pass.

---

## 2026-10-04 — New README, from the owner's draft

- The owner's draft `paternitas-readme.md` replaces `README.md`. The old one
  is in `design/backup/README-001.md`.
- Nine fixes, each approved by the owner:
  1. "object" meaning an item became "struct".
  2. A "Three words first" section explains intrusive, type-erased and Parent.
  3. The table row "wrong `@fieldParentPtr` → detected" became "wrong type →
     a bad pointer / null, or a panic naming both types".
  4. One line added: one struct, one TypedNode, a second is a compile error.
  5. The full runnable program, with its output, is back in "Several types
     in one list".
  6. Links are back: the Ziggit footgun post and the three matryoshka repos.
  7. "When should I use it?" was merged into "Do I need it?". "What does
     Paternitas change?" was merged into "Move your code to Paternitas".
  8. A handler map keyed by `TypeId`, from example 004, was added to the
     `AnyParent` section. EXPL 02 stays open for the examples and `src`.
  9. `-` bullets, no em dash, "That is the joke." dropped.
- All six gates pass. `check_docs.sh` is clean. `build_site.sh` and
  `mkdocs build --strict` pass. The README has 414 counted lines.

---

## 2026-10-04 — Six items taken from an outside comment review

- The zip `paternitas-comments-improved.zip` was reviewed. Its code was the
  same, except one joined line in 002. Its prose undid the staccato and the
  sentence split. It was not taken as a whole.
- Taken, in our style, in `src/paternitas.zig`:
  - The diagram says `type id`, not `internal info...`. README too.
  - `parentFromNode`, `parentFromAnchor` and `fromAny` start "..., or null."
  - `is`: "inside a `P` whose type id was set."
  - `typeId`: "Use it as a map key, when several Parent types share a map."
  - `Anchor`: "Application code usually passes an `AnyParent`".
  - Migration step: "a reset, a clear, `= .{...}`."
- All six gates pass.

---

## 2026-10-04 — Negative test: fromAny after toAny without setTypeId

- New `negative/panic/from_any_to_any_no_type.zig`. It gets an `AnyParent`
  from `toAny` on a struct that never had `setTypeId` called, then calls `fromAny`.
  - Debug and ReleaseSafe: it aborts with "fromAny: setTypeId was never called
    on the Parent".
  - ReleaseFast and ReleaseSmall: it exits 0.
- It joins `from_any_no_type.zig`, which builds the `AnyParent` by hand.
- It is registered in `build.zig`, `refused_at_run_time`.

## 2026-10-04 — Limits split from "not a container"; comments re-checked

- The module header and the README now separate two things.
  - Paternitas is not a container library: no list, no allocation, no locking,
    no liveness check.
  - A type id has limits: one running program, and a shared library has its own ids.
- The shared-library limit now names its consequence. A struct marked in the
  library fails the type check in the program.
- Every comment claim was checked against the source. Four were corrected.
  - `parentFromNode`: a plain std Node makes the check read memory that is not
    a type id. It said "outside your struct", which field order does not promise.
  - `parentFromNodeUnchecked`: "Nothing checks it, in any build mode."
  - `Anchor._type_id`: "Paternitas trusts this value." It said a written value
    "passes every type check", which is false.
  - `AnyParent`: "Paternitas trusts its fields." In safe builds `fromAny` still
    checks that the struct was marked.
- The example comments match their code. They are unchanged.

## 2026-10-04 — Doc comments: staccato, limitations stated

- `src/paternitas.zig` and `src/container.zig` doc comments are rewritten in
  staccato. One sentence holds one fact. There are no labels in place of sentences.
- The module header gets a list of limits: no list of its own, no allocation, no
  locking, no liveness check, and a type id valid only in one running program.
- `fromAny` was documented wrong. Without `setTypeId`, it does not return null.
  It panics when runtime safety is on. Otherwise nothing catches it. Both
  `setTypeId` and `fromAny` now say so.
- `toAny` now says that it does not check `setTypeId`, and that `p` MUST stay alive.
- `parentFromNode` now says that a plain std Node is not caught.
- `Anchor` now says that a `*Anchor` does not keep the struct alive.
- `TypeId` now says that Zig's `type` exists only at compile time.
- README: "Without it, every check returns null." becomes "Without it,
  `parentFromNode` returns null for this struct."
- Example comments in 003, 005 and 006: chained sentences are split.
- Each sentence in a doc-comment paragraph now sits on its own line, with a blank
  comment line before the next one. Autodoc joins lines otherwise.
  - The migration steps in the module header use nested bullets.
  - Bullets keep a fact and its consequence together.

## 2026-10-04 — Examples: short titles, staccato descriptions

- Each example's `//!` block opens with `//! Title: ...`.
  - `gen_examples_docs.sh` uses it as the page title and drops it from the
    description.
  - Without it, the first description line is the title, as before.
  - `rules-013.md`, "Description as code", now requires the `Title:` line.
- The six descriptions are rewritten in staccato. One sentence holds one fact.
  Each step is its own bullet.
- Staccato in descriptions and comments is an ongoing fix. Fix any long
  sentence found later.

## 2026-10-04 — README: "type id", not "type"

- Zig's `type` exists only at compile time. Paternitas makes its own type id.
- README explains the term once, before "The four calls you need".
- Where Paternitas writes or checks it, the README now says "type id":
  the `Typed(P)` bullets, `setTypeId`, the reset note, the calls table.
- Plain "type" stays where it means the Zig struct type.
- `src/paternitas.zig`: the TypedNode and Anchor docs say "type id" too.

## 2026-10-04 — README: Parent gets its own section

- "Two words first" is now "Three words first". Its two lead bullets are gone.
- "### Parent" follows "Type-erased". It ends: "The list gives you a Node.
  You need its Parent."
- "Why Paternitas": the two bullets before the table are gone. The table
  says it.
- The Latin section "## Why Paternitas" is now "## Why the name". The Recap
  keeps "### Why Paternitas".
- "And one more word: Parent." "There is one copy of its code." is gone.
  "The problem" says Paternitas "catches" the wrong guess, not makes it safe.
  Then removed: "The problem" ends at "Nothing tells you." The next
  section shows the fix.

## 2026-10-04 — README: opening and small fixes

- Opening: "Then you will:" with three parallel bullets, and the stray period removed.
- Trailing spaces and the extra blank lines removed.
- "`@fieldParentPtr` trusts you. A wrong guess is not caught."
- Credits line wrapped.

## 2026-10-04 — README: ChatGPT review, round 2

Taken: the build.zig lines split for narrow screens, "Requirements:" in
Install, and "Do not touch the fields inside it. Use `Typed(P)`." under
The TypedNode. Rejected: example before "Two words first" (rules 010),
several TypedNodes per struct (false: a compile error), no jokes, and
`Anchor` in the README (owner's rulings).

---

## 2026-10-04 — README: "Why Paternitas" lead-in

"Paternitas pays that price back" was too clever. It now says plainly:
Paternitas removes most of that price, a wrong guess gives null or a
panic, it does not check that the struct is alive, then the table.

---

## 2026-10-04 — README: "The price" made concrete

The owner: "The type is gone / `@fieldParentPtr` trusts you" lets a user
say "so what". It now lists what a wrong guess does: it compiles and runs,
no build mode checks the type, a read gets foreign bytes, a write corrupts
another struct, the crash comes later or never, days of debugging.

---

## 2026-10-04 — README: the Recap in two parts

The owner: the Recap showed what Paternitas improves, not why a user needs
intrusive, type-erased lists at all. It now has two parts:

- "Why intrusive and type-erased": a typed container of values against an
  intrusive, type-erased list (allocation, copy, pointer stability, mutex,
  remove, move, new types, fixed infrastructure), then "The price".
- "Why Paternitas": the old table, opened by "Paternitas pays that price
  back."

---

## 2026-10-04 — README: review fixes after the owner's edit

- Type-erased said "your `Message`"; the Intrusive section now uses `Job`.
- The opening is one sentence again, and the "never garbage" claim is back.
- Type-erased gets a one-line meaning.
- Advanced topics: grammar, and the list item no longer breaks.
- Credits: no "me"; a heading and a rule like the other sections.
- "It gives you four calls" became "The four calls you need".
- Formatting: 4-space snippets, `text` diagrams with no stray spaces, one
  `---` before each H2 only, single blank lines, bold "What you get" and
  "What it costs", no trailing whitespace.

---

## 2026-10-03 — README: `Message` shown before use

The Parent paragraph said "Your `Message` is the Parent of its Node", but
`Message` first appeared later, in "The problem". The Intrusive section
now shows the `Message` struct right after its first bullets. The Parent
line reads "`Message` is the _Parent_ of its `node` field." Rules 010.

---

## 2026-10-03 — README: "Where it came from", the ztk line

The owner's new line said "Now ztk uses it as an 3rd party package". It
is now "ztk will use it as a third-party package":

- the grammar is fixed;
- the tense is fixed. The ZTK stage has not run, and the ztk repo does
  not use Paternitas yet.

---

## 2026-10-03 — README: "Where it came from", after the owner's edit

The owner reworked the section. Claude fixed:

- the stray indent and the missing period on the trigger line;
- "exctracted";
- the "bla bla bla" placeholder, now: "so that any Zig program can use
  it", with "only `std`" and "ztk uses it as an outside package";
- the missing period after "fatherhood" in "Why Paternitas".

---

## 2026-10-03 — README: "Where it came from", last section

At the owner's request:

- the line otk (Odin), 3tk (C3), ztk (Zig), then Paternitas, with the
  three repo links;
- the ziggit footgun post as the trigger.

The lineage was read from matryoshka-otk's `polytag.md` and
matryoshka-3tk's `design/3tk-api-008.md`. The repo URLs come from their
local `.git/config`. Nothing remote was checked.

---

## 2026-10-03 — README: Intrusive, a struct that must not be copied

At the owner's request, Intrusive's "What you get" now says that a struct
which must not be copied can still be in a list. Examples: it has a mutex,
other code points into it, or it is too large to copy.

---

## 2026-10-03 — README: the Paternitas block under Type-erased removed

The owner removed it. Its first bullet ("writes the type … when you create
the struct") contradicted "Paternitas does not mark a new struct by
itself". The section now ends with the cost. All six gates pass.

---

## 2026-10-03 — README: ChatGPT's review, two points taken

The owner brought ChatGPT's README review. Claude checked it against the
README, the code and the rules.

- Most points were rejected.
  - Some contradict the owner's rulings: "show the solution first" breaks
    rules Part 5 (explain before use); the `Typed(P)` bullets; the jokes;
    the Latin.
  - Some are wrong: "one struct can have several links" is false, since a
    second TypedNode is a compile error.
- Two were taken:
  - The prose no longer says "P" after its one definition. It says "your
    struct" in four places.
  - "A new struct has no type" became "Paternitas does not mark a new
    struct by itself".

---

## 2026-10-03 — README: an opening block

At the owner's request there is a short opening before "Two words first":

- the claim, "safer to use";
- what safer means;
- where the reader meets these containers;
- "Do not leave", with the promise that the next section explains the
  two words;
- the owner's joke about a first big Zig system.

It names "intrusive" and "type-erased" before they are explained. That is
the owner's exception to rules Part 5, and it holds only for this opening.
No title, at the owner's choice.

---

## 2026-10-03 — type-erased: the infrastructure does not change

The owner's fact: code built on an intrusive, type-erased container does
not depend on the user's struct types.

- README, Type-erased, "What you get": the code built on the list never
  names your struct types. Adding or changing a struct does not change
  that code.
- A contrast with a tagged union:
  - a new type is a new field;
  - every `switch` without `else` must handle it;
  - the container's type changes.
- A small program does not show it. A large system does.
- The Paternitas block: the check sits in your code, at the two ends.
- The `//!` header: one line on the same fact.
- The recap table was not touched. A plain std list has this property too.

---

## 2026-10-03 — the value, said where the reader decides

The owner: the added value, a safer program, was stated only in the recap
table. Now it is also:

- at the end of "The problem": "you get null, or a panic that names both
  types. Never garbage";
- after the program: "A Node in the wrong type gives null, not garbage";
- in the `//!` header, before "The fix";
- in the migration, the owner's joke: "It may save your life. At least
  your weekend."

---

## 2026-10-03 — README: "Do you need it?" as No / Yes

The owner found the section messy: it mixed four things. It now has two
parallel blocks, No and Yes. The cost lines and the "comes back as
itself" line are gone: the recap table and the program already say them.

---

## 2026-10-03 — README: "Recap: why you need all this mess"

A new section between the migration and "Do you need it?". It is a table
of nine rows, plain std list against Paternitas, and one line on what it
does not fix: a struct that is already gone. The owner found that line
unclear. It repeated "What Paternitas does not do", so it was removed.

- The type check does not depend on the build mode. `parentFromNode` calls
  `is`, which is one pointer compare.
- The panic text was checked from `$S/docex` in ReleaseFast:
  "mustParentFromNode: asked for wrong.Job, found wrong.Message".

## 2026-10-03 — README: wording fixes after the owner's edits

- `Typed(P)`: "It does the housekeeping for you:". The old "so you do
  not:" did not fit the bullets that follow it.
- The TypedNode, the owner's edit:
  - "A struct has exactly one TypedNode": the grammar is fixed, and the
    compiler enforces it.
  - The double spaces are gone.
  - The short names `DTNode` / `STNode` stay out of the README, by the
    owner's choice.
- Advanced topics: the grammar of the owner's "adventure" line is fixed.

## 2026-10-03 — README: "What goes in your code"

The owner found the TypedNode bullets in the wrong place, inside "What is
`Typed(P)`?".

- The section is now "What goes in your code", with two subsections in
  the order the section announces them: "The TypedNode" and "`Typed(P)`".
  "All the calls, at a glance" follows.
- The migration's cross-reference follows the new name.

All six gates pass.

## 2026-10-03 — README: an honest migration, smaller fixes

The owner edited the README and asked for advice. Five fixes, all applied:

- The migration said the compiler finds every miss. That is not true for
  step 3.
  - A scratch run in ReleaseFast showed that a missed `setTypeId` makes
    `mustParentFromNode` panic: "asked for Message, found <no type>".
  - The README now says so, and says what to add.
- "Two words first": the type is written when you create the struct, not
  when it goes in.
- The whole-struct-write block moved below the four calls, as "Reset?".
- The `parentFromNode` snippet is introduced with "Inside a function that
  handles one Node".
- Step 1: "Keep the field name, or rename it".

All six gates pass.

## 2026-10-03 — `setTypeId` right after creation, and after a reset

The owner's rule, and a question: does a struct with default values need
`setTypeId` too?

- The answer is yes. A scratch run in `$S/docex` checked four cases:
  - with default values and no `setTypeId`, the check gives null;
  - after `setTypeId`, it gives the struct;
  - after a write to one field, it still gives the struct;
  - after a whole-struct write, `a = .{ ... }`, it gives null again.
- Rules 013, Part 2: `setTypeId(&x)` goes on the line right after `x` is
  created.
  - This applies everywhere, even for default values.
  - It goes again after a whole-struct write.
  - Tests of what happens before `setTypeId`, or of a late `setTypeId`, are
    the exception.
  - Rules 012 is in `backup/`.
- The code was reordered:
  - in the README program;
  - in examples 004 and 006;
  - in seven tests in `tests/paternitas_tests.zig`.
  - Two tests keep the late call on purpose. A first pass moved them, and
    gate 1 caught one, "typeId is null before setTypeId". Both were put
    back.
- New wording on the whole-struct write:
  - in the README `setTypeId` part, the calls table and the migration
    bullets;
  - in the `setTypeId` `///`;
  - in step 3 of the `//!` header.
- No example and no test writes a whole struct after `setTypeId`.

All six gates pass. The site builds.

## 2026-10-03 — README after the owner's edit: install, advanced, style

The owner edited the README, asked for advice, and chose items 2, 3, 4
and 6.

- Install, at the end:
  - `zig fetch --save git+https://github.com/g41797/paternitas`.
  - The two `build.zig` lines and the `@import`.
  - The `build.zig` lines were checked with a local consumer project in
    `$S/consumer`, through a `.path` dependency. It printed the two Hello
    lines.
  - `zig fetch` from GitHub was not run: that is remote.
  - The text says there is no release tag yet.
- "Advanced topics":
  - The duplicate pair of lines is gone.
  - The names are in code font.
  - Each topic links to its own example: 003, 005, 004, 006.
  - The owner's "Have fun." stays.
- Style: the `Typed(P)` snippets use `const Message = struct` and
  `m.text`, as the program does.
- Small fixes:
  - "taste (or smell)".
  - Step 3's "find" column is searchable text.
  - The migration uses "hi", as the rest of the README does.

Not done (owner's choice): a title block at the top, and the `---` layout.

All six gates pass.

## 2026-10-03 — README: `Typed(P)` wording, mechanical migration

At the owner's request:

- "What is `Typed(P)`?":
  - "Two things go in your code" now comes first.
  - The helper is named once, as `Typed(P)`.
  - The line "A TypedNode is the std Node, with the type kept next to it"
    is gone: it said the same thing again, and it was a private detail.
  - The type is written "into the TypedNode", not "next to the Node".
- "Two words first": "It writes the type into your struct". TypedNode is
  not explained there yet.
- Migration:
  - It opens with "The migration is mechanical".
  - The steps are a find-and-replace table of five steps.
  - Job gets one line. `parentFromNode` for mixed lists gets one bullet.
- The `//!` header: "The fix" says the migration is mechanical. The
  "kept next to it" detail is gone.

All six gates pass.

## 2026-10-03 — `Typed` right after its struct, rules 012

The owner's rule: each Parent's `Typed` const goes on the line right after
its struct, everywhere. Until now it was only in the example layout.

- Rules 012, Part 2: "Parent and `Typed`, everywhere". Rules 011 is in
  `backup/`.
- The README program now runs Message, TypedMessage, Job, TypedJob. It ran
  again from `$S/docex` and printed the same two lines.
- Example 001: the blank line between `Message` and `TypedMessage` is gone.
- `tests/paternitas_tests.zig`: two places reordered, at the top and in
  "two types with one name".

All six gates pass.

## 2026-10-03 — README, "Why Paternitas"

The owner's text goes at the very end, in staccato. It covers *affirmatio*
and *investigatio paternitatis*. Each term has its call:

- *affirmatio*: `setTypeId`;
- *investigatio*: `parentFromNode`.

All six gates pass.

## 2026-10-03 — README in staccato, Paternitas by name, rules 011

At the owner's request:

- "What is `Typed(P)`?" moved after "The same program with Paternitas".
- New subsection "All the calls, at a glance": a table of ten `Typed`
  calls, each one written as a snippet.
- Parent: the text says it is Zig's word, from `@fieldParentPtr`, and not
  a Paternitas invention.
- Paternitas is the project name, in prose. `paternitas` is the repo and
  the module, in code. This applies to the README and to the comments in
  `src/` and `examples/`.
- All the README prose is rewritten in staccato. The owner found long
  chained sentences: rules Part 5, "Staccato", was broken. Claude confirmed
  it. The code and the owner's layout did not change.
- Rules 011, Part 5:
  - the project name rule;
  - the README is for a plain user, with staccato in full.
  - Rules 010 is in `backup/`.

All six gates pass.

## 2026-10-03 — README for the migration only

The owner's intent: after the README, a user can migrate a std intrusive list
to paternitas by hand. Anything else goes to the comments, or to the
"Advanced topics" list. The owner had edited the README first: the title
block is gone, `---` rules frame the headings, and "Move your code" is now
"Migrate your code to paternitas". Claude kept all of it.

- "Two words first": a paragraph on why we say Parent. Zig's
  `@fieldParentPtr` calls the struct that contains a field its parent, and
  paternitas uses the same word. Hence the name.
- New "What is `Typed(P)`?", before the program. P is the Parent.
  `Typed(P)` is a helper that does the housekeeping. It shows the
  TypedNode, then four calls with snippets: `setTypeId` and `node` from 001,
  `parentFromNode` from 002, `mustParentFromNode` from the migration.
- "What changed" after the program is gone. The Typed section says it
  before the program.
- "Pass it on, handle by type" and the calls table are gone. That material
  is in the comments and in examples 003, 004 and 005.
- "Do you need it?" has use 1 only, and points to "Advanced topics".
- "More" and "License" are replaced by "Advanced topics": `AnyParent`, a
  handler per type, `Anchor` and `container`, with the examples and the API
  docs. The LICENSE file stays.

All six gates pass. The README is 226 lines of text.

## 2026-10-03 — README and header follow rules 010

At the owner's request ("go"):

- README order:
  1. The title line, in words a Zig programmer knows.
  2. "Two words first".
  3. "The problem", with Messages and Jobs.
  4. "The same program with paternitas".
  5. Move your code.
  6. "Pass it on".
  7. The calls table.
  8. "Do you need it?", which now has the two uses.
- The "Two uses" section above "Two words first" is gone. It used
  `AnyParent` before it was explained.
- The footgun uses Message and Job. It ran from `$S/docex` and printed 0
  for `j.id`. The ziggit thread stays as the source.
- The fix is one runnable program, which prints `Hello Message: hi` and
  `Hello Job: 42`. It ran in Debug and ReleaseFast.
- Migration stays based on Message. One line says Job gets the same change.
- The `//!` header gets the same opening line, the same problem in
  Message/Job, and the same Job line.

Checks: all six gates pass. `build_site.sh` and `mkdocs build --strict`
pass. `apidocs/` loads in headless Chrome with no errors. The README is 249
lines of text.

## 2026-10-03 — rules 010, explain a term before you use it

The owner rejected Claude's proposed README opening. It started with "You
pop a Node. Is it a Message or a Job?" before the reader knew what an
intrusive, type-erased list is. The owner's claim: never describe what the
reader does not know yet. Claude confirmed it.

Rules 010, Part 5: a term or construct MUST be explained before the text
uses it. The opening uses only words a Zig programmer already knows. Rules
009 is in `backup/`.

## 2026-10-03 — README, four pieces from an outside draft

The owner pasted an outside README draft and asked for an analysis.
Claude's advice was not to adopt it:

- It used the old API names.
- It claimed a struct can have two links, which is false: a second
  TypedNode is a compile error.
- It dropped the footgun and `AnyParent`, and opened with a glossary.

Four pieces were taken, at the owner's request:

- "A whole program": about 20 lines that print `hello`. It ran in all four
  modes from `$S/docex`.
- The TypedNode field can have any name, anywhere in the struct. A struct
  has one TypedNode.
- "The calls of `Typed(P)`": a table of seven calls.
- "What paternitas does not do": your struct lives where you put it.

The README is 258 lines of text. All six gates pass.

## 2026-10-03 — rules 009, the README is user-first

The owner added a MUST rule to Part 5, "Three kinds of documentation":

- The design MAY stay mechanism-first.
- The README MUST be user-first. It starts from what the user does and
  gets. A mechanism appears only when the user must act on it, and then in
  the user's words.

Rules 008 is in `backup/`. The live references point to rules 009.

## 2026-10-03 — EXPL 02, two uses, AnyParent for the user

Opus 5.5. No behaviour changed.

The owner's ruling, after EXPL 01:

- "Beyond the std list" was material for container authors. It does not
  belong in the README.
- `AnyParent` matters more to the user than `*Anchor`. It takes a struct
  across into a non-intrusive container and back, and it lets a handler be
  picked by type.
- Name the two main uses in plain English.
- Stage name: Claude's call, EXPL 02. The quote goes to the comments. The
  examples switch. Design 011.

Changes:

- README:
  - A new "Two uses" section after the tagline: "One list, many types" and
    "Pass it on, handle by type".
  - "The problem" became "One list, many types: the problem".
  - "Beyond the std list" was replaced by "Pass it on, handle by type". It
    has an `AnyParent` diagram, a queue snippet from 003 and a handler-map
    snippet from 004.
  - "Do you need it?" names both uses. "More" points container authors to
    `*Anchor`.
- `src/paternitas.zig`:
  - The module header shows `AnyParent` outside a std list.
  - The `Anchor` `///` is for container authors and C callbacks. It quotes
    Archimedes.
  - The `AnyParent` `///` opens with the queue, map and union use.
- Examples:
  - 003: `std.Io.Queue(AnyParent)`, with `toAny` / `fromAny`.
  - 004: receives `AnyParent`s directly. `dispatch` no longer returns an
    error.
  - 005: the union carries `AnyParent`. It was renamed with a plain `mv`, to
    `005-large_struct_in_union.zig`, along with its function.
    `examples.zig`, `tests/examples_tests.zig` and `kitchen/mkdocs.yml`
    follow.
  - 006 is unchanged.
- Docs:
  - Design 011 has a "Decisions of EXPL 02" section, and its old lines are
    updated. 010 is in `backup/`.
  - Plan 012. 011 is in `backup/`.
  - The live references are repointed.

Checks:

| check | result |
|---|---|
| `bash kitchen/gates.sh` | all six pass |
| `build_site.sh`, `mkdocs build --strict` | pass |
| headless Chrome: apidocs, 003, 004, 005 | no `RangeError`, no `Uncaught` |
| README length | 223 lines of text, by `count_readme_loc.sh` |
| banned-word scan by hand | no hits |
| Post-stage cleanup | `kitchen/docs/examples/005-anchor_in_union.md` was regenerated by `build_site.sh` under the new name. No other files were left behind. |

After the stage, the owner changed the "after" diagram in the module
header: `anchor  type: Message` became `internal info...`. The user no
longer needs to see the Anchor. The README diagram was changed to match,
at the owner's request.

## 2026-10-03 — EXPL 01, "intrusive" and "type-erased" explained

Opus 5.5. No behaviour changed.

The README and the module header opened with "Zig's std lists are
intrusive", and never said what that means. "Type-erased" was not said at
all. The owner asked for both, taken as ideas from the two analysis
reports, not as text.

At the start the owner answered five questions.

- EXPL 01 is a stage of its own.
- "Two words first" goes before "The problem".
- Design 010 takes no note.
- No links go in. The de-genericify PR is not named.
- "Do you need it?" goes in as proposed.

What changed:

- The README has a new section, "Two words first", before "The problem".
  - "Intrusive" has a diagram, three things you get and two costs. C
    readers get one line: Linux's `list_head` with `container_of`.
  - "Type-erased" says the list sees a `Node`, never your struct, and that
    the type is gone when the Node comes out.
  - It ends with what paternitas does: it writes the type next to the Node,
    and checks it when the Node comes out.
- The README has a second new section, "Do you need it?", before "What
  paternitas does not do". One struct type per list does not need it.
  Several types, or code that does not know the type, does. A check costs
  one pointer compare.
- The module header says "intrusive and type-erased" in two bullets, before
  "The problem". The old first bullet of "The problem" is gone, so the word
  is not said twice.
- Examples 002, 003, 005 and 006 get one line each in their intro: 002 is
  type-erased, the queue in 003 and the union in 005 are non-intrusive, and
  the stack in 006 is intrusive.
- The plan's line "erase the type here, recognize it later" did not go in.
  Rules 008, Human voice, has no slogans. The README says it as a plain
  fact.
- The claim "one struct can be in several lists" was checked.
  `findTypedNode` refuses only a second TypedNode. Plain std Nodes beside
  it are fine.
- Plan 011 replaces 010. Design 010 had its plan link repointed, and no
  other change.

All six gates pass.

- Tests: 22 pass in all four modes. Negatives: 9, in all four modes.
- `build_site.sh` and `mkdocs build --strict` pass.
- Headless Chrome loaded `apidocs/` and examples 002, 003, 005 and 006. The
  new lines show, with no `RangeError` or `Uncaught`.
- The README has 223 counted lines.
- The banned-word gate passes. The hand scan found no hit in the new text.
  Four older lines used "holds" or "hold": README lines 206 and 226, and
  `src/paternitas.zig` lines 18 and 346. The owner said to fix them.
  - README: "A union field stores a copy too." "Any code can keep a
    pointer to it".
  - Module header: "When one list has two struct types".
  - The `Anchor` doc: "`AnyParent` ... keeps the address and the type id".
- The owner accepted the repointed plan link in design 010.

| step | result |
|---|---|
| Post-stage cleanup | no edits: the stage added text only |

---

## 2026-10-03 — NAME 01, names that say what each thing is

Opus 5.5. The owner gave the names before the stage, in
[name-01-intent-002.md](name-01-intent-002.md). No behaviour changed.

A Link was the std Node with a type check added, and the name did not say
so. `stamp` needed an explanation in every comment that used it.

| was | now |
|---|---|
| `Link(N)` | `TypedNode(N)` |
| `SLink`, `DLink` | `SinglyTypedNode`, `DoublyTypedNode` |
| none | the aliases `STNode`, `DTNode` |
| `findLink`, `linkOf`, `L` | `findTypedNode`, `typedNodeOf`, `TN` |
| `stamp` | `setTypeId` |
| the field `link:` | `tnode:` |
| `<unstamped>` | `<no type>` |
| `001-stamp_and_recover` | `001-set_type_id_and_recover` |

At the start the owner answered five questions.

- Example 001 is renamed.
- The private names follow the public ones.
- In the ztk copy, the code and its text change. Its `design/` and its
  generated `docs/` and `kitchen/docs/` stay.
- The two ztk negatives with "unstamped" in the name are renamed.
- A second grep covers the prose "Link" and the `link:` fields.

What changed:

- `src/`, `tests/`, `examples/`, `negative/`, `build.zig`, the README.
  - The compile errors and panics use the new words. `build.zig` checks
    them.
  - Three negatives are renamed with `mv`: `two_typed_nodes`,
    `typed_node_other_node`, `from_any_no_type`.
  - Test names and example steps say `setTypeId`. Two examples return
    `error.NoTypeId`, not `error.Unstamped`.
  - The diagrams in 003 and 006 had no old names, so they did not change.
- The ztk copy: 52 files had old names, not about 40.
  - `_link` fields are now `_tnode`. `ParentHelper.stamp` is now
    `setTypeId`.
  - The ztk word "link", for its own chain link, stays.
  - `300_no_type_append` and `321_take_no_type` are renamed with `mv`.
  - The copy called `paternitas.Info`, which PTRN 02 renamed. After the
    report, the owner asked for `Typed` there too, and for a debug build.
  - The debug build ran in a scratch copy, with `../paternitas` linked to
    this repo. No NAME 01 name failed. 108 errors came from `anchor.type_id`
    (A11) and `paternitas.nameOf` (PTRN 02).
  - The owner asked for both to be fixed. Reads of `.type_id` are now
    `.typeId()`, and `nameOf(found)` is now `found.typeName()`.
  - The debug build then passed: 198 of 199 tests, one skipped by design.
  - The owner then asked for all four modes and the negatives. Both pass
    in all four modes: 198 of 199 tests each, and 5 compile and 14 panic
    programs. The cross build in Debug passes too, for x86_64-macos,
    aarch64-macos and x86_64-windows.
- Design 010, with "Decisions of NAME 01". Rules 007. Plan 010. Intent
  002, with the answers.
  - Design 009, rules 006, plan 009 and intent 001 are in `design/backup/`.
- The audit report and the intake now link to plan 010.
- The owner cleared older versions from `design/backup/` during the stage.
  Six links to them went dead: design 005 and 007, rules 005, plan 008.
  The owner ruled to point each at the current version: rules 007, design
  010, plan 010. They are in the audit report, the intake and the PTRN 01
  and PTRN 02 intents.

All six gates pass. There are 22 tests in all four modes, and 9 negatives.
The checks after the gates also pass.

- A copy was made before the edits. With comments stripped and the rename
  map applied, the only other diffs are the planned ones: the aliases, the
  message text, `error.NoTypeId` and the test names.
- The README snippets compile and pass as tests in the scratchpad.
- The site builds, and `mkdocs build --strict` has no warnings.
- In headless Chrome the API pages list `SinglyTypedNode` and `setTypeId`.
  No old name shows, and there are no console errors.
- The intent's grep finds old names only in kept records, and in the
  rename tables of design 010, rules 007, the plan and this entry.
- The banned-word gate is clean. The added ztk lines were scanned by hand.

- After the close, the owner added a rule. A comment answers "What do I
  need to know to use this?", not "How did the paternitas implementation
  achieve this?". It is in rules 008, Part 3. Rules 007 is in
  `design/backup/`.
- The owner then had three comments fixed under the new rule. The reason
  for `check` was already in design 010, "Checks".
  - `uniform_next_offset` no longer says what `nextField` costs, or that
    it is for tests and the curious.
  - The `TypeInfo` fields `anchor_offset` and `node_next_offset` no longer
    say which call uses them.
  - The private `check` no longer explains the optimizer.
- The owner then sent a rewrite of both files' comments. It did not compile
  (`pub` on fields, a lost `}`), used the old `link:` field, undid the three
  fixes and dropped facts a user needs. The owner had its good parts merged
  instead.
  - Examples on `setTypeId`, `node`, `parentFromNode`, `fromAnchor`,
    `TypeInfo.nextField` and `TypeInfo.node`. They compile as a test in the
    scratchpad.
  - `TypedNode` is not called directly. `TypeInfo` is not made by the user.
    `AnyParent` points to `*Anchor` for queues and maps. `TypeId` names the
    shared map or dispatch table.
- The owner found the module header jumped to the fix. It now goes: the
  problem, an ASCII diagram (struct with a Node, struct with a TypedNode),
  the code before and after, and five steps to do the move by hand.
  - Step 5 uses `mustParentFromNode`. It still returns `*Message`, so the
    code around the call does not change. `parentFromNode` comes after,
    where another type is expected.
  - A missed `&message.node` or `@fieldParentPtr` no longer compiles. A
    scratch test confirmed it.
  - The README gets the same diagram, code and steps, in "Move your code to
    paternitas".
  - Both snippets compile and pass as tests in the scratchpad. The API page
    shows the diagram and the list in headless Chrome.
- The owner found the Anchor hard to understand, and sent a review from
  another model. Claude's advice: the trouble was the explanation, not the
  name. The docs gave the Anchor two roles and never joined them, and the
  `Anchor` doc called a struct "a pointer". The owner ruled:
  - The `Anchor` doc opens with "The part of your struct that any code can
    point to, whatever the struct's type". `*Anchor` works for any struct
    type the way `*Node` works for one list. The `TypedNode.anchor` field
    doc matches.
  - The README section "When you must not copy" has an ASCII diagram: two
    structs, one queue of `*Anchor`, `parentFromAnchor`.
  - The module header and the `AnyParent` doc: `*Anchor` carries the
    struct, `AnyParent` is for picking a handler by type id.
  - `fromAnchor` and `mustFromAnchor` are now `parentFromAnchor` and
    `mustParentFromAnchor`, to pair with `parentFromNode`. The negative is
    now `must_parent_from_anchor`, moved with `mv`. In the ztk copy only
    the call into paternitas changed. ztk's own `fromAnchor` stays.
  - `Anchor` keeps its name. The reasons are in design 010, "Decisions of
    NAME 01". Design 010 was edited in place: it is this stage's version.
  - All six gates pass. The ztk copy builds in Debug: 198 of 199 tests, one
    skipped by design.
  - The owner then asked for all four modes and the negatives in the ztk
    copy. Both pass in all four modes: 198 of 199 tests each, and the
    negative step exits 0 (34 of 34 steps in Debug and ReleaseSafe, 16 of 16
    in ReleaseFast and ReleaseSmall, where the safety-only cases are not
    built).
- The owner gave the Anchor an image: Archimedes, "Give me a place to
  stand, and I will move the Earth". The Anchor is the fixed point
  everything is reached from: the type, the struct, its Node, its `next`.
  - The `Anchor` doc now opens: "The one fixed point in your struct.
    Everything else is reached from it."
  - The README opens "When you must not copy" with the quote, in Latin and
    English, and says the Anchor is that place in your struct.
  - Plan 010 keeps the image for LOOK 01: a lever on a fixed point, or an
    anchor.
- The owner asked why a queue cannot carry `*Node`. It can, when every
  struct in it has the same Node kind. A scratch test sent two struct types
  through one `std.Io.Queue` of `*Node` and got each back with
  `parentFromNode`.
  - The README section "When you must not copy" now gives both choices:
    `*Node` for one Node kind, `*Anchor` for any. When in doubt, `*Anchor`,
    because a struct can change its Node kind later. The quote comes after.
  - The module header gives the same choice. The `Anchor` doc's last line
    now reads: `*Node` carries any struct with the same Node kind, `*Anchor`
    carries any struct.
  - The ztk copy, run again after these edits: 198 of 199 tests and the
    negatives pass in all four modes.
- The owner noted that a std list does not copy either, so "When you must
  not copy" put the Anchor's reason in the wrong place. The README section
  is now "Beyond the std list": a std list links the struct where it is,
  other code stores values, so you give it a pointer into the struct. The
  mutex, file handle and buffer list is gone.
  - Then the owner asked for the copy to be said plainly. The opening now
    reads: most other containers store a copy of each item you put in. Put
    in a pointer, and only the pointer is copied.
  - The first line now says "Intrusive std lists", at the owner's word.
  - The owner asked for "non-intrusive containers", explained in the text.
    Intrusive: the Node lives inside your struct. Non-intrusive: the
    container knows nothing of your struct and stores a copy. The diagram's
    box is now "a non-intrusive container of *Anchor", and the choices say
    "container", not "queue".
- The owner asked what `Typed(P)` is to the user. Not a mixin, and not
  just "a helper type": it takes the `@fieldParentPtr` work off the user.
  - The `Typed` doc now opens: "Does the `@fieldParentPtr` work for `P`,
    and checks the type." You never write `@fieldParentPtr` or the field's
    name. You get the struct back only when the type matches.
  - The README list says the same. The `Typed` line in the "After" code, in
    the module header and in the README, has the comment "does the
    @fieldParentPtr work".
  - The name stays `Typed`, for the ztk reason in design 010.
- The owner added two analysis reports, `intrusive-type-erased-best-C.md`
  and `zelda-and-paternitas.md`, in commit `936c951`. One had a banned word.
  At the owner's word, `check_docs.sh` now skips both, as it skips
  `paternitas-001.md`. Rules 008, Part 4, "Scan scope", says so. Rules 008
  was edited in place: it is this stage's version.

| step | result |
|---|---|
| Post-stage cleanup | no edits: the stage was only renames |

---

## 2026-10-03 — PTRN 02, the docs for the user

A PTRN 02 follow-up, 2026-10-02 to 2026-10-03. Opus 5.5 wrote the code
comments and the README. Fable did the voice pass on the design. No
behaviour changed.

The owner found the text correct but not human. Then the owner found a
deeper fault. The README and the comments copied the design. They described
the internals instead of how a user solves the problem.

What changed:

- rules-006 replaces 005. It adds "Three kinds of documentation" and "Human
  voice" to Part 5. Part 3 now says a comment stands alone and example steps
  are commands. Part 2 adds the order of a source file and the layout of an
  example file. The line that put the entry point first is gone.
- The README starts from the ziggit footgun, in code. Then it shows the same
  code with paternitas, and a queue of `*Anchor`. The snippets compile and
  run as tests in the scratchpad.
- Every comment in `src/` is rewritten for the caller. No comment leans on
  "stamped" or "Anchor" without explaining it.
- `src/paternitas.zig` and `src/container.zig` follow the user's path. Only
  the order changed: the sorted lines of each file are the same as before.
- Each example opens with the situation it solves. The steps are commands.
- Design 009 is the voice pass, plus the rulings of this round. 008 is in
  `design/backup/`.
- The first Fable pilot rewrote only the voice. The brief told it to keep
  the facts, so it kept the wrong ones. The second pilot came from Claude.

Autodoc groups declarations by kind and sorts a type's calls by name. The
source order helps the reader of the source, not the API page.

All six gates pass. The site builds, and `mkdocs build --strict` is clean.
The pages load in headless Chrome with no console errors. The banned-word
scan is clean.

---

## 2026-10-02 — PTRN 02, Info becomes Typed

A PTRN 02 follow-up. The owner did not like `MessageInfo`, and brought a
review that proposed `Helper`. Opus 5.5. No behaviour change.

- `Info(P)` is now `Typed(P)`. `MessageInfo` is now `TypedMessage`, and so
  on for each Parent. Tests: `MI`, `JI`, `AI`, `BI` are now `TypedMsg`,
  `TypedJob`, `TypedA`, `TypedB`.
- `Helper` was not taken. ztk has `ParentHelper(P)` and `XxxHelper` consts
  in 97 files. Checked in `design/source/paternitas-and-ztk/ztk/`.
- `TypeInfo` and `Anchor.info()` keep their names.
- The examples 003 to 006 follow the owner's edit of 002: the types first,
  each Parent with its `Typed` const, then the `pub fn`, then the private
  fns. 001 keeps its types inside the function. 002 lost its double blank
  lines.
- Design 008. 007 is in `design/backup/`. The reasons are in "Decisions of
  PTRN 02".
- Left as records: the audit report, the intake, `design/source/`, this log.

Checks.

- Six gates pass. 22 tests in all four modes. 9 negatives.

---

## 2026-10-02 — PTRN 02, plain names

The owner asked what `Tally` is, then asked for clever names to become plain
English. Opus 5.5. No behaviour change.

| file | was | now |
|---|---|---|
| example 002 | `recognize` | `recoverAndCount` |
| example 003 | `sendAway`, `comeBack` | `removeAndSend`, `receiveAndAppend` |
| example 004 | `Tally`, `tally`, `checkedForm` | `Counts`, `counts`, `checkFromAny` |
| `src/container.zig` | `shift`, private | `addOffset` |
| tests | `H`, `jj`, `via`, `evs` | `Handlers`, `job`, `from_anchor`, `events` |
| tests | `ma`, `ja`, `mi`, `ji`, `mn` | `m_anchor`, `j_anchor`, `m_info`, `j_info`, `m_node` |
| negatives | `forged`, `Bad`, `Two`, `MyNode` | `hand_built`, `BareNode`, `TwoLinks`, `OtherNode` |

- `Counts` in 004 now matches 002.
- `build.zig`: the expected message of `link_other_node` names `OtherNode`.
- `events` in the tests got an explicit type. Rules Part 2.

Checks.

- Six gates pass. 22 tests in all four modes. 9 negatives.

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
