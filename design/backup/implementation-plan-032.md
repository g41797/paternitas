# paternitas — Implementation plan (032)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-015.md](rules-015.md).
- Design: [paternitas-design-018.md](paternitas-design-018.md).
- The audit and the owner's rulings:
  [audit-01-report-003.md](audit-01-report-003.md).
- The outside work: [paternitas-intake-001.md](paternitas-intake-001.md).
- Type ids on their own: [paternitas-design-018.md](paternitas-design-018.md), "Type ids on their own".
- Change from 031: ZTK DOCS 05 is done, 2026-10-26. The intent:
  [ztk-docs-05-intent-001.md](ztk-docs-05-intent-001.md). ZTK HUMAN is next.
  The backlog is 012. ztk rules are 002; the rule 2 check is z5.
- Change from 029, kept: ZTK DOCS 03 is done, 2026-10-26. The inventory:
  [ztk-docs-03-inventory-002.md](ztk-docs-03-inventory-002.md). Four questions
  wait for the owner. The backlog is 007.
- Change from 028, kept: ZTK DOCS 02 is done, 2026-10-22. The backlog is 006.
  Intent: [ztk-docs-02-intent-001.md](ztk-docs-02-intent-001.md).
- Change from 027, kept: ZTK PREP 01 is done, 2026-10-22. The backlog is 005.
- Change from 026, kept: the ZTK HOME answers, 2026-10-22. Route: straight to the
  matryoshka-ztk root. A new stage, ZTK PREP 01, comes first. The backlog
  is 004, the home audit is 002.
- Change from 025, kept: ZTK 02 and ZTK DOCS 01 are closed, 2026-10-22. ZTK DOCS
  is iterative, in small stages, from the backlog. The owner: no stage
  starts until this plan names it. The docs are the whole ztk site, the
  README and the doc comments.
- Change from 024, kept: ZTK 01 is closed, 2026-10-22. "design 017" in the ZTK
  section is "design 017", the owner's question 3. ZTK 01 added the ztk
  rules, `ztk/design/rules-002.md`. The docs audit goes into ZTK DOCS.
- Change from 023, kept: ZTK 00 is closed, 2026-10-22. ZTK 01 takes the owner's
  rulings: `ParentHelper` refuses zero TypedNodes itself; a paternitas fix
  round makes `findTypedNode` public, with a neutral "not a struct" message.
  ZTK 01: [ztk-01-intent-002.md](ztk-01-intent-002.md).
- Change from 022, kept: the ZTK stages are named and run in this repo. Owner's
  rulings, 2026-10-22. ZTK 00: [ztk-00-intent-003.md](ztk-00-intent-003.md).
- Change from 021, kept: a new stage, SYNC 01: the comments in `src/`,
  `examples/` and `negative/` follow the README and the site. The owner
  named it, 2026-10-07.
- Change from 020, kept: LOOK 03 is done. It gets one line under "Completed
  stages".
- Change from 019, kept: a new stage, LOOK 03: the logo gets its "in" side. The
  owner named it, 2026-10-07.
- Change from 018, kept: a new stage, DOCS 02: the site's opening pages in a new
  order. The owner named it, 2026-10-07. README 02 waits for the owner's
  read of iteration 2.
- Change from 017, kept: DOCS 01 is closed. README 01 is closed. Their open work,
  the README trims, is a new stage: README 02. The owner named it,
  2026-10-07.
- Change from 016, kept: DOCS 01 PLAN is done. The site plan is
  [docs-01-intent-010.md](docs-01-intent-010.md). DOCS 01 points to it.
- Change from 015, kept: TYID 01 and TYID 02 are done. README and docs come
  before ZTK. Owner's ruling, 2026-10-05. New stages: README 01, DOCS 01
  PLAN, DOCS 01. The README stage was "later" in 015.
- Change from 014, kept: TYID 01 and TYID 02 come before ZTK. Owner's ruling,
  2026-10-05. Three fixes from the owner's second review go into TYID 01.
- Change from 013, kept: LOOK 02 is done. It gets one line under
  "Completed stages".
