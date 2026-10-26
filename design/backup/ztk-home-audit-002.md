# ZTK HOME — what changes when ztk goes back (002)

ztk is worked on in this repo. At ZTK HOME it moves to matryoshka-ztk.
This file lists what then has to be updated or fixed. Written 2026-10-22,
at the owner's request. Nothing is decided here. The questions for the
owner are at the end.

## The owner's answers, 2026-10-22

1. H4: route 2. ztk goes straight to the matryoshka-ztk root. NEXT is not
   updated; it is superseded.
2. H7: home is the local matryoshka-ztk repo. There the zon gets
   paternitas by `.url` and `.hash`. A paternitas tag comes first: the
   owner's step.
3. H11, H22, H23: Claude's call. Yes, now, as backlog items: a ztk gate
   script in `ztk/kitchen/`, ztk's design notes and a ztk-only log in
   `ztk/design/`. paternitas `kitchen/ztk_gates.sh` stays until the move.
4. H20: the mantra is "do not forget". Nothing is deleted.
   `ztk/design/backup/` stays. At home its files are listed in
   context.md. Removing obsolete files is a later cleanup, the owner's.
5. H1, H2: fix both pointers in matryoshka-ztk. The owner's permission
   covers these two writes only.
6. H9: remove `VERSION` from `src/matryoshka.zig`. Two tests named "317 —
   the toolkit states its version" use it, in `tests/layer1_id.zig` and
   `tests/layer2_mbox.zig`. They go too. 203 tests become 201.

Change from 001: the answers above.

Every item has an id, H1, H2, …. They go into the plan when ZTK HOME is
planned. Items that ZTK DOCS can make easier now are marked **now**.

## 1. Three ztk trees, and their plans

```text
matryoshka-ztk/                         frozen since 2026-09-20
  src/ tests/ examples/ stories/        A: the old tree, 3tk names (polynode)
  design/STATUS.md, plan-080, rules-050    its state, plan, rules
  design/secondary/lang/port/3tk-to-ztk/next/
    next-status.md, next-staging-plan-019.md, next-log.md
    ztk/                                B: NEXT, unchanged since 2026-09-21

paternitas/
  ztk/                                  C: the live ztk, on paternitas
  design/ STATUS, plan-026, ztk-plan-003, ztk-docs-*, ztk-home-audit
  ztk/design/rules-003.md, task*-tests, *-creation-002
```

- C is the one that goes home. B and A are older.
- Four sets of state and plans describe ztk:
  - root `design/STATUS.md` + plan-080 (A),
  - next-status.md + next-staging-plan-019.md + next-log.md (B),
  - paternitas `STATUS.md` + plan-026 + `ztk-plan-003.md` + the ZTK DOCS
    files (C),
  - the ztk narrative in paternitas `STATUS-LOG.md` (C).

## 2. Stale pointers found today

- H1 matryoshka-ztk `design/STATUS.md` points to
  next-staging-plan-002.md. The live one is 019.
- H2 next-status.md, "ztk on paternitas": points to
  paternitas/design/ztk-00-intent-003.md as the intent. That stage is
  closed. It should point to paternitas `STATUS.md` alone.
- H3 Both fixes are writes to matryoshka-ztk: owner's permission each time.

## 3. The route home

- H4 Two routes.
  - Route 1: C replaces B in `next/ztk/`, then NEXT's PROMOTE copies it to
    the root. Two moves. NEXT's plan 019 stays the frame.
  - Route 2: C goes straight to the root, and PROMOTE is done in the same
    step. B is superseded without being updated.
  - Route 2 is one move and no stale middle copy. Route 1 keeps NEXT's
    plan valid as written. Owner's call.
- H5 PROMOTE deletes the old tree (A) at the root. That is the owner's
  step (plan 019).
- H6 C differs from B in every `src/` file, and B has `internal/info.zig`,
  which C removed. No merge: C replaces B whole. Any B change after
  2026-09-21 must be checked first. Plan 025 says "NEXT's date checked
  again".

## 4. The build

- H7 `build.zig.zon`: `.paternitas = .{ .path = ".." }`. At home it must
  be a `.url` and a `.hash`, so paternitas needs a tagged release first.
  - For local work, `zig build --fork=` or a `.path` to a sibling clone.
    Owner's call.
- H8 The CI in matryoshka-ztk (`linux.yml`, `mac.yml`, `windows.yml`,
  `docs.yml`) then fetches paternitas over the network. `docs.yml` pins Zig
  0.15.2; ztk is 0.16 (plan 019, WORKFLOW).
- H9 `VERSION = "0.1.0"` in `src/matryoshka.zig` says "Matches
  `build.zig.zon`". The zon says `0.0.1`. A mismatch today. **now**, as a
  backlog item (comment or number: code, owner's call).
- H10 The fingerprint is the old tree's, since ztk replaces it (the
  zon comment says so). Fine for route 2. For route 1 too.

