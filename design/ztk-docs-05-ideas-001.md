# ZTK DOCS 05 — ideas and proposals not yet agreed (001)

Ideas kept so a clear loses nothing. None is decided. The owner rules on
each before it is used. The intent is
[ztk-docs-05-intent-001.md](ztk-docs-05-intent-001.md).

## For later README rounds

- NEXT's draft, `ztk/design/README-001.md`, copied as is from matryoshka-ztk
  `NEXT/ztk/design/README-001.md`.
  It has 1309 lines in old names. No pipeline example in it. B46. Its story order may feed the site pages:
  - the process, threads, the queue at the centre
  - no allocation on transfer, a queue that does not know your types
  - the pool, the reuse rules, then the Matryoshka name
- `ztk/design/readme-creation-002.md`, the same as NEXT's
  `NEXT/ztk/design/readme-creation-002.md`,
  has open questions O-1 to O-5 and
  P-27 (cancellation and futures). Nobody ruled on them.
- The "Steps for a reader" in today's `ztk/README.md`: one thread, add a
  thread, add a pool, swap the channel for a mailbox. It may become Get
  Started.
- The bridge notes in today's `ztk/README.md` belong on a site page, not in
  the README.

## Paternitas 101 (B44, later)

- A page in `ztk/kitchen/docs/addendums/`.
- Paternitas explained for a ztk reader. It says it need not be read.

## The first example (step 1)

- The owner's candidate, 2026-10-26: `ztk/examples/layer4/020-pipeline_masters.zig`,
  179 lines, today's names. Its NEXT original is
  `matryoshka-ztk/examples/layer4/020-pipeline_masters.zig`, old names.
- Producer, transformer, consumer. Two mailboxes. Events become Sensors. A
  ShutdownCommand stops the chain.
- Agreed and done, 2026-10-26; see the intent's State. The proposal was: the README shows the diagram
  and `transformerFn` only, about 25 lines, and links the file.
- What stands in the way of a README snippet:
  - "Master" in its name and its struct. B42 is open.
  - The variable `poly` is an old name for `*Anchor`.
  - `destroySlot` is called by hand and again by `defer`.
  - `init` and `destroy` take about 40 lines of setup.
  - These are code changes. Each needs the owner's approval.

## Where today's `ztk/README.md` notes go (agreed and done, 2026-10-26)

- "Steps for a reader": the spine of Get Started, `ztk/kitchen/docs/get-started.md`.
- "The bridge" and "The working code": a new page, Patterns, "Crossing to
  std.Io", `ztk/kitchen/docs/patterns/bridge.md`. Its example: `examples/bridge/104`.
- "Built on Paternitas", the Matryoshka model part: Background, Ideas, the
  Matryoshka model page. Until then, B44 Paternitas 101 or the backlog.
- In this stage the text moves as is, marked as a draft. The page stages
  rewrite it later.
