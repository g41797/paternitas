# ztk — writing the doc comments

**`001`, created 2026-09-20 while the documentation stages were being planned,  
on Opus 5.** Nothing is superseded; this is the first version.

**The subject document of the COMMENTS stage** in
[next-staging-plan-018.md](../../next-staging-plan-018.md). The plan carries a
short description and a link.

**Why this stage matters more than it looks.** The old mkdocs pages are frozen  
and unreachable. The per-module part of each generated page is what carried  
them, so **these comments are the documentation now** — not a supplement to it.

**It runs after README.** Its input is the module mapping table in
[readme-creation-001.md](readme-creation-001.md): each file's *source passage*
is the README wording the block is written from, and *the block owes* is the  
detail the README could not carry.

---

## What is decided

1. **The rules already exist and are not rewritten:** `design/rules-050.md`
   Part 4 — Comments, doc comments, autodoc. This document does not restate  
   them; it records what a session gets wrong and what ztk decides on top.
2. **A template first.** One header, drafted, rendered, checked, and shown to
   the owner **as a page** rather than described as a plan. Only then the rest.
3. **Verify by rendering, not by reading.** Part 4 says so, and the two failure
   modes below are invisible in source.
4. **No behaviour changes.** A shape that reads badly in a doc comment is
   reported to the owner, not fixed in `src/`.
5. **Nothing is said in both tiers.** A fact that earned its place in the README
   is not repeated in the block. The mapping table is what keeps that honest.

## What is open

| | what | why it is open |
|---|---|---|
| **O-1** | **Which file gets the template.** `matryoshka.zig` is the module root and the first page a reader lands on, so it is the natural one. But a template is several throwaway drafts, and `src/` has not changed since POOL | The owner rules whether drafts happen in `src/` or in a scratch file, with only the final one written in |
| **O-2** | **Whether the zig-docs-comments file in the owner's Downloads folder is taken in.** Written by another AI on 2026-09-20, 46 lines. **Not a source of truth** | If taken, it comes the way the external meta-plan in `design/secondary/lang/common/` did: as it arrived, `-external-` in the name, cited for reasoning and never as authority |
| **O-3** | **How much of the examples' `//!` blocks change.** 93 example files already carry description-as-code blocks with ASCII diagrams, written under Part 4 | They may already be right. Measure before touching any of them |

---

## The four failures Part 4 exists to prevent

**Each of these is invisible when reading the source.**

1. **The splice.** A `///` on the first declaration after the `//!` header is
   spliced onto the module overview page with no separator, whatever blank lines  
   sit between them. The fix is `const _doc_stub = void;` — private and  
   undocumented, so it renders nowhere. **`src/matryoshka.zig:17` already has  
   one.** The other files need checking one by one.
2. **The collapse.** Autodoc renders doc comments as CommonMark, which folds
   single line breaks into one paragraph. A box-drawing diagram loses its shape  
   unless it sits in a fenced block. Every ASCII picture in a `//!` is fenced.
3. **The truncation.** `//!` and `///` above the same function are different
   token kinds to the parser, and the doc silently truncates to whichever sits  
   immediately above. Mixing them is a bug, not a style choice.
4. **The unfollowable reference.** A `.md` file named from inside `src/` cannot
   be followed by a reader of the generated page. Comments are self-contained.

**A fifth, from Part 4 and worth repeating here:** a documented assert must  
exist. MBOX 1 found 15 entries in the old tree's pages naming an assert that was  
never in the source and could not have compiled. It survived because nothing  
compiles a doc page.

---

## What ztk has to say that 3tk does not

The mapping table's *block owes* column, gathered here as the work list. Every  
line traced to `readme-creation-001.md`'s measured inventory.

| file | what only the block can carry |
|---|---|
| `matryoshka.zig` | one module and not six; the root is the whole surface; `VERSION` |
| `inner.zig` | `OuterId` is an opaque pointer compared by address, not a language typeid, and null is the unstamped id, so a zeroed inner is unstamped and zeroed memory is a valid unstamped outer; the descriptor behind an id is internal and a caller reads nothing out of one; the std node, 16 bytes, and the border to a plain `std.SinglyLinkedList`; `AnyOuter` as a border type |
| `helper.zig` | the inner field found by type and not by name, and zero or two being a compile error; why `create` takes `(alloc, io)` where 3tk takes an allocator alone; the MUST that an outer keeping the `Io` does not outlive its runtime; `takeFromSlot` and `fillSlot` as the per-item border |
| `queue.zig` | the tail pointing at itself, so the link test sees a chain of one; no bulk input; moved never copied; `countOfId` in place of an iterator |
| `mbox.zig` | the outcome set per call; `sendLimited` as its own call; `close` returning a `Queue` by value; `destroy` aborting in every build and why that is not a fast-build assumption; `receiveFuture` and `receiveResult` |
| `pool.zig` | `GetMode`'s three policies; the three hooks and their real signatures; no hook taking an `io`; `on_close` called more than once and twice at once; the stack, so reuse is last in first out; `getWaitFuture` and `getWaitResult` |

**The two `Result` unions and `Io.Cancelable` have no 3tk counterpart at all.**  
Whether the README mentions them is `P-27` in `readme-creation-001.md`. Whether  
it does or not, **the blocks carry them**, because they are in every waiting  
signature.

---

## The order

1. Measure. Which files already satisfy Part 4, and which carry a splice risk.
   `matryoshka.zig` has the stub; the other nine are unread on this point.
2. The template, rendered with `preview_apidocs.sh`, checked against Part 4,
   shown to the owner as a page.
3. The five remaining `src/` files, in the mapping table's order.
4. The examples, only if `O-3` says they need it.
5. Render the whole site and read it as a visitor would — the landing page's
   badge leads straight here, in the same tab, and this is what it leads to.

---

## Changelog

| version | stage | date | what changed |
|---|---|---|---|
| `001` | planning | 2026-09-20 | Created. The decided and the open, the four failures Part 4 prevents, the work list derived from the README document's mapping table, and the order. No comment written. |