## 5. The gates

- H11 The ztk gates, `kitchen/ztk_gates.sh`, live in paternitas's
  `kitchen/`, not in `ztk/kitchen/`. They run from paternitas's root. At
  home ztk needs its own gate script inside `ztk/`. **now**: a copy under
  `ztk/kitchen/` that runs from `ztk/` keeps the move a plain copy.
- H12 paternitas's g4 (`check_docs.sh`: banned words, dead refs) checks
  ztk's docs today. matryoshka-ztk has its own `check_design.sh`: dead refs,
  orphans, forward-looking prose, retired words. ztk's `design/` must pass
  that one at home.
- H13 z4, the rule-2 check (backlog B21), goes into ztk's own script, so it
  travels.

## 6. The docs and the site

- H14 Links that leave `ztk/`: the README's `../paternitas`. At home it is
  a URL. Rule 2: one link. **now**, in the README stage.
- H15 The six `//!` links to `g41797.github.io/matryoshka-ztk/examples/…`
  are dead until the site is published from matryoshka-ztk. They become
  live only at home. Backlog B4.
- H16 `ztk/kitchen/mkdocs.yml`: `site_dir: ../docs`. In paternitas that is
  `ztk/docs`; at the root of matryoshka-ztk it is `docs/`, which the old
  tree uses today. Route 2 overwrites it.
- H17 The matryoshka-ztk site (148 pages) is replaced by ztk's site. The
  old pages are read for the inventory (B28), then go with the old tree.
- H18 The examples catalog generator and the nav sync (B30) run inside
  `ztk/` so they travel.

## 7. The design docs and the rules

- H19 ztk's rules: `ztk/design/rules-003.md` adds to paternitas rules-015.
  At home it merges into the matryoshka-ztk rules (rules-050 → next
  version), with B18–B20 (ztk rules-002).
- H20 Two conventions for old versions.
  - paternitas: `design/backup/`, transient.
  - matryoshka-ztk: kept, listed in context.md "Superseded versions";
    `check_design.sh` fails on an unlisted file.
  - `ztk/design/backup/` (made in ZTK DOCS 01) fails that gate at home.
    Owner's call: list them, or leave `backup/` behind.
- H21 Where a doc lives (rules-050 Part 6): `design/` holds current state;
  the rest goes to `design/secondary/`. ztk's `task1-tests-003`,
  `task2-tests-002`, `*-creation-002` must be sorted.
- H22 ztk design text that lives only in paternitas today:
  - design 017, "ztk on paternitas",
  - `ztk-plan-003.md`, the name table outside plan → today,
  - the ZTK intents 00–02, the findings, the backlog, this file.
  - At home these are ztk's history and design. They must travel, as one
    ztk design doc plus a log entry. **now**: write the ztk-side text into
    `ztk/design/` as it is decided, so the copy carries it.
- H23 The ztk narrative is in paternitas `STATUS-LOG.md`, mixed with
  paternitas stages. At home matryoshka-ztk needs it in its own log. A
  ztk-only summary, written before the move.

## 8. State and plans after the move

- H24 matryoshka-ztk: one STATUS, one plan, one log. The four sets of §1
  fold into them. The old tree's waiting work (root STATUS, its list of waiting work)
  is closed or carried, the owner's call: most of it is about `polynode`.
- H25 paternitas after the move:
  - the owner removes `ztk/`, `kitchen/ztk_gates.sh`, and `design/source/`
    (open item 2);
  - STATUS, the plan and design 017 drop the live ZTK parts and keep one
    line and a pointer to matryoshka-ztk;
  - paternitas CI must not build `ztk/`. Check `.github/workflows/`.
- H26 The memory note `ztk-repo-write-permission` names writes to
  matryoshka-ztk. After the move it is the home repo; the rule stays as the
  owner says.

## 9. What ZTK DOCS can do now, to make the move a copy

Nothing in `ztk/` should name a path above itself (plan 019 says the same
of NEXT).

- No `../` link in ztk text (H14).
- The gate script inside `ztk/` (H11, H13).
- ztk's design decisions written into `ztk/design/`, not only into
  paternitas's `design/` (H22).
- A ztk-only log in `ztk/design/` from now on, or a summary before the
  move (H23).
- The `backup/` question decided before more files go there (H20).

## Questions for the owner

1. H4: route 1 (via NEXT) or route 2 (straight to the root)?
2. H7: how ztk gets paternitas at home: a tag and a hash, or a path?
3. H11, H22, H23: start now — a ztk gate script in `ztk/`, and ztk's
   design and log in `ztk/design/`?
4. H20: `ztk/design/backup/`, or matryoshka-ztk's "listed in context.md"?
5. H1, H2: fix the two stale pointers in matryoshka-ztk now? It is a write
   there.
6. H9: the version mismatch, `0.1.0` against `0.0.1`. Which is right?
