# ZTK HOME — intent (001)

The owner named ZTK HOME, 2026-10-26. Route 2: `paternitas/ztk/` goes to
the matryoshka-ztk root. The audit: [ztk-home-audit-003.md](ztk-home-audit-003.md).

## Checked first

- NEXT unchanged since 2026-09-22: only the two ZTK PREP 01 pointer writes
  and `.idea/`. No merge needed.

## The owner's answers, 2026-10-26

1. The old tree is moved, not deleted: `mv` to `old-tree/` at the
   matryoshka-ztk root. Claude's call: the root, not `design/secondary/`,
   since `check_design.sh` reports every unlisted file under `design/`.
2. `stories/` goes to `old-tree/` too. Not created at the new root.
3. `zig fetch` may run once, for the `v0.0.2` tag.
4. Commands may run in matryoshka-ztk during ZTK HOME.
5. `docs.yml`: Zig 0.15.2 becomes 0.16.
6. `check_next_docs.sh` and the two NEXT history links: Claude's call.
   NEXT is superseded; they stay as a record, untouched.

## Steps

1. `mv` the old tree's `src tests examples stories kitchen docs build.zig
   build.zig.zon README.md` into `old-tree/`. `design/`, `.github/`,
   `LICENSE`, the dot files stay.
2. Copy `paternitas/ztk/{src,tests,examples,negative,kitchen,build.zig,
   build.zig.zon,README.md}` to the root. `ztk/docs/` is build output: not
   copied. `check_design.sh` (and `.check_design_allow` if present) copied
   from `old-tree/kitchen/tools/` into the new `kitchen/tools/`.
3. `zig fetch --save` the `v0.0.2` tag; `.path = ".."` goes.
4. `ztk/design/` folds into matryoshka-ztk `design/`: rules merged into a
   new rules version, `ztk-design-001` in, `ztk-log` to the STATUS-LOG
   head, the rest to `secondary/`, `backup/` listed in the context file.
   New STATUS and plan versions there.
5. B50: `design/cross-repo-001.md` in both repos, ztk's the source.
6. Gates there: `kitchen/gates.sh`, `check_design.sh`, the strict site
   build. Here: the six gates.
7. paternitas STATUS, the plan, the design: one line and a pointer. The
   owner removes `ztk/`, `kitchen/ztk_gates.sh`, `design/source/`.

## Progress, 2026-10-26

- Steps 1 to 3 done. The old tree is in `old-tree/`; the new tree is at
  the root; the zon takes `v0.0.2` by `.url` and `.hash`
  (`paternitas-0.0.1-46sCAS-GAABfU7vaVFHRHWE6ZHkWdI-qi9CS-VUxLXCN`).
- In matryoshka-ztk: four ztk gates pass; the strict site build passes.
- `check_design.sh`: 62 dead refs, no orphans, nothing else. 61 are old
  design docs pointing into the old `kitchen/`, now `old-tree/kitchen/`.
  One was dead before the move: the context file names 3tk-to-ztk-005;
  the file on disk is `-007`.
- Step 4 waits for the owner: the shape of the new `design/`.
- Step 4 done, the owner's answers: the old design docs to
  `secondary/old-tree/`; rules 051 from 015 and ztk 003; the old dead link
  fixed. Steps 5 to 7 done. All gates pass in both repos.
