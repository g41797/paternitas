# paternitas — ADPT 01 intent (001)

The intent for ADPT 01, shown to the owner on 2026-09-25. Nothing is changed
yet. Waiting on the owner's answers to Q1–Q9.

- The charter: [implementation-plan-003.md](implementation-plan-003.md).
- The rules it audits: [rules-002.md](rules-002.md).
- Model: Opus 5.5. The stage rewrites the rules later stages run on.
- Gate 1 passes on the current tree. Log: `zig-out/adpt01-gate1.log`.

---

## 1. The process audit

One full stage walked against `rules-002.md` Part 1. Findings:

- **A1. Cleanup vs approval.**
  - Step 7 says to fix obsolete parts during cleanup.
  - Part 0 says each fix needs its own approval.
  - Step 8 says do not fix without approval.
  - The rules do not say whether cleanup edits need approval.
- **A2. The continue-prompt ruling is only in the log.**
  - The owner ruled: the prompt begins with "Read", and the path is absolute.
  - Step 12 does not say it.
- **A3. The gates cost round trips.**
  - Gate 5 is a bare `zig fmt` command.
  - The log names are not fixed. INTR 15 used `g1_debug.log` to `g5_fmt.log`.
  - Proposed: `kitchen/gates.sh`.
    - Runs the five gates in order.
    - Writes `zig-out/gN_*.log`.
    - Stops at the first failure.
    - Prints one result line per gate.
- **A4. The banned-word gate.**
  - Add `fed arm leg fires faces pitch` to `check_docs.sh`.
    - A trial scan hits only the plan's own line that lists them.
    - Plan 004 rewrites that line.
  - Gate the six multi-word entries of `rules-002.md` Part 4 as phrases.
    - Named there, not here: this file is scanned by the gate.
  - `commit`, `cut` and `hands` stay a hand scan. The meaning decides.
- **A5. The stderr noise.**
  - Cause: the test wrapper sets `std.testing.log_level = .debug`.
  - The example logs at `info`. Zig 0.16 prints it under `failed command:`.
  - Proposed: drop that line from the wrappers.
    - The default level hides `info`.
    - Examples keep their logging for the docs page.
  - One line in Part 2 records it.
  - Verified by gate 1 after the change.
- **A6. Hard breaks inside raw HTML.**
  - `fix_md_hardbreaks.sh` rewrites the source in place.
  - `kitchen/docs/index.md` already carries trailing spaces in its `<style>`
    block and in the hero `<div>`.
  - Proposed: skip lines that start with `<`.
  - Proposed: skip everything inside `<style>`, `<script>` and `<pre>` up to
    the closing tag.
  - Then strip the trailing spaces already in `kitchen/docs/index.md`.
- **A7. The model rule for a mostly-reading stage.**
  - The model follows what the stage writes, not how much it reads.
  - Rules or design: the strongest model.
  - Mechanical sync or a check-up: Sonnet. Said at step 2.

## 2. The site check-up

- **S1. The favicon.**
  - Keep ztk's until a logo exists, like the placeholder sources.
  - `kitchen/docs/favicon.ico` is a duplicate of
    `kitchen/docs/assets/images/favicon.ico`. Nothing references it.
  - Deleting it needs the owner.
- **S2. The Examples link.**
  - The landing page hides the navigation. Examples is unreachable from it.
  - Proposed: keep the nav entry.
  - Proposed: add an "Examples" button beside the lines-of-code badge.
- Then `build_site.sh` and the preview, looked at with the owner.

## 3. The CI check-up

The owner's part.

- Push.
- Set Pages to "GitHub Actions".
- Share the first runs of the four workflows.

Claude fixes what they show.

## 4. What gets written

- A new rules version, 003, for A1, A2, A5 and A7. `rules-002.md` moves to
  `design/backup/`.
- Script edits for A3, A4 and A6.
- The test wrapper for A5.
- `kitchen/docs/index.md` for A6 and S2.
- Close: plan 004, a log entry, STATUS.

## Questions

1. A1: may cleanup edit without asking, when it changes no behaviour and the
   log lists each edit? Or does every edit need approval?
2. A3: add `kitchen/gates.sh`?
3. A4: gate the six words and the six phrases? Leave `commit`, `cut` and
   `hands` to the hand scan?
4. A5: drop `log_level = .debug` from the wrappers?
5. A6: skip raw HTML in `fix_md_hardbreaks.sh`, and strip the existing spaces
   in `kitchen/docs/index.md`?
6. A7: accept the model rule as written?
7. S1: keep ztk's favicon for now? Delete the duplicate
   `kitchen/docs/favicon.ico`?
8. S2: add the Examples button?
9. Run parts 1 and 2 now, and part 3 after the owner's push?