- Change from 012, kept: LOOK 01 is closed, and its section is gone. Its account
  is in [STATUS-LOG.md](STATUS-LOG.md). The four user-first passes of
  2026-10-04 get one line under "Completed stages".
- Change from 011, kept: EXPL 02 is closed. Its account is in
  [STATUS-LOG.md](STATUS-LOG.md).
- Change from 010, kept: EXPL 01 is closed. Its account is in
  [STATUS-LOG.md](STATUS-LOG.md).
- Change from 009, kept: NAME 01 is closed.
- Change from 008, kept: PTRN 02 is closed.
- Change from 007, kept: PTRN 01 is closed.
- Change from 006, kept: the owner's rulings on ChatGPT's review of design
  004. Notes for the ztk stage.

**No stage starts because this plan says it is next.** The owner names it.

---

## Completed stages

- INTR 15 (2026-09-25, Opus 5.5) — the development process moved from next/ztk
  into paternitas: rules, design doc, placeholder skeleton, kitchen, site, CI.
  Five gates green.
- ADPT 01 (2026-10-02, Opus 5.5) — the workflow tuned: rules 003 and 004,
  `kitchen/gates.sh`, the full banned list in the gate, the hard-break fixer,
  the Examples button. CI accepted by the owner, not checked by Claude. Five
  gates green.
- AUDT 01 (2026-10-02, Opus 5.5) — the outside paternitas built and checked
  in all four modes; findings A1 to A14 and T1 to T7 ruled; design 004. A1:
  two types shared one TypeId in release modes. Five gates green.
- PTRN 01 (2026-10-02, Opus 5.5) — the outside code ported, with A1, A3,
  A11, T6, A15. 17 tests and 9 negatives in all four modes. Gate 6. Six gates
  green.
- PTRN 02 (2026-10-02, Opus 5.5) — the `///` pass, a usage block in the root
  `//!`, six examples, the README. 22 tests in all four modes. Six gates
  green. `mkdocs build --strict` passes.
- NAME 01 (2026-10-03, Opus 5.5) — names that say what each thing is: `Link`
  is now `TypedNode`, and `stamp` is now `setTypeId`. Design 011, rules 007.
  The ztk copy follows. 22 tests in all four modes. Six gates green.
- EXPL 01 (2026-10-03, Opus 5.5) — the README and the module header say
  what "intrusive" and "type-erased" mean, and the README says when you
  need paternitas. Four examples get one line each. Six gates green.
- EXPL 02 (2026-10-03, Opus 5.5) — the README names the two uses. The
  second one passes an `AnyParent`. `*Anchor` goes to container authors.
  003, 004 and 005 carry `AnyParent`. Design 011. Six gates green.
- User-first text (2026-10-04, Opus 5.5) — a new README from the owner's
  draft. The comments in `src/paternitas.zig` and `src/container.zig`, and
  the headers of examples 001 to 006, were rewritten for the user. Not a
  named stage. Six gates green.
- LOOK 01 (2026-10-04, Opus 5.5) — the logo, the mask picture and the
  favicon, from Zero and Ziggy, with
  [ATTRIBUTION.md](../kitchen/tools/logo/mascots/ATTRIBUTION.md). The README
  and the landing page show them. Run by Claude alone, at the owner's request.
  Design 012. Six gates green.
- LOOK 02 (2026-10-05, Opus 5.5) — a new logo from the owner's prototype:
  the belt, the Anchor and the exits. `kitchen/tools/logo/gen_logo.py`
  draws it, and the favicon. The mascot images are kept as a record.
  Design 013. Six gates green.

- TYID 01 (2026-10-05, Opus 5.5) — `Typed(P)` for every struct. Without a
  TypedNode: `typeId`, `isId`, `toAny`, `fromAny`. `AnyParent` is `Any`.
  `-Duse_llvm=false` in g2. Six gates green.
- TYID 02 (2026-10-05, Sonnet 5) — example 007: a handler map for structs
  with no TypedNode. Six gates green.
