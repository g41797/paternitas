# ZTK DOCS 05 — the README, first real version (intent 001)

The owner named the stage, 2026-10-26. Items B11, B10, B45. The owner's
answers of the same day are below. The work is iterative: one small step at
a time. Ideas not yet agreed live in
[ztk-docs-05-ideas-001.md](ztk-docs-05-ideas-001.md), so a clear loses nothing.

## The owner's answers

1. The README is short for now. NEXT's 1309-line `README-001` is not the
   base. Its ideas wait in the ideas file for later rounds.
2. The opening stays: "Software has two worlds", and the title "Toolkit for
   Building Background Processes".
3. The first example follows the pipeline example from an earlier README.
   Claude finds that README and shows it to the owner first. New or changed
   example code needs its own approval.
4. Install says "to come". The zon takes paternitas by `.url` and `.hash`
   only at ZTK HOME.
5. The badges stay and point at the matryoshka-ztk workflows. The README
   links the ztk site, on the matryoshka-ztk GitHub Pages URL.
6. The README states its lines of code. A ztk gate checks the claim, as g4
   does for paternitas. B45.
7. "Paternitas 101" is a new page in `addendums/`, separate from B13. It
   comes later, not in this stage. B44. "Built on Paternitas" links to it.

## The README's parts

- The logo and the badges.
- "Software has two worlds", the title.
- What you get: a short list.
- Install: "to come".
- The first example: a pipeline, after point 3.
- Built on Paternitas, rule 2's form: what it is, that ztk's docs cover all
  a ztk user needs, one link, and that it need not be read.

## Steps

1. Find the pipeline example (point 3). Show it to the owner.
2. Write the README skeleton. The owner reads it.
3. Fill the parts one at a time. The owner reads each.
4. The lines-of-code claim and its gate check (B45).
5. Close: three ztk gates, six paternitas gates, the ztk strict build.

## State

- Step 1 is done, 2026-10-26. The example is
  `ztk/examples/layer4/020-pipeline_masters.zig`. The owner's rulings:
  - The README shows its diagram and `transformerFn`, and links the file.
  - `poly` is now `anchor`. The `destroySlot` calls that `defer` already
    makes are gone. The file before the change:
    `design/backup/020-pipeline_masters-001.zig`.
  - "Master" stays for now. A comment says a Master is your code, not
    ztk's. B42 is still open.
  - Three ztk gates and six paternitas gates pass.
- Step 2 is written, 2026-10-26: `design/backup/ztk-readme-draft-002.md`. It
  waits for the owner. The working draft is a separate file because today's
  `ztk/README.md` has notes no site page has yet (the MUST rule). The draft
  replaces it once those notes have a place.
- Measured: `count_src_loc.sh` 801, `count_readme_loc.sh` on today's README
  48.
- The owner read the skeleton, 2026-10-26: the parts and order agreed.
  "Learn more" stays. "License" goes: the badge has it. "What you get"
  names the mailbox, the pool, the queue, the helper.
- The old README's notes moved, the owner's approval:
  - "Steps for a reader" to `ztk/kitchen/docs/get-started.md`, as a draft.
    Its planning line about 3tk's "How to start" was dropped (F3.4).
  - "The bridge" and "The working code" to the new
    `ztk/kitchen/docs/patterns/bridge.md`, "Crossing to std.Io", in the nav.
  - The model text of "Built on Paternitas" is backlog B47, word for word.
  - The ztk strict site build passes. g4 passes.
- Next: step 3, fill the draft's parts one at a time. When it is done, it
  replaces `ztk/README.md`.
- Draft 002, 2026-10-26: the lines-of-code line ("about 800", the owner),
  "What you get" (agreed; "hooks" stays), "A pipeline" written, waiting.
  B45's gate checks "about 800", not an exact number.
- The pipeline answers: an Anchor bullet added; the code stays exact;
  "Nothing leaks" stays. "Built on Paternitas" and "Learn more" written.
  The draft is complete, 75 lines, waiting for the owner's full read.
  "Built on Paternitas" links the paternitas site until B44 exists.
- The owner: "ok, replace README". `ztk/README.md` is draft 002. The old
  README: `design/backup/ztk-README-temp-001.md`. Draft 002:
  `design/backup/ztk-readme-draft-002.md`.
- Step 4: `ztk/kitchen/tools/check_readme_claim.sh`, run as gate
  `z4_readme` in `kitchen/ztk_gates.sh`. It rounds `count_src_loc.sh` to
  the nearest hundred and compares with "about N lines of Zig". Tried with
  "about 900": it fails and names 800.
  - ztk rules-001 reserves "z4" for the rule 2 check. That check becomes z5,
    when it is approved. Waits for the owner.
- Step 5: four ztk gates, six paternitas gates, the ztk strict build pass.
- Closed, 2026-10-26. Plan 032, backlog 012, ztk rules 002.
