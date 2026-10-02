# paternitas — Rules (003)

All coding, doc, and process rules for paternitas.

Change from 002: the ADPT 01 audit. Owner's rulings, 2026-09-25.

- A cleanup edit that changes no behaviour needs no approval. Part 0, Part 1
  step 7.
- The gates run from `kitchen/gates.sh`. Part 0.
- The model follows what a stage writes. Part 1 step 2.
- The continue prompt begins with "Read", and its path is absolute. Part 1
  step 12.
- Test wrappers keep the `.debug` log level, and the noise is written down.
  Part 2.
- The gate enforces the other word forms and the phrases. `holds` and
  `object` join the hand scan. Part 4.
- The hard-break fixer skips raw HTML. Part 5.

Source: a trimmed copy of the Matryoshka rules,
`/home/g41797/dev/root/github.com/g41797/matryoshka-ztk/design/rules-050.md`.

- That file may have a newer version by now. Look for the highest
  `rules-NNN.md` in the same folder.
- A rule there that is not here does not apply here.
- What was kept: Part 0 adapted, Zig style, comments and autodoc, banned words,
  writing documents.
- What was dropped: the Master pattern, stories, dispatch, Matryoshka's
  implementation invariants, its patterns and its provenance.
- What was added: the git rules, and the stage sequence in Part 1.

Companion: [paternitas-design-003.md](paternitas-design-003.md) — the design
decisions and what paternitas keeps from ztk.

---

## Part 0 — Every session

Read this part every session. The rest is reference.

Hard gates.

- No git. The one exception is plain `git status`.
- Every other git operation goes through the owner.
- To move a file, use a plain `mv`. Never `git mv`.
- No file deletions. Ask the owner.
- Show intent before code. The owner approves before code is written.
- Plan approval is not code change approval. Each fix needs its own approval.
  - One exception: a cleanup edit that changes no behaviour. Part 1, step 7.
- Architectural changes need explicit owner approval.
- One stage at a time. No skipping. Each stage passes before the next.
- **No stage starts because a document says it is next.** The owner names it.
- Ask the owner questions as numbered plain text. No picker tool.
- State lives in the owner's `.md` files, not in Claude memory. That is what
  survives a clear.

Documents.

- Never overwrite a doc. Write a new version with the next suffix (-001, -002,
  ...).
- Move the old version to `design/backup/` with a plain `mv`.
- `design/backup/` is transient. The owner deletes from it. It is never a
  source of truth.
- After writing a new version, update every live reference to the old one, in
  the same stage.
- Filling an empty file is not overwriting.
- Three files are handled three different ways.
  - `design/STATUS.md` — updated **in place**. The stable entry point.
  - `design/STATUS-LOG.md` — **appended to**, newest at top. A past entry is
    never edited.
  - `design/implementation-plan-NNN.md` — **versioned**. A new version after
    each completed stage or INTR.
- A bulk repoint of references excludes `design/STATUS-LOG.md`. A past entry
  names the version that was current when it was written. That name is the
  fact it records.
- Read `design/STATUS.md` first. It is current state, not history.

Verification.

- Run kitchen scripts, not manual `zig` commands.
- Run from the repo root.
- `bash kitchen/gates.sh` runs the five gates.
  - In order. It stops at the first failure.
  - One line per gate on the screen.
  - Each gate's output goes to a fixed log: `zig-out/g1_debug.log` to
    `zig-out/g5_fmt.log`.
  - Pass or fail comes from the exit code, never from the log text.
- The five gates, in order:
  1. `bash kitchen/build_and_test_debug.sh`
  2. `bash kitchen/build_and_test_all.sh`
  3. `bash kitchen/build_cross_debug.sh`
  4. `bash kitchen/tools/check_docs.sh`
  5. `zig fmt --check src tests examples build.zig`
- Build before test. `zig build` must pass before `zig build test`.
- Full verification = all four modes: Debug, ReleaseSafe, ReleaseFast,
  ReleaseSmall.