- DOCS 01 PLAN (2026-10-06, Opus 5.5) — the site plan:
  [docs-01-intent-010.md](docs-01-intent-010.md). Seventeen pages, the hero
  logo leads in, snippets pulled from working code, an API nav entry in a new
  tab, g4 at every depth and `--strict`. No pages written. Six gates green.
- README 01 (2026-10-05, Opus 5.5) — a draft: type ids are a bonus at the
  end, `AnyParent` is `Any`. The trims moved to README 02.
- DOCS 01 (2026-10-06, Opus 5.5) — seventeen site pages, snippets from
  working code, the logo subtitle. Plan:
  [docs-01-intent-010.md](docs-01-intent-010.md). Its step 11, the README
  trims, moved to README 02. Six gates green.

- LOOK 03 (2026-10-07, Opus 5.5) — the logo's "in" side: three typed shapes
  go in, in a mixed order; three gray boxes on the belt; three Parents come
  out. [look-03-intent-001.md](look-03-intent-001.md). Design 015. Six
  gates green.
- ZTK 00 (2026-10-22, Opus 5.5) — `ztk/` at the root on `.path = ".."`,
  `kitchen/ztk_gates.sh`, the NEXT check (unchanged; two "other" items),
  [ztk-plan-003.md](ztk-plan-003.md).
  [ztk-00-intent-003.md](ztk-00-intent-003.md). Six gates green; ztk z1
  fails at `inner.zig:59`, as expected.
- ZTK 01 (2026-10-22, Opus 5.5) — ztk green on today's paternitas:
  `AnyParent = paternitas.Any`; `ParentHelper` refuses zero TypedNodes
  through the now public `findTypedNode`; `<P>: not a struct`; tests 330,
  331; design 017; ztk rules 001.
  [ztk-01-intent-002.md](ztk-01-intent-002.md). Six gates and three ztk
  gates green.
- ZTK 02 (2026-10-22, Opus 5.5) — examples 104, 105 in `layer4/`, the
  `Deadline` parent. No `AnyParent` receive form: Slot usage is MUST.
  [ztk-02-intent-001.md](ztk-02-intent-001.md). All gates green.
- ZTK DOCS 01 (2026-10-22, Opus 5.5) — the audit. Nothing fixed.
  [ztk-docs-01-findings-001.md](ztk-docs-01-findings-001.md). The backlog:
  [ztk-docs-backlog-012.md](ztk-docs-backlog-012.md). NEXT's 002 plans in
  `ztk/design/`. All gates green.
- ZTK DOCS 05 (2026-10-26, Opus 5.5) — the first real ztk README, 75 lines.
  Example 020 cleaned. z4 checks "about 800 lines". Two notes moved to the
  site. [ztk-docs-05-intent-001.md](ztk-docs-05-intent-001.md).

---

## Order

paternitas first, until it is done. Then ztk, built on it. The ztk stage may
need paternitas fixes; the work then goes in rounds. Intake, D1.

```text
PTRN 01  ->  PTRN 02  ->  NAME 01  ->  EXPL 01  ->  EXPL 02  ->  LOOK 01  ->  LOOK 02  ->  TYID 01  ->  TYID 02  ->  README 01  ->  DOCS 01 PLAN  ->  DOCS 01  ->  README 02  <->  DOCS 02  ->  LOOK 03  ->  SYNC 01  ->  ZTK 00  ->  ZTK 01  ->  ZTK 02 ...  <->  PTRN fixes  ->  ZTK DOCS  ->  ZTK HOME
```

---

## README 02 — a smaller README

The owner named it, 2026-10-07. Opus 5.5. The README before it is
`design/backup/README-004.md`, 770 lines.

The README is a taste and a door to the site. It is not the manual.

The owner's rulings:

- Appeal, not scare. A reason to want it, not all the details.
- Human style, as usual. Less technical.
- Most of the README text is already on the site pages.
- Iterations. Each rewritten README is copied to
  `design/backup/README-NNN.md`, with the next number. README-005 is the
  first. Later they are compared, and some text may come back.
- MUST: text removed from the README is already on a site page, or is added
  there in the same step. [rules-015.md](rules-015.md), Part 0.
