# paternitas — ADPT 01 intent (002)

The intent for ADPT 01, with the owner's answers to Q1–Q9, 2026-09-25.

Change from 001: the answers are recorded. A4 grows: the other word forms and
the upstream hand-scan entries. A5 turns around: the wrappers keep `.debug`.

- The charter: [implementation-plan-004.md](implementation-plan-004.md).
- The rules it audits: [backup/rules-002.md](backup/rules-002.md). Rules 003
  replaces them.
- Model: Opus 5.5. The stage rewrites the rules later stages run on.

---

## Decisions

- **A1. Cleanup vs approval.** Q1: yes.
  - Cleanup may edit without asking when the edit changes no behaviour.
  - The log lists each edit.
  - An edit that changes behaviour still needs approval.
- **A2. The continue prompt.** Step 12 of rules 003 says it: the prompt begins
  with "Read", and the path is absolute.
- **A3. `kitchen/gates.sh`.** Q2: yes.
  - Runs the five gates in order.
  - Writes `zig-out/g1_*.log` to `zig-out/g5_*.log`. Fixed names.
  - Stops at the first failure.
  - Prints one result line per gate.
  - Pass or fail comes from each exit code, never from the log text.
  - Part 0 "Verification" points to it, and still lists the five gates.
- **A4. The banned-word gate.** Q3: yes to all.
  - `check_docs.sh` adds the six single words of Part 4 it missed.
    - Named there, not here: this file is scanned by the gate.
  - It adds the five multi-word entries of Part 4 as phrases. Five, not six:
    the "escape" entry is already caught by the gate.
  - It adds the other forms of every banned word: `-s`, `-ed`, `-ing`, `-ly`
    and the like.
  - A trial scan of all new entries: 0 hits outside the plan 003 line that
    lists them. Plan 004 rewrites that line.
  - `commit`, `cut` and `hands` stay a hand scan. The meaning decides.
  - From upstream `ZTK/design/rules-050.md`, added to the hand scan in rules 003:
    - `holds`, in the custody sense. Use `keeps`, `has` or `contains`.
    - `object`, meaning an item. Use "item".
- **A5. The stderr noise.** Q4: the wrappers keep `std.testing.log_level =
  .debug`. The owner needs all four levels.
  - The noise is accepted.
  - Rules 003 Part 2 records it: a passing test's log output shows under Zig
    0.16's `failed command:` line. It is not a failure.
- **A6. Hard breaks inside raw HTML.** Q5: yes.
  - `fix_md_hardbreaks.sh` skips lines that start with `<`.
  - It skips everything inside `<style>`, `<script>` and `<pre>` up to the
    closing tag.
  - The trailing spaces already in the raw HTML of `kitchen/docs/index.md` are
    stripped once.
- **A7. The model rule.** Q6: yes, as written.
  - The model follows what the stage writes, not how much it reads.
  - Rules or design: the strongest model.
  - Mechanical sync or a check-up: Sonnet.
  - Said at step 2.
- **S1. The favicon.** Q7: yes to both.
  - Keep ztk's favicon until a logo exists.
  - Delete `kitchen/docs/favicon.ico`. It is byte-identical to
    `kitchen/docs/assets/images/favicon.ico`, and nothing references it. The
    owner approved the deletion.
- **S2. The Examples link.** Q8: yes.
  - An "Examples" button beside the lines-of-code badge, with the badge's
    class. It links to `examples/examples/`.
  - The nav entry stays.

## Order

Q9: yes.

1. Now: parts 1 and 2.
   - Rules 003. Rules 002 moves to `design/backup/`.
   - Design 003 and plan 004, for the new rules file. Plan 005 at close.
   - `kitchen/gates.sh`.
   - `check_docs.sh`, `fix_md_hardbreaks.sh`, `kitchen/docs/index.md`.
   - The favicon duplicate.
   - The five gates.
   - `build_site.sh` and the preview, looked at with the owner.
2. After the owner's push: part 3.
   - The owner pushes, sets Pages to "GitHub Actions", and shares the first
     runs of the four workflows.
   - Claude fixes what they show.
3. Close after part 3: plan 004, a log entry, STATUS.
