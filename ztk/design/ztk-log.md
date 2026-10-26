# ztk — session log

Append-only. Newest entries at top. Only the head is read.

The ztk work from 2026-10-22 to 2026-10-26 happened in the paternitas repo,
with `ztk/` at its root. Its full narrative is in paternitas
`design/STATUS-LOG.md`, mixed with paternitas stages. This log starts with a
summary of that work, so it travels with `ztk/` (B39, H23).

---

## 2026-10-26 — ZTK PREP 02 (Opus 5.5)

- The ztk gates live in `kitchen/gates.sh`, inside ztk. It runs from any
  directory. Logs: `zig-out/z1_test.log` to `zig-out/z4_readme.log`.
  paternitas `kitchen/ztk_gates.sh` only calls it, until the move.
- `design/ztk-design-001.md`: ztk's design notes, copied from paternitas.
- This log.
- Links above `ztk/`: listed for the owner. See the paternitas review file
  of ZTK HUMAN and ZTK PREP 02.

---

## 2026-10-22 to 2026-10-26 — the ztk work in paternitas, a summary

- ZTK 00. `ztk/` set up at the paternitas root, on `.path = ".."`. Three
  gates: tests, negatives, fmt.
- ZTK 01. ztk green on paternitas. `AnyParent = paternitas.Any`, ztk's
  narrower view. The ztk rules: a ztk user needs to know only how to
  embed one TypedNode; Paternitas is named in three places only.
- ZTK 02. Example 104, a DoublyTypedNode parent from your own timeout list
  through a mailbox and back. Example 105, a handler map that keeps the Slot
  to the end. No `AnyParent` receive form: Slot usage is MUST.
- ZTK DOCS 01. The docs audit. Every finding is in the backlog.
- ZTK PREP 01. `VERSION` and its two tests removed. Two pointers fixed in
  matryoshka-ztk, with the owner's permission.
- ZTK DOCS 02. The site frame: the hero, the nav groups, strict build.
- ZTK DOCS 03. The inventory of the 60 matryoshka-ztk pages: take,
  rewrite, merge or drop.
- ZTK DOCS 04. Four comments no longer name Paternitas.
- ZTK DOCS 05. The first real README. Example 020 cleaned. Gate z4 checks
  "about 800 lines". Two old README notes moved to the site as drafts.
- ZTK HUMAN. Every comment in `src/`, the 75 example headers, the example
  helpers and the tests rewritten for a human reader. Example headers open
  with `//! Title: ...`. A fix: `newPool` in the comments is `pool.new`.

The state files of that time, all in paternitas `design/`: STATUS, the
plan (033), the ztk backlog (013), the intents of each stage, the ZTK HOME
audit (002).
