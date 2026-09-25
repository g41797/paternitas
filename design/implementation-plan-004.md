# paternitas — Implementation plan (004)

Forward-looking work, plus one line per completed stage.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- Rules: [rules-003.md](rules-003.md).
- Design decisions: [paternitas-design-003.md](paternitas-design-003.md).
- Change from 003: ADPT 01 is in progress. The owner ruled on its items. The
  rules file is 003.

**No stage starts because this plan says it is next.** The owner names it.

---

## Completed stages

- INTR 15 (2026-09-25, Opus 5.5) — the development process moved from next/ztk
  into paternitas: rules, design doc, placeholder skeleton, kitchen, site, CI.
  Five gates green.

---

## ADPT 01 — adaptation

Tune the workflow before any real code. Model: Opus 5.5.

- Reason for the model: this stage rewrites the rules the later stages run on.
  A mistake here is paid for in every stage after it.

Intent first, per `rules-003.md` Part 1. The owner ruled on each item,
2026-09-25. The rulings: [adpt-01-intent-002.md](adpt-01-intent-002.md).

### 1. The deeper process audit

- Walk one full stage on paternitas against the rules' Part 1, step by
  step. Note every step that is unclear, missing, or costs a round trip.
- Start from the quick-pass findings in `STATUS-LOG.md`, INTR 15.
- Items carried over from INTR 15:
  - The banned list in `check_docs.sh` omits some entries of the rules'
    Part 4: six single words, and the multi-word entries. next/ztk's gate
    omitted them too. Decide: add them, or record why not.
  - Zig 0.16 prints a passing test's stderr under a `failed command:` line.
    The gate logs carry it on every run. Decide whether examples log at all
    in tests, or the noise is accepted and written down.
  - `fix_md_hardbreaks.sh` adds trailing spaces inside the landing page's
    `<style>` block. Harmless. Decide whether it should skip raw HTML too.
- Decide what the model rule says for a stage that is mostly reading.

### 2. The site check-up

- Rebuild with `build_site.sh` and look at it with the owner.
- The favicon is ztk's. Decide: keep it until a logo exists, or replace it.
- Decide whether the Examples page stays in the nav while the landing page
  hides the navigation.

Parts 1 and 2 run now. Part 3 runs after the owner's push.

### 3. The CI check-up

- The owner pushes, and reads the four workflows' first runs.
- GitHub Pages must be set to deploy from GitHub Actions, in the repo
  settings. Owner's action.
- Fix what the first runs show.

### 4. Close

- Per `rules-003.md` Part 1, step 10: a new plan version, a log entry, STATUS
  updated.

---

## Deferred

- **`negative/` and gate 6.** Deferred to the first stage where paternitas
  refuses something: a compile error, or a panic in safe builds. The build
  step, the folder and the gate arrive together then. The shape to follow is
  next/ztk's, listed in `paternitas-design-003.md`.
- **`paternitas-001.md`.** The advice the owner collected. Read after ADPT 01,
  not before. It may feed the README, the implementation, and the start of the
  design.
- **README text.** `README.md` stays at the owner's `WIP` until ADPT 01, unless
  the owner says otherwise.