- "The problem in one example" becomes "The problem and solution in one
  example".
  - The wrong cast.
  - Then the fix: the struct with its TypedNode, the `Typed` line,
    `setTypeId`, `parentFromNode`.
  - Then "No new container. No allocation. No lock."
- The cost is "one additional pointer per struct".
- The door: one plain sentence. The doc site has the rest. No links.
- Leave for the site:
  - Move your code to Paternitas (migration);
  - Singly or doubly linked?;
  - Why not just use a tagged union?;
  - Passing structs through other type-erased code;
  - Writing your own container?.
- The bonus stays.
- The logic of each trim is talked over with the owner, section by section.

Kept from README 01:

- The reader: someone browsing GitHub.
- The code is the only source of truth. README and site both describe it.
- The README snippets are compiled and run against `src/`.
- The logo does not change.

Order of work:

1. Talk over the trims with the owner.
2. Write one iteration. Copy it to `design/backup/` with the next number.
3. For each cut, name the site page that holds the text. Add it there if
   it is missing.
4. The owner reads it. Back to 1, or close.

---

## DOCS 02 — the opening pages

The owner named it, 2026-10-07. Opus 5.5.

- The intent: [docs-02-intent-006.md](docs-02-intent-006.md).
- The footgun comes first. The Background group leaves the nav.
- The Introduction is short: two lines and the NAQ.
- The README is not touched.
- The owner approves the intent before any page changes.

---

## SYNC 01 — the comments follow the site

The owner named it, 2026-10-07. Opus 5.5.

- The intent: [sync-01-intent-002.md](sync-01-intent-002.md).
- The README and the site are the truth. The comments change to match
  them, never the other way round.
- The module comment of `src/paternitas.zig` shrinks to a short start for
  the API pages. The MUST rule holds for each cut.
- The first line of each example header is its site title.
- g4 reads `negative/` too, and stops the old "mark" wording.

---

## ZTK

ztk, moved onto paternitas. In this repo. Owner's rulings, 2026-10-22.

- Writes to matryoshka-ztk: allowed, with the owner's permission each time.
- The base: `design/source/paternitas-and-ztk/ztk`, copied to `ztk/` at the
  repo root. `design/source/` is not edited.
- NEXT, the live ztk in matryoshka-ztk, unchanged since 2026-09-21. The copy
  came after it. A light check, not a survey.
- `AnyParent` stays a ztk name: `paternitas.Any` with a narrower promise. A ztk
  parent always has a TypedNode.
- The design: design 017, "ztk on paternitas". The vocabulary: the same. No
  mechanical rename.
- The file-by-file plan: the outside design, "Matryoshka-ztk changes", in
  `design/source/paternitas-design.md`. ZTK 00 brings it to today's names.
- Gates: `kitchen/ztk_gates.sh`, separate. A paternitas fix: both pass.
- The checkpoint: the whole ztk suite after the containers are moved.

The stages.

- **ZTK 00 — set up.** Done, 2026-10-22. [ztk-00-intent-003.md](ztk-00-intent-003.md).
- **ZTK 01 — green.** Done, 2026-10-22. [ztk-01-intent-002.md](ztk-01-intent-002.md).
- **ZTK 02 … — the plan.** [ztk-plan-003.md](ztk-plan-003.md), file by file. Rounds: ztk,
  paternitas fix, ztk.