- A stage is complete only when all five gates pass.
- Redirect output to `zig-out/` log files. Read the log file, not shell stdout.
- Run a single gate by hand only to look into a failure.

Status files — where each fact lives.

- Three files carry project state. A fact lives in exactly one. The others get
  a pointer, not a copy.
- `design/STATUS.md` — current state only.
  - Where we are, this rules file, the sources of truth, open items, test
    count, the next stage and its model.
  - No design decisions. They live in `paternitas-design-NNN.md`.
  - No narrative. It lives in `STATUS-LOG.md`.
  - Short. It never grows by accretion.
- The plan — forward-looking work, plus one line per completed stage.
- `design/STATUS-LOG.md` — the narrative. A stage's full account is written
  here and nowhere else. Newest at top. Only its head is read.
- Design decisions, with reasons and owner's rulings, go in
  `design/paternitas-design-NNN.md`.
- A big task gets its own versioned `.md` under `design/`.
- Before deleting stage text from `STATUS.md` or the plan, confirm the same
  content is in `STATUS-LOG.md`. Grep by stage name.

---

## Part 1 — The stage sequence

The usual order in which the owner and Claude work together.

1. The owner names the stage.
2. Claude states the model for it, with the reason.
   - The model follows what the stage writes, not how much it reads.
   - Rules or design: the strongest model.
   - Mechanical sync or a check-up: Sonnet.
   - Say when a stage wants a weaker model.
   - Taking the strongest model silently is a failure.
3. Claude reads what the stage needs and shows intent: what changes, and where.
4. The owner approves, or rules on the open questions.
5. Code.
6. Gates: `bash kitchen/gates.sh`, per Part 0.
   - If the stage touched `build.zig`'s `docs` step, or anything under `src/`
     or `examples/`: run `kitchen/tools/preview_site.sh` and do the
     rendered-page check in Part 3, "Doc target size".
7. Post-stage cleanup.
   - Obsolete parts, wrong comments, repeated code that can be extracted.
   - An edit that changes no behaviour needs no approval.
     - The log's "Post-stage cleanup" row lists each edit.
   - An edit that changes behaviour needs approval.
   - Banned-word hits are step 8, not cleanup.
   - Re-run the gates after cleanup.
8. Banned-word scan over changed `*.md` and `*.zig` — Part 4. Report to the
   owner. Do not fix without approval.
9. Rules audit: check every changed `.zig` and `.md` file against this
   document. Report violations before closing.
10. Close the stage across the three files.
    - `STATUS-LOG.md`: the narrative at the top. Include a "Post-stage
      cleanup" row. Its absence means the step was skipped.
    - The plan: a new version, with one line added to "Completed stages".
    - `STATUS.md`: "Current state" and "Next". Nothing else.
11. Sync `README.md` if the stage changed what it says.
12. End the message with the continue prompt.
    - Three lines: the STATUS file, the stage, the model. Nothing else.
    - The first line begins with "Read". A bare path names a file. "Read"
      makes it an instruction.
    - The path is absolute, so the prompt works from any directory.
    - Say whether to clear or compact.
    - It must not repeat the reading list. `STATUS.md` holds that.

---

## Part 2 — Zig style

Import order (LE style).

- "LE" means "little-endian": imports are placed at the bottom of the file,
  after the code.
- Package and local imports first.
- `const std = @import("std")` always last.
- Do not flag std-last as a violation.

```zig
const helper = @import("helper.zig");
const std = @import("std");
```

SPDX headers.

- Owner-added. Never remove them during edits.
- Do not add SPDX headers to new `src/` files. The owner will.

General style.

- Explicit typing: `const x: T = ...` where the type is known.
- Explicit dereference: `ptr.*.field`.
- Check the standard library before adding custom definitions.
- `errdefer` after every `alloc.create` or resource-acquiring `try`.
- `defer` for cleanup that must run on all exit paths.

