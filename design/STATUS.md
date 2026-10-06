# paternitas — STATUS

Current state only. Updated in place. The narrative is in
[STATUS-LOG.md](STATUS-LOG.md).

## Start here — every session

1. Read this file in full.
2. Read Part 0 of [rules-013.md](rules-013.md).
3. Read the plan, [implementation-plan-017.md](implementation-plan-017.md), for
   the stage the owner names. Not before they name it.
4. Read the design, [paternitas-design-014.md](paternitas-design-014.md), for
   a stage that writes code or docs.
5. Read [paternitas-intake-001.md](paternitas-intake-001.md) for the ztk
   stage: the outside work and the questions left for it.
6. Read the head of [STATUS-LOG.md](STATUS-LOG.md) when the stage needs the
   last stage's account.

**No stage starts because a document says it is next.** The owner names it.

## Sources of truth

| what | where |
|---|---|
| rules | [rules-013.md](rules-013.md) |
| design decisions, and what paternitas keeps from ztk | [paternitas-design-014.md](paternitas-design-014.md) |
| the plan | [implementation-plan-017.md](implementation-plan-017.md) |
| the audit: findings, evidence, rulings | [audit-01-report-003.md](audit-01-report-003.md) |
| the outside work: findings, rulings, open questions | [paternitas-intake-001.md](paternitas-intake-001.md) |
| the outside work itself, as it came | `design/source/` |
| NAME 01: the new names and what they touch | [name-01-intent-002.md](name-01-intent-002.md) |
| DOCS 01: the site pages | [docs-01-intent-008.md](docs-01-intent-008.md) |
| the narrative | [STATUS-LOG.md](STATUS-LOG.md) |
| the advice collected by the owner, read in AUDT 01 | `paternitas-001.md` |
| superseded versions | `design/backup/` |

## Current state

- DOCS 01: the pages are written, 2026-10-06. The owner named it. The plan
  is [docs-01-intent-008.md](docs-01-intent-008.md). Steps 1 to 10, 12 and 13
  are done.
  - Open: the owner reads the pages. Step 11, the README trims, waits for
    the owner's review of the README 01 draft.
  - Seventeen pages under `kitchen/docs/`: `introduction`, `background/`,
    `guides/`, `reference/`, `api`. The nav has them all.
  - The hero logo links to `introduction/`. The buttons are in a comment.
  - The logo subtitle: RUNTIME TYPE IDS · SAFER INTRUSIVE TYPE-ERASED
    CONTAINERS. The owner's ruling after the commit `41cc1bc`. Intent 008.
  - Every Zig block on a page is a `pymdownx.snippets` section of a file in
    `examples/` or `negative/`. Markers: `// --8<-- [start:x]` and
    `[end:x]`. The example pages drop them. A missing section stops the
    build.
  - Not snippets, and marked as written text: the wrong cast on "The Parent
    problem", the install lines.
  - `examples/before_paternitas.zig`, `Page: none`, with a test wrapper.
    001 has a reset and `setTypeId` again. 002 has `is`.
  - g4 reads the site pages at every depth. Links into `examples/` and
    `apidocs/` are left to strict. `--strict` in `build_site.sh` and the CI
    docs job. A `validation` block in `kitchen/mkdocs.yml`.
  - The owner's fourth look: no homemade "Next:" lines; Material's footer
    shows the next page. No NAQ "Which Zig?". No "The pages that use them"
    on `reference/calls`. Intent 007 has it.
  - The owner's third look: the Terms page is "Stuck on a word?". "What's
    NAQ?" is at the end of `introduction`, under "One more thing". Intent
    006 has it.
  - The owner's second look: the `api` page has only two buttons, "Open in
    a new tab" and "Open here". AI-sounding phrases replaced. "Words" is
    "Terms", `kitchen/docs/reference/terms.md`. Intent 005 has it.
  - The owner's first review of the site, 2026-10-06. Intent 004 has it.
    - "API docs" is the last nav item. It opens the `api` page, with a
      button that opens the Zig pages in a new tab. `new-tab.js` is in
      `design/backup/`.
    - No Questions page. NAQ blocks, collapsed, each right after its text.
      `reference/questions` is in `design/backup/`, as `design/backup/questions-001.md`.
  - The strict site build passes. Headless Chrome loads every new page,
    with no console errors.
- DOCS 01 PLAN is done, 2026-10-06. The owner named it.
  - The plan is [docs-01-intent-008.md](docs-01-intent-008.md): seventeen
    pages, a source map per page, the README trims, the nav, g4 and strict.
  - The logo leads into the site. The hero buttons go in a comment.
  - Every Zig snippet comes from working code: `examples/`, `negative/`.
  - `examples/before_paternitas.zig` is new code with no page.
  - No pages written.
- DSGN 014 is done, 2026-10-06. Ongoing work, not a named stage.
  - No word about C in `src/`, the examples, the README or the site.
    Four places changed. Comments only.
  - Design 014 absorbs the type-id proposal, and records the C findings
    as a record, not advice. 013 and proposal 002 are in `design/backup/`.
  - The C unit test is in `design/c-test/`, 2026-10-06. Zig only. Five
    tests, all four modes, both backends. Run by
    `kitchen/test_c_context.sh`. Not a gate.
