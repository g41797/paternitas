# paternitas — STATUS

Current state only. Updated in place. The narrative is in
[STATUS-LOG.md](STATUS-LOG.md).

## Start here — every session

1. Read this file in full.
2. Read Part 0 of [rules-014.md](rules-014.md).
3. Read the plan, [implementation-plan-021.md](implementation-plan-021.md), for
   the stage the owner names. Not before they name it.
4. Read the design, [paternitas-design-015.md](paternitas-design-015.md), for
   a stage that writes code or docs.
5. Read [paternitas-intake-001.md](paternitas-intake-001.md) for the ztk
   stage: the outside work and the questions left for it.
6. Read the head of [STATUS-LOG.md](STATUS-LOG.md) when the stage needs the
   last stage's account.

**No stage starts because a document says it is next.** The owner names it.

## Sources of truth

| what | where |
|---|---|
| rules | [rules-014.md](rules-014.md) |
| design decisions, and what paternitas keeps from ztk | [paternitas-design-015.md](paternitas-design-015.md) |
| the plan | [implementation-plan-021.md](implementation-plan-021.md) |
| the audit: findings, evidence, rulings | [audit-01-report-003.md](audit-01-report-003.md) |
| the outside work: findings, rulings, open questions | [paternitas-intake-001.md](paternitas-intake-001.md) |
| the outside work itself, as it came | `design/source/` |
| NAME 01: the new names and what they touch | [name-01-intent-002.md](name-01-intent-002.md) |
| DOCS 01: the site pages | [docs-01-intent-009.md](docs-01-intent-009.md) |
| DOCS 02: the opening pages | [docs-02-intent-005.md](docs-02-intent-005.md) |
| LOOK 03: the logo's "in" side | [look-03-intent-001.md](look-03-intent-001.md) |
| the narrative | [STATUS-LOG.md](STATUS-LOG.md) |
| the advice collected by the owner, read in AUDT 01 | `paternitas-001.md` |
| superseded versions | `design/backup/` |

## Current state

- LOOK 03 is done, 2026-10-07. The owner named it. The intent is
  [look-03-intent-001.md](look-03-intent-001.md). Design 015.
  - Three typed shapes go in on the left, in a mixed order. Three gray
    boxes on the belt. Three Parents come out, sorted.
  - `gen_logo.py`: `ENTRIES`, `entries()`. [LOGO.md](../kitchen/tools/logo/LOGO.md)
    explains it. The favicon did not change.
- DOCS 02: the site's opening pages in a new order. The owner named it,
  2026-10-07. The intent is [docs-02-intent-005.md](docs-02-intent-005.md).
  - Done: the pages changed, 2026-10-07. Open: the owner looks at the
    preview.
  - One nav group, "How to prevent the linked list footgun": "In short",
    "Intrusive lists", "Type-erased lists", "Are you my Parent?". No
    Background group. The files keep their paths.
  - The footgun is told once, on "Are you my Parent?", after the two word
    pages. "In short" has no problem, no fix, no code.
  - Italic *Paternitas* in prose and headings, on every site page. Not in
    NAQ titles, code, the logo `alt`, the README.
  - The hero shows "{{ src_loc() }} lines of code" under the logo: a pill,
    not a link. 189 today.
  - Links in the page text open in a new tab, internal ones too:
    `kitchen/hooks/new_tab_links.py`. Same tab: "Open here", the hero,
    `#` links.
  - The owner's first look is applied. "Move your code" is "Migrate your
    code". "Type ids on their own" is "Type ids, listless and nodeless".
  - The first real NAQ, at the end of "In short": how the lines of code
    are counted.
  - No two NAQs back to back. Each sits right after the text it is about,
    not at the end of a section.
- README 02: a smaller README. The owner named it, 2026-10-07. The plan is
  [implementation-plan-021.md](implementation-plan-021.md), "README 02".
  - The README before it: `design/backup/README-004.md`.
  - Each new iteration is copied to `design/backup/`, from README-005 on.
  - A new MUST rule: text cut from the README or a site page stays on the
    site. [rules-014.md](rules-014.md), Part 0.
  - Done: the setup, iterations 1 to 4, and a fix to "Where it came
    from". Copies: `design/backup/README-005.md` to
    `design/backup/README-009.md`.
  - "What you get" says "The code is shorter than this README". g4 checks
    it: it fails when the code is not shorter, and names both counts.
  - Waits: the owner reads iteration 4.
- DOCS 01 is closed, 2026-10-07. The pages were written 2026-10-06. The plan
  was [docs-01-intent-009.md](docs-01-intent-009.md). Its step 11, the README
  trims, moved to README 02.
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
  - The plan is [docs-01-intent-009.md](docs-01-intent-009.md): seventeen
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
  - The owner's rulings are in [implementation-plan-021.md](implementation-plan-021.md), "README 01".
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

1. DOCS 02: the owner's look goes on, then the stage closes.
   [docs-02-intent-005.md](docs-02-intent-005.md).
2. README 02: the owner reads iteration 4, README-009. The plan:
   [implementation-plan-021.md](implementation-plan-021.md), "README 02".
3. The last state: six gates pass, 27 tests, the strict site build passes,
   2026-10-07. The owner commits and pushes.
