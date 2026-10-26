# ZTK DOCS 03 — the page inventory (001)

The owner named the stage, 2026-10-26. Item B28.
The plan: [implementation-plan-030.md](implementation-plan-030.md), "ZTK".
The backlog: [ztk-docs-backlog-007.md](ztk-docs-backlog-007.md).

One line per hand-written page of the matryoshka-ztk site,
`kitchen/docs/`, read only. No page written in this stage.

- 60 hand-written pages.
- "3tk" is the number of lines with `PolyNode`, `PolyHelper` or `PolyTag`.
- "orphan": the page is not in the old nav.
- Verdicts:
  - **take**: the text stays, with small edits.
  - **rewrite**: the idea stays, the text is new. Mostly 3tk names and
    code that ztk no longer has.
  - **merge**: goes into the page named in the verdict.
  - **drop**: not on the new site. The reason is given. The text stays in
    matryoshka-ztk's history.
- Rule 1 of `ztk/design/rules-001.md` applies to every page: it stands
  alone and does not send the reader to paternitas.
- Every verdict is a proposal. The owner rules on each group before its
  page stage.

## The examples

- 88 pages under `examples/`, generated from the `//!` headers by
  `gen_examples_docs.sh`. One verdict: **take, generated**. B30 brings the
  generator back into the build, with the nav sync. The headers are B34.

## Root pages → Home, Background

| page | lines | 3tk | verdict | new place |
|---|---|---|---|---|
| `index` | 33 | 0 | drop: replaced by the ZTK DOCS 02 hero | — |
| `manifesto` | 278 | 0 | take | Background |
| `history` | 38 | 0 | rewrite: add the move onto paternitas, in ztk terms | Background |
| `the-shape` | 57 | 1 | take, one name | Get Started, its picture |

## `tools/` → Tools, Get Started

| page | lines | 3tk | verdict | new place |
|---|---|---|---|---|
| `tools/index` | 18 | 1 | merge, orphan: the four concepts in short | Get Started |
| `tools/polynode` | 93 | 10 | rewrite: Item, the one TypedNode a user embeds | Tools / Item |
| `tools/mailbox` | 99 | 2 | take, two names | Tools / Mailbox |
| `tools/pool` | 96 | 0 | take | Tools / Pool |
| `tools/master` | 99 | 1 | take, one name; waits for B42 | Tools / Master |

## `api/` → API Reference

| page | lines | 3tk | verdict | new place |
|---|---|---|---|---|
| `api/polynode/index` | 46 | 8 | rewrite: Item, ItemHandle, Slot | API / Item |
| `api/polynode/functions` | 47 | 4 | rewrite | API / Item |
| `api/polynode/manual-definition` | 272 | 37 | rewrite, much shorter: one TypedNode field and `ParentHelper` | API / Item |
| `api/polynode/stdlib-compatibility` | 155 | 12 | rewrite: std lists through the TypedNode | API / Item |
| `api/polyhelper` | 309 | 38 | rewrite as `ParentHelper` | API / ParentHelper |
| `api/tags-and-slots/index` | 74 | 7 | rewrite: tag identity is `TypeId` now | API / Type ids and Slots |
| `api/tags-and-slots/slot-programming` | 118 | 5 | merge | API / Type ids and Slots |
| `api/mailbox/index` | 85 | 4 | take, four names | API / Mailbox |
| `api/mailbox/send` | 61 | 2 | take | API / Mailbox |
| `api/mailbox/receive` | 66 | 1 | take | API / Mailbox |
| `api/mailbox/control` | 74 | 2 | take | API / Mailbox |
| `api/mailbox/events` | 93 | 0 | take | API / Mailbox |
| `api/mailbox/errors` | 15 | 0 | merge | Errors |
| `api/pool/index` | 149 | 4 | take, four names | API / Pool |
| `api/pool/get` | 41 | 0 | take | API / Pool |
| `api/pool/put` | 76 | 2 | take | API / Pool |
| `api/pool/control` | 55 | 0 | take | API / Pool |
| `api/pool/events` | 73 | 0 | take | API / Pool |
| `api/pool/hooks-discipline` | 34 | 0 | take | API / Pool |
| `api/pool/next-steps` | 15 | 0 | merge: two example links | API / Pool, its index |
| `api/pool/errors` | 15 | 0 | merge | Errors |
| `api/root-and-master` | 120 | 7 | rewrite, orphan; Master part waits for B42 | API / Root and Master |
| `api/cancel-and-*` (one page) | 65 | 0 | take, orphan | API / Cancel and item life |
| `api/invariants` | 104 | 0 | take, orphan | API / Invariants |
| `api/cleanup/index` | 35 | 1 | merge: pattern 1 | API / Cleanup, one page |
| `api/cleanup/pattern-2` | 19 | 4 | merge | API / Cleanup |
| `api/cleanup/pattern-3` | 18 | 0 | merge | API / Cleanup |
| `api/cleanup/pattern-4` | 20 | 0 | merge | API / Cleanup |
| `api/cleanup/summary` | 22 | 0 | merge | API / Cleanup |
| `api/cleanup/no-raw-allocator` | 43 | 11 | merge, rewrite the names | API / Cleanup |