Observable by human.

- A function with distinct phases is a coordinator plus named step functions.
- The coordinator shows the whole flow in a few lines.
- Each step function does one step. Its name is its documentation.
- If a block needs a comment to explain it, it should be a named step instead.
- A 1-2 line guard or log between step calls stays inline.

One quality bar.

- Tests and examples meet the same bar as `src/`.
- No throwaway code in any category.
- Tests check correctness. They are internal and not in the generated docs.
- Examples show one pattern. They are part of the generated docs.

Examples.

- Entry point: `pub fn <snake_case>(allocator: std.mem.Allocator, io: std.Io) !void`.
- Never a quoted identifier (`@"..."`). Autodoc cannot resolve its links.
- No `std.testing` inside example code. No `std.debug.assert`.
- A test wrapper in `tests/` calls the example and checks it.
- Test wrappers supply `std.testing.allocator` and `std.Io`.
- Test wrappers set `std.testing.log_level = .debug`. The owner wants all four
  levels.
  - Zig 0.16 prints a passing test's log output under a `failed command:`
    line.
  - It is not a failure. The gate logs carry it on every run.
  - Pass or fail comes from the exit code.

---

## Part 3 — Comments, doc comments, autodoc

### What a comment says

Staccato applies. It is defined once, in Part 5.

- Do not explain WHAT. Names do that.
- Explain WHY only if non-obvious.
- No multi-paragraph docstrings.
- No "used by X" or "added for Y flow" comments.
- No references to `.md` files inside `src/*.zig` comments.
  - Readers of source or generated docs see only the `.zig` files.
  - Comments are self-contained. State the fact, do not point at a doc.
- File-header `//!` standard: model on `std.Io`'s own file header.
  - A header that reads as one run-on paragraph across several `//!` lines is
    a violation, even if each line is short.

### `///` and `//!` in `src/`

- `//!` at the top of each file: the module description.
- `///` on every `pub` declaration: function, type, error set, const.

First-declaration doc-stub rule.

- If a file's first declaration after the `//!` header carries a `///`
  comment, autodoc splices that comment onto the module overview page.
- Fix: insert `const _doc_stub = void;` as the first declaration after the
  `//!` header. No doc comment, not `pub`.
- Only needed when the first declaration would otherwise carry a `///`
  comment.
- Verify by rendering the page, not by reading the source.

### Description as code

An example's `//!` description is written like its code.

- One-line intent first. This is the coordinator line.
- Then named steps as bullets, one per bullet, in the order they run.
- Any ASCII diagram inside a `//!` block sits in a fenced code block.
  - Autodoc renders doc comments as CommonMark, which collapses single line
    breaks.
- Mixing `//!` and `///` above the same function is a bug.
- The entry point sits at the top of the file, directly after the `//!` block.
- Imports stay at the bottom.

### Doc target size

- `build.zig`'s `docs` step never roots a doc target at a module whose import
  graph spans a large tree.
  - Such a target makes the autodoc client hang on "Loading..." with
    `RangeError: Maximum call stack size exceeded`.
- `zig build docs` exiting 0 is necessary, not sufficient.
- Load the generated page in a browser and check the console for `RangeError`
  or `Uncaught`.
- Check `tar tf kitchen/docs/apidocs/sources.tar` for files outside the
  target's own area.

### Live-scan rule

- A scan is "done" only when re-run live against current file contents at the
  moment of the claim.
- A prior pass's claim of completion is not sufficient.

---

## Part 4 — Banned words

Scan `.zig` and `.md` after any stage that changes them. Report hits to the
owner. Do not fix without approval.

`kitchen/tools/check_docs.sh` enforces the list below.

- It matches each word, its other forms, and each multi-word entry.
- A multi-word entry split across two lines is missed.
- The hand scan covers what only the meaning decides: "commit", "cut",
  `hands`, `holds`, "object".

Scan scope.