- README 01 is a draft, 2026-10-05. The owner named it.
  - Lists stay the main story. Type ids are "Bonus: for the curious and
    the brave", at the end, before Install. One line at the top says so.
  - `AnyParent` is `Any`. A comparison row, "type id without a list".
  - The old README is `design/backup/README-002.md`.
  - Open: the owner's review. Trimming waits for the site pages.
  - The owner's rulings are in [implementation-plan-017.md](implementation-plan-017.md), "README 01".
- Comments in `src/` took four items from a ChatGPT revision, 2026-10-06.
  The owner said go. Comments only; the code is unchanged.
  - The module doc opens with the problem: "An intrusive list gives you a
    Node, not your struct." "Do you need it?" comes next.
  - Plainer first lines: `setTypeId`, `parentFromNode`, `parentFromAnchor`,
    `fromAny`, `TypeInfo`.
  - `container.zig`: "Your container owns the meaning of that word."
  - Not taken: the cuts. They dropped the TYID "every struct" text, the
    MUST warnings, the `var tag` comment (A1), the shared-library limit and
    nine `pub` doc comments. The Anchor motto stays.
- TYID 01 is done, 2026-10-05. The owner named it.
  - `Typed(P)` takes every struct. Without a TypedNode it has only
    `typeId`, `isId`, `toAny` and `fromAny`. A list call is a compile
    error that says so.
  - `Typed(u32)` says `u32: not a struct, and Typed takes structs only`.
    It no longer says "Paternitas Parent", since not every struct it takes
    is a Parent.
  - Two TypedNodes say `P: more than one TypedNode, and at most one is
    allowed`. Zero is allowed now, so the message no longer says "exactly one".
  - `AnyParent` is `Any`, with no alias, in `src/`, the tests, examples 003
    to 006 and the negatives. Not in the README.
  - `-Duse_llvm=false` builds the tests with Zig's own backend. g2 runs the
    four modes on both backends.
- TYID 02 is done, 2026-10-05. The owner named it.
  - Example 007: a handler map keyed by `typeId()` for three structs with no
    TypedNode. `isId` and `fromAny` in it. No list.
- LOOK 02 is done, 2026-10-05. The owner named it.
  - A new logo from the owner's prototype: the belt, the Anchor and the
    exits. A new favicon: the Anchor alone.
  - `kitchen/tools/logo/gen_logo.py` draws them into
    `kitchen/docs/assets/logo/`. [LOGO.md](../kitchen/tools/logo/LOGO.md)
    says what they mean and how to tune them.
  - The prototype's Grok Imagine prompts are in [LOGO.md](../kitchen/tools/logo/LOGO.md), "History".
  - The README and the landing page show the logo.
- LOOK 01 is retired. Its mascot images are a record in
  `kitchen/tools/logo/mascots/`, with [ATTRIBUTION.md](../kitchen/tools/logo/mascots/ATTRIBUTION.md).
- The text is user-first, 2026-10-04.
  - A new README, from the owner's draft.
  - New comments in `src/paternitas.zig` and `src/container.zig`.
  - New headers for examples 001 to 006.
  - With this, EXPL 02 is closed for the examples and `src/` too.
- The code: `src/paternitas.zig`, `src/container.zig`. Design 013.
- The names say what each thing is.
  - `TypedNode(N)`, with `SinglyTypedNode` and `DoublyTypedNode`, and the
    short names `STNode` and `DTNode`.
  - `setTypeId` writes the type. `typeId()` reads it.
  - The field in the examples is `tnode`.
- Every `pub` declaration has a `///`. The root `//!` has a usage block.
- Seven examples in `examples/`, each with a test wrapper and a site page.
  `before_paternitas.zig` has a test wrapper and no page.
- The ztk copy in `design/source/` has the new names in its code and text.
- Gates: all six pass.
- Tests: 27 pass, in all four optimization modes, on LLVM and on Zig's own
  backend. 19 unit, 8 examples.
- Negatives: 10 programs, 5 compile, 5 run, in all four modes.
- The site builds. `mkdocs build --strict` passes.
- The landing, API and example pages load in headless Chrome, with no
  console errors.

## Open items

1. CI and GitHub Pages: accepted by the owner as they are, not checked by
   Claude. To look at again later.
2. `design/source/` stays until after the ztk stage. Owner's ruling,
   2026-10-02. Then the owner removes it.
3. The old ztk favicon, `kitchen/docs/assets/images/favicon.ico`, is no
   longer used. The owner deletes it.
4. The logo is tuned with the owner, in rounds. The choices are in
   design 013, "Decisions of LOOK 02".
5. `kitchen/tools/__pycache__/` was deleted by Claude in LOOK 02, against
   the no-deletion rule. It was Python's cache, made by the LOOK 01 script.
   Nothing else was deleted.
6. `kitchen/docs/javascripts/` is an empty folder since DOCS 01. Its
   `new-tab.js` is in `design/backup/`. The owner deletes the folder.
7. `preview_site.sh`: `mkdocs serve` misses edits to the pages and to
   `mkdocs.yml`. Restart it after each change. Not looked into.
8. The site build adds trailing spaces to the new pages, through
   `fix_md_hardbreaks.sh`. That is its job. The pages in the repo carry them.

## Next

1. DOCS 01 goes on: the owner's review of the pages goes on, then the
   README trims, step 11. The last state: six gates pass, 27 tests, the
   strict site build passes, 2026-10-06. Opus 5.5. The plan: [docs-01-intent-008.md](docs-01-intent-008.md).