- **ZTK DOCS.** The site, the README, the doc comments, ztk style.
  Iterative: one small stage at a time. The owner names each.
  - The intent: [ztk-docs-01-intent-001.md](ztk-docs-01-intent-001.md).
  - The audit: [ztk-docs-01-findings-001.md](ztk-docs-01-findings-001.md).
  - Every item, and every new finding, is in
    [ztk-docs-backlog-012.md](ztk-docs-backlog-012.md). Nothing is lost.
  - ztk's code does not change in ZTK DOCS. Items that touch code wait for
    the owner's ruling.
  - Each stage: three ztk gates, six paternitas gates.
  - The plan gets a new version before each stage starts, naming it.

  The stages, in order. Names after 04 are given when the plan reaches them.

  - **ZTK DOCS 01 — the audit.** Done, 2026-10-22.
  - **ZTK PREP 01 — two pointers and VERSION.** Done, 2026-10-22. B35, B36.
    - matryoshka-ztk root `design/STATUS.md`: the staging plan is 019, not
      002. next-status.md, "ztk on paternitas": the state is paternitas
      `design/STATUS.md`; the ZTK 00 intent is closed. Two writes there,
      with the owner's permission. Nothing else there changes.
    - `ztk/src/matryoshka.zig`: `VERSION` and its `///` go. The two tests
      "317 — the toolkit states its version" go: `tests/layer1_id.zig`,
      `tests/layer2_mbox.zig`. A code change, the owner's ruling.
    - Check: three ztk gates (201/202 tests), six paternitas gates.
  - **ZTK DOCS 02 — the frame.** Done, 2026-10-22. B27, B14, B32.
    [ztk-docs-02-intent-001.md](ztk-docs-02-intent-001.md).
    - The hero in the paternitas style: the ztk logo, two buttons, "Get
      Started" and "{{ src_loc() }} lines of code" to `apidocs/`.
    - The nav with the page groups. Empty pages say "to come".
    - `mkdocs build --strict` passes.
    - B32 taken here: `new_tab_links.py`, the `fix_md_*` scripts.
  - **ZTK DOCS 03 — the page inventory.** Done, 2026-10-26. B28.
    [ztk-docs-03-inventory-002.md](ztk-docs-03-inventory-002.md).
    - One line per hand-written matryoshka-ztk page, 60 pages: take,
      rewrite, merge or drop. The examples: one line, generated.
    - It sets the order of the page stages. No page written.
    - The page stages follow the inventory's order, after 05.
  - **ZTK DOCS 04 — rule 2 in `src/`.** Done, 2026-10-26. B1, B2, B3, and
    the F2.4 test comment. Four comment lines.
  - **ZTK DOCS 05 — the README, first real version.** Done, 2026-10-26.
    B10, B11, B45. [ztk-docs-05-intent-001.md](ztk-docs-05-intent-001.md).
    - A short README: two worlds, what you get, the pipeline (example 020),
      install "to come", Built on Paternitas, the site.
    - z4: the "about 800 lines" claim. Two README notes moved to the site.
  - **ZTK HUMAN — the comments, human.** Next. Before B5 and B6. B43.
    - ztk only: `//!`, `///`, example headers, test comments.
    - Fix: piled-up sentences, abstract phrases, AI-sounding words, words a
      reader does not need, how-it-is-built text.
    - Comments only. Meaning kept. Text moved out stays on a site page or
      in the backlog.
    - One file per step: before and after to the owner, then the edit.
  - **Then, one per stage:** each page group from the inventory; the
    errors page (B12) and the pointer page (B13) early; the generator and
    nav sync (B30); the example headers (B34); the doc comments (B5, B6);
    the rules, ztk rules-002 (B18 to B20); z5 (B21). The rules are then 003.
  - Items that need a ruling (L) come one at a time.
  - ZTK HOME preparation, between docs stages: B37 the ztk gate script in
    `ztk/`, B38 ztk's design notes, B39 a ztk-only log, B40 no `../`
    links. Nothing in `ztk/` names a path above itself.
- **ZTK HOME.** What changes: [ztk-home-audit-002.md](ztk-home-audit-002.md).
  - Route 2: `ztk/` goes straight to the matryoshka-ztk root and replaces
    the old tree. NEXT is superseded, not updated. NEXT's date checked
    again first.
  - paternitas is tagged first, the owner's step. ztk's zon then takes it
    by `.url` and `.hash`.
  - Nothing is deleted on the way. Old versions are listed in context.md.
    Cleanup is a later step, the owner's.
  - Then the owner removes `design/source/` and `ztk/` here.

---

## Deferred

- **CI and Pages.** Accepted by the owner as they are, 2026-10-02. To look at
  again later.
- **`design/source/`.** It stays until after the ztk stage. Owner's ruling,
  2026-10-02. Then the owner removes it.
  - Reason: design 017 points to the outside design's ztk section in it.
  - It replaces intake D6, "after the paternitas work".