- Skip `design/STATUS-LOG.md` and `design/backup/`. Both record what is gone.
- Skip `design/paternitas-001.md`. It is kept untouched.
- The gate skips this rules file, because it has to name every word. Scan it
  by hand, and read each hit: a hit outside the lists below is a real one.
- Stdlib names are not hits.

Words.

- `drain` — use `clear`, `reset`, `empty`, or a domain verb.
- `dll` / `DLL` — clashes with Windows DLL. Spell out `DoublyLinkedList`.
- "commit" meaning save or update — it implies git. Say "save", "update" or
  "write".
- "cut" meaning a new version — say "write a new version".
- `seam`, `seamless` — use "boundary", or name the two things that meet.
- `sweep` — say what the work is.
- `settle`, `settled` — use "agreed", "decided", or "the owner accepted it".
- `underneath` — name the thing.
- `on purpose` — give the reason, or state who does it.
- `hatch`, including "escape hatch" — name the field.
- `parked` — say "waiting", and name what it waits on.
- `lifecycle` — say "usual flow" or "states".
- `ledger` — say what the list is.
- `hands`, in the custody sense — use "gives back", "returns", "passes to".
- `holds`, in the custody sense — use `keeps`, `has` or `contains`.
- "object" meaning an item — use "item". "object" elsewhere is fine.

AI-sh word list.

- robust, seamlessly, comprehensive, leverage, efficient, powerful,
  facilitate, utilize, ensure, performant, ergonomic, idiomatic, streamline,
  orchestrate, sophisticated, intuitive, scalable, unlock, empower, harness,
  deliver, fed, arm, leg, idempotent, fires, faces, pitch, object model,
  execution context, execution model, programming model, paradigm, mindset,
  ownership, gained, wire, wired, wires, wiring.
- For the `wire` family use "connect", "hook up", or the concrete action.

Replacements for `ownership`. Name the action instead.

| instead of | write |
|---|---|
| transfers ownership | the item moves |
| caller retains ownership | the caller keeps the item |
| exclusive ownership | exclusive access |

---

## Part 5 — Writing documents

### Present tense

- A design doc describes what is, not what will be.
- Forward-looking work belongs in the plan.

### Staccato — the one definition

Applies everywhere text is written: documents, comments, doc comments, example
descriptions.

- A document is not a novel. Do not use prose style.
- Use simple English. Use short sentences.
- Start with a short introduction, then a bullet list.
- One fact per bullet.
- No prose paragraphs with comma-separated lists.
- Do not chain multiple ideas into one sentence.
- Break a long sentence into several short sentences, or into bullets.
- When a bullet splits at a colon, at "and", or into sub-items, demote each
  part to a nested bullet.
- Do not replace bullet lists with many standalone one-line sentences.

Diagrams.

- Use ASCII diagrams. Make them human-readable.
- Prefer clarity over brevity.

Structure.

- Cross-reference instead of duplicating.
- When extending a document, match the heading levels already in use.

### Markdown hard breaks

- CommonMark joins two lines separated by a single newline into one line.
- A two-line effect survives only two ways.
  - The first line ends with two or more trailing spaces.
  - The two lines are separated by a blank line.
- Prefer the blank line.
- `kitchen/tools/fix_md_hardbreaks.sh` fixes `kitchen/docs/**/*.md`. It runs
  inside `build_site.sh` and `preview_site.sh`.
- It skips a page's leading front matter block.
- It skips raw HTML.
  - A line that starts with `<`.
  - Everything inside `<style>`, `<script>` and `<pre>`, up to the closing
    tag.

### mkdocs pages — blank line before every list

- Put a blank line between a lead-in line and the list after it.
- Without it, mkdocs renders the list as flat text.
- Verify with `mkdocs build --strict`, not by reading the source.
- `kitchen/tools/fix_md_lists.sh` fixes `kitchen/docs/**/*.md`. It runs inside
  `build_site.sh` and `preview_site.sh`.
- It skips a page's leading front matter block.