## `patterns/` → Patterns

| page | lines | 3tk | verdict | new place |
|---|---|---|---|---|
| `patterns/index` | 13 | 1 | rewrite: the group's list | Patterns |
| `patterns/slot-and-polynode` | 504 | 45 | rewrite: Slot and Item idioms | Patterns |
| `patterns/dispatch` | 439 | 29 | rewrite: dispatch on `typeId()` | Patterns |
| `patterns/mailbox-and-topology` | 246 | 1 | take | Patterns |
| `patterns/pool` | 207 | 12 | rewrite the names | Patterns |
| `patterns/async` | 455 | 3 | take, three names | Patterns |
| `patterns/master-and-shutdown` | 443 | 5 | take; waits for B42 | Patterns |

## `addendums/` → Background, Get Started

| page | lines | 3tk | verdict | new place |
|---|---|---|---|---|
| `addendums/api_reference` | 7 | 0 | drop, orphan: the hero button does it | — |
| `addendums/installation` | 32 | 0 | rewrite: the zon names paternitas by `.url` and `.hash` (ZTK HOME) | Get Started |
| `addendums/laws_of_docs` | 23 | 0 | take | Background |
| `addendums/io-101` | 197 | 0 | take | Background |
| `addendums/intrusion-type-erasure` | 42 | 0 | take | Background |
| `addendums/slot-based-programming` | 393 | 3 | take, three names | Background |
| `addendums/slot-idiom` | 857 | 0 | merge, orphan: the same ground as the one above | Background / Slot-based programming |
| `addendums/slot-vs-ref-counting` | 112 | 1 | take | Background |
| `addendums/tag-vs-tagged-union` | 107 | 12 | rewrite: type id vs tagged union | Background |
| `addendums/typeErasedQueue-vs-mailbox` | 104 | 0 | take | Background |
| `addendums/handle-based-programming` | 99 | 4 | take, four names | Background |
| `addendums/why-boring` | 148 | 0 | take | Background |
| `addendums/matryoshka-and-rethinking` | 341 | 2 | take, orphan | Background |
| `addendums/matryoshka-ztk-notation` | 815 | 1 | take | Background |

## The counts

- take 31, rewrite 15, merge 12, drop 2. Total 60.
- Orphans: 7. Four stay as pages, two are merged, one is dropped.
- 3tk names: 35 pages. The new names are the ones in `ztk/src/`
  today: the TypedNodes, `ParentHelper`, `TypeId`, `AnyParent`.

## The order of the page stages

Smallest risk first. Each is one ZTK DOCS stage, named by the owner.

1. Get Started: `the-shape`, `tools/index`, `addendums/installation`.
2. Errors (B12): the two error-set pages, and the paternitas messages.
3. Tools: Mailbox, Pool, then Item (rewrite). Master after B42.
4. API / Item and ParentHelper: the 3tk rewrites, the largest.
5. API / Type ids and Slots.
6. API / Mailbox, API / Pool: take.
7. API / Cleanup, Cancel and item life, Invariants.
8. Patterns, take pages first.
9. Background, take pages first; the Slot merge last.
10. The pointer page (B13), for writing your own container.
11. Anything waiting for B42: Tools / Master, Root and Master, the
    Master patterns, the site name.

## Questions for the owner

1. The verdicts: agree, or change any line?
2. Background takes all of the addendums. Too many for one group? A
   split into "Ideas" and "Comparisons" is one option.
3. `slot-idiom` (857 lines) into `slot-based-programming`: the merge, or
   keep both?
4. The order of the page stages: agree?
