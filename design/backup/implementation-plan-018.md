# paternitas — Implementation plan (018)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-014.md](rules-014.md).
- Design: [paternitas-design-014.md](paternitas-design-014.md).
- The audit and the owner's rulings:
  [audit-01-report-003.md](audit-01-report-003.md).
- The outside work: [paternitas-intake-001.md](paternitas-intake-001.md).
- Type ids on their own: [paternitas-design-014.md](paternitas-design-014.md), "Type ids on their own".
- Change from 017: DOCS 01 is closed. README 01 is closed. Their open work,
  the README trims, is a new stage: README 02. The owner named it,
  2026-10-07.
- Change from 016, kept: DOCS 01 PLAN is done. The site plan is
  [docs-01-intent-008.md](docs-01-intent-008.md). DOCS 01 points to it.
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
  [docs-01-intent-008.md](docs-01-intent-008.md). Seventeen pages, the hero
  logo leads in, snippets pulled from working code, an API nav entry in a new
  tab, g4 at every depth and `--strict`. No pages written. Six gates green.
- README 01 (2026-10-05, Opus 5.5) — a draft: type ids are a bonus at the
  end, `AnyParent` is `Any`. The trims moved to README 02.
- DOCS 01 (2026-10-06, Opus 5.5) — seventeen site pages, snippets from
  working code, the logo subtitle. Plan:
  [docs-01-intent-008.md](docs-01-intent-008.md). Its step 11, the README
  trims, moved to README 02. Six gates green.

---

## Order

paternitas first, until it is done. Then ztk, built on it. The ztk stage may
need paternitas fixes; the work then goes in rounds. Intake, D1.

```text
PTRN 01  ->  PTRN 02  ->  NAME 01  ->  EXPL 01  ->  EXPL 02  ->  LOOK 01  ->  LOOK 02  ->  TYID 01  ->  TYID 02  ->  README 01  ->  DOCS 01 PLAN  ->  DOCS 01  ->  README 02  ->  ZTK ...  <->  PTRN fixes
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
  there in the same step. [rules-014.md](rules-014.md), Part 0.
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

## ZTK — later

In the matryoshka-ztk repo. The owner names it.

- The plan, file by file: design 005, "ztk on paternitas", and the outside
  design's section it points to.
- The vocabulary: design 005, "ztk on paternitas". No mechanical rename.
- NAME 01 gave the ztk copy in `design/source/` the new names: `TypedNode`,
  `setTypeId`, `_tnode`. The ztk repo needs the same change.
- NAME 01 also changed `paternitas.Info` to `Typed` in the copy's
  `src/helper.zig`, at the owner's request.
- At the owner's request, NAME 01 also brought the copy up to the current
  API, so it builds against this repo.
  - Each read of `anchor.type_id` is now `anchor.typeId()`. AUDT 01, A11.
  - `paternitas.nameOf(found)` is now `found.typeName()`, in
    `src/helper.zig`.
  - It builds and passes in all four modes, with `../paternitas` linked to
    this repo in a scratch copy. 198 of 199 tests pass in each mode. One
    skips by design.
  - `zig build negative` passes in all four modes: 5 compile and 14 panic
    programs. The `safe_only` panic cases run in Debug and ReleaseSafe
    only, as ztk's `build.zig` says.
  - The cross build passes in Debug: x86_64-macos, aarch64-macos,
    x86_64-windows.
- The copy's `build.zig.zon` points at `../paternitas`, the outside copy,
  not at this repo.
- `ParentHelper` stays. Design 005.
- The checkpoint: run the whole ztk suite after the containers are moved, not
  before. Before that, Queue, stack, Mbox and Pool do not build.
- AUDT 01, A11: ztk reads the id as `anchor.typeId()`.
- The open questions: the intake, "Open for the ztk stage".

---

## Deferred

- **CI and Pages.** Accepted by the owner as they are, 2026-10-02. To look at
  again later.
- **`design/source/`.** It stays until after the ztk stage. Owner's ruling,
  2026-10-02. Then the owner removes it.
  - Reason: design 005 points to the outside design's ztk section in it.
  - It replaces intake D6, "after the paternitas work".
