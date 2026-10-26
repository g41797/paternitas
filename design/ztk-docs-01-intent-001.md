# ZTK DOCS — intent (001)

Two stages: ZTK DOCS 01, the audit; ZTK DOCS 02, the fixes. The owner's
rulings, 2026-10-22. Neither starts until the owner names it.

ztk's code does not change. Comments, README, site, design docs only.

## The owner's answers, 2026-10-22

1. The site: `ztk/kitchen/docs/index.md` and the new errors page. NEXT's site pages wait
   for ZTK HOME.
2. NEXT's `readme-creation-002` and `comments-creation-002` come into
   `ztk/design/` as the guide. Read from matryoshka-ztk, no write there.
3. The optional pointer (own container over Anchors) goes on a site page.
4. z4, the rule-2 check, goes into `ztk_gates.sh` after the comment fixes.
5. The style: paternitas `rules-015` was derived from matryoshka-ztk
   `rules-050`. Audit both. New useful paternitas rules may be merged into
   the ztk rules, as ztk rules-002, in `ztk/design/`, in ZTK DOCS 02 (the owner,
   2026-10-22). They go to matryoshka-ztk at ZTK HOME.
6. Two stages.

## Found before the stages

- README, 69 lines, and `ztk/kitchen/docs/index.md` carry old words: `Inner`,
  `item.id`.
- No errors page.
- paternitas in text outside rule 2's three places: `src/inner.zig:19`,
  `:97`; `src/helper.zig:10`; `tests/layer1_any.zig:202`.

## ZTK DOCS 01 — the audit

1. Every public ztk name, and every paternitas name, method or message a
   ztk user can reach. Does its ztk doc stand alone?
2. Every place paternitas is named in text, against rule 2.
3. The old words in the README and the site.
4. The rules: `rules-050` (matryoshka-ztk) and `rules-015` (paternitas),
   side by side. What paternitas added that ztk should take; what ztk has
   that paternitas dropped.
5. NEXT's README and comments plans, 002, copied into `ztk/design/`.

The findings go in `design/ztk-docs-01-findings-001.md`. Nothing is fixed.

## ZTK DOCS 02 — the fixes

1. Doc comments, from the audit. `anchor.typeId()` gets a ztk doc.
2. README in today's words. "Built on Paternitas" per rule 2.
3. The errors page.
4. The optional pointer page.
5. The site home page and the nav.
6. The merged ztk rules: rules-002, in `ztk/design/`.
7. z4 in `ztk_gates.sh`.

## Check

Each stage: three ztk gates, six paternitas gates.
