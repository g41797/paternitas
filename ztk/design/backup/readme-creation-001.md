# ztk — writing the README

**`001`, created 2026-09-20 while the documentation stages were being planned,  
on Opus 5.** Nothing is superseded; this is the first version.

**The subject document of the README stage** in
[next-staging-plan-018.md](../../next-staging-plan-018.md). The plan carries a
short description and a link. Everything else about the README lives here.

**What this is for.** The README is written over several rounds, and the owner  
clears the session between them. This file is what survives. A round reads  
**What is decided** and **What is open** first, and nothing else is needed to  
continue.

**Its second reader is the COMMENTS stage.** The wording that survives the  
README becomes the `//!` module blocks in `src/*.zig`. The module mapping table  
at the end is written for that stage, and its own subject document is  
`comments-creation-001.md` beside this one.

**The starting text is 3tk's README**, in the `matryoshka-3tk` repository. It is  
frozen there and read when needed rather than copied in, so there is no second  
copy to drift. **Its intent, order and mantra are right and are not reopened.**  
What changes is every place it states a C3 fact.

---

## What is decided

**The owner's rulings. A round applies them and does not reopen them.**

1. **The README is the entry to the project.** With the landing page's picture
   un-linked, there is almost nothing behind it. It carries the project.
2. **It is for working developers. Human beings.** They will not read AI slop,
   impressive vocabulary, or a large documentation site.
3. **The 3tk README is the base.** Its intent, order, wording and mantra come
   across. **Only the facts that are wrong for Zig are rewritten.**
4. **The old ztk README is not a starting point, and neither is its tone.** The
   3tk README broke completely with every ztk README before it.
5. **The working file is README-001 in `ztk/design/`**, versioned, with
   superseded copies in `ztk/design/backup/`. The approved text becomes  
   `ztk/README.md` at the end of the stage, and the repository root's  
   `README.md` at PROMOTE.
6. **Iterative, in small units.** One section at a time. Text the owner has
   approved is not re-touched.
7. **Who writes which part.** The owner or another model drafts. This side
   supplies material before a draft and checks and cuts after one. Recorded in  
   `3tk-to-ztk-007.md` under **Who writes which part**.
8. **Every factual claim about ztk is checked against `src/*.zig`.** That is the
   only source of truth. It is what both 3tk drafts failed at, and the failure  
   is on record there as six errors.
9. **Constraints that can be checked**, in place of instructions about quality:
   one idea per line; no adjective without a number or a code reference behind  
   it; no sentence that still works when deleted; a section opens on the  
   reader's problem, not on a feature; no snippet that is not copied from a file  
   that compiles.
10. **The README measures itself.** `count_readme_loc.sh` and
    `count_src_loc.sh` produce the two numbers the opening states. They are  
    computed, never typed.

## What is open

**Nothing is drafted yet.** These are the questions a round must not decide on  
its own.

| | what | why it is open |
|---|---|---|
| **O-1** | **Which of 3tk's 34 rulings are the family's and which are C3's.** They are listed below as candidates, not imported as decided | Some are about how any Matryoshka README works. Some are about C3. Importing all 34 would carry C3 decisions into a Zig page |
| **O-2** | **The family section.** 3tk's says Zig is *"The second. Still in progress."* In ztk's own README that sentence is about itself | Only the owner can say what ztk claims about its own state |
| **O-3** | **The `(alloc, io)` pair.** 3tk's `mailbox::create` takes an allocator; ztk's takes both, because Zig 0.16 split the environment in two | The *why* is one sentence and it is the owner's to write |
| **O-4** | **Whether the minimal channel-to-mailbox example is written** | Step 2 of *How to start* names an example that does not exist in ztk. See `B-1` below |
| **O-5** | **Whether the README links the generated docs site.** 3tk ruled no link, anywhere, for now — its ruling 33 | ztk has a landing page and 3tk has none, so the ruling may not carry |

**Debts — what the README depends on that does not exist yet.**

| | what | where the README depends on it | owner of the work |
|---|---|---|---|
| **B-1** | **No minimal channel-to-mailbox example.** ztk has the full bridge flow — `examples/bridge/104-server_handler_and_workers.zig`, 205 lines — but nothing small | *How to start*, step 2. 3tk names `shc::l_bridge::from_a_channel_to_a_mailbox` there | Deferred by BRIDGE. `O-4` decides whether the README stage writes it |
| **B-2** | **No step-1 example that reads as a story.** `examples/layer1/021-define_type.zig` is 63 lines of assertions | *How to start*, step 1 — put an `Inner` in your struct, chain a few, take them out | Open. A ten-line example would open the README better than four assertions |

---

## The reader

**Unchanged from 3tk**, because the reader is the family's, not the language's.  
The one `kitchen/docs/addendums/why-boring.md` describes, in the frozen root.

- Not a systems programmer. Not an async enthusiast.
- His nouns are `Customer`, `Order`, `Invoice`, `Payment`.
- Transport is irrelevant to him. He cares that `CreateOrder` arrived.
- He measures before optimizing.
- **Boring means predictable.** Not slow, not old.

**One difference worth stating.** The Zig reader arrives at a language whose  
standard library moved under him — `std.Io` is new, and the environment is two  
values now, not one. He is more likely to be holding an `Io` already and  
wondering where the toolkit fits beside it. That is what the bridge example  
answers, and it is why `AnyOuter` exists at all.

## The required order

**3tk's, and it is the family's.** Each right-hand term is introduced only once  
its left-hand problem has been stated.

```text
   ordinary background process
              |
              v
   threads with responsibilities that must exchange work
              |
              v
   communication is the center  --------->  mailbox
              |
              v
   transfer must not allocate  ----------->  intrusive
              |
              v
   infrastructure must not know
   application types  -------------------->  type erasure
              |
              v
   some structs cannot be copied,
   so the object stays at its address
              |
              v
   where do objects come from  ----------->  pool
              |
              v
   reuse needs policy  ------------------->  hooks
              |
              v
   only then: the Matryoshka model, by name
```

## Tone reference

The 3tk README itself is the reference. What it does, in its own shape:

- It never sells. It spends its first 300 lines on the reader's problems before
  the toolkit is allowed in.
- Short lines. Plain words. ASCII pictures that carry weight.
- It earns the name last, and admits the main reason is that it is funny.
- One heading speaks to the reader: *The slot — read this one twice, at least*.
  An honest warning, not a claim that it is all simple.
- It ends on the family, and on *the next move is yours*.

---

## The measured inventory

**Read 2026-09-20 from `ztk/src/`. Re-print before trusting a line number.**

`helper.zig` 323 lines, `inner.zig` 157, `internal_tests.zig` 16,  
`matryoshka.zig` 92, `mbox.zig` 594, `pool.zig` 746, `queue.zig` 174,  
`internal/check.zig` 29, `internal/cond_timeout.zig` 71,  
`internal/stack.zig` 183. **2,385 total, comments included.**

93 example files. 19 negative programs. 202 tests, 201 passing and 1 skipping.

### One module, not six

**This is the first fact 3tk's README states that is wrong for ztk.**  
`matryoshka.zig:7` — *"This module root is the whole public surface. Nothing  
else is importable."* A user writes `@import("matryoshka")` and gets 24 names.  
There is no `ztk::inner`, no `ztk::helper`.

| what | where |
|---|---|
| `OuterId`, `Inner`, `Slot`, `AnyOuter` | `inner.zig` |
| `OuterInfo`, `infoOf` — internal, no page | `internal/info.zig` |
| `isLinked`, `isStamped`, `outerAddr`, `ofNode` | `inner.zig` |
| `Queue` | `queue.zig` |
| `OuterHelper` | `helper.zig` |
| `takeFromSlot`, `fillSlot`, `AnyOuter.moveFromSlot`, `AnyOuter.moveToSlot` | `inner.zig` |
| `Mbox`, `newMbox`, `receiveResult` | `mbox.zig` |
| `Pool`, `newPool`, `getWaitResult` | `pool.zig` |
| `VERSION` | `matryoshka.zig:86` |

### The outcome sets — there is no list of eight

**3tk declares eight faults in one place and every operation fails with one of  
them.** ztk has no such list. Zig error sets are declared per call, and two of  
them are unions with `Io.Cancelable`.

| call | error set | line |
|---|---|---|
| `Mbox.send` | `error{Closed}` | `mbox.zig:133` |
| `Mbox.sendLimited` | `error{ Closed, Limit }` | `mbox.zig:150` |
| `Mbox.sendOob` | `error{Closed}` | `mbox.zig:169` |
| `Mbox.receive` | `error{ Closed, Timeout, Wakeup } \|\| Io.Cancelable` | `mbox.zig:194` |
| `Mbox.tryReceive` | `error{Closed}` | `mbox.zig:253` |
| `Mbox.receiveAll` | `error{Closed}` | `mbox.zig:279` |
| `Mbox.wakeUpAll` | `error{Closed}` | `mbox.zig:347` |
| `Pool.GetError` | `error{ Closed, NotAvailable, NotCreated, UnknownIdentity }` | `pool.zig:89` |
| `Pool.getWait` | `error{ Closed, Timeout, UnknownIdentity } \|\| Io.Cancelable` | `pool.zig:302` |
| `Pool.put` | `error{UnknownIdentity}` | `pool.zig:374` |
| `Pool.countOf` | `error{UnknownIdentity}` | `pool.zig:517` |

**Cancellation is ztk's and not 3tk's.** `Io.Cancelable` appears in the two  
waiting calls. 3tk has no equivalent, so any sentence about the outcome set has  
to account for a failure mode 3tk's reader never meets.

**Two `Result` unions pack an outcome into one value**, for `Io.Select` and  
`Io.Group`: `Mbox.Result` at `mbox.zig:75` — `item`, `closed`, `timeout`,  
`canceled`, `wakeup` — and `Pool.Result` at `pool.zig:94` — `item`, `closed`,  
`timeout`, `canceled`, `unknown_identity`. **3tk has neither.**

### `Inner`, `Slot`, `AnyOuter` — `inner.zig`

- **`OuterInfo`** `:24` — `name` and `inner_offset`. `const`, so it lives in
  read-only memory.
- **`OuterId = *const OuterInfo`** `:33` — the id is **the address of the
  descriptor**. 3tk's is a `typeid`. This is the deepest difference between the  
  two and it touches every signature.
- **the unstamped id** — null. There is no sentinel object. What its name read
  `<unstamped>` and its offset is zero, so a missed check yields the inner's own  
  address rather than a wild pointer.
- **`Inner`** `:73` — two fields: `node: std.SinglyLinkedList.Node` and
  `id: OuterId`. 16 bytes, measured in all four modes. **An outer may go onto a  
  plain `std.SinglyLinkedList`.**
- **`Slot = ?*Inner`** `:83`.
- **`AnyOuter`** `:100` — `ptr` and `id`. The border type, for a container the
  toolkit does not own. `set` `:109` refuses a full one and an unstamped outer.

### `OuterHelper` — `helper.zig`

`const REQ = matryoshka.helper.OuterHelper(Request);` — one per outer type. `:34`.

- `ID` `:46`, `isIt` `:49`, `stamp` `:57`, `toInner` `:64`.
- `fromInner` `:72` / `mustFromInner` `:81`.
- `fromSlot` `:89` / `mustFromSlot` `:96` — read without emptying.
- `moveFromSlot` `:108` / `mustMoveFromSlot` `:123` — read and empty.
- `fromAny` `:137` — the typed read out of an `AnyOuter`.
- `isLinked` `:143`.
- **`create(allocator, io, slot)`** `:161` — allocates, runs the outer's own
  `init`, stamps, fills the Slot. **Frees the outer again if `init` fails.**
- **`destroy(allocator, io, slot)`** `:180` — runs `finish`, empties, frees.

**Both calls take `(allocator, io)`**, and so do the two methods every outer  
must declare:

```zig
pub fn init(self: *Request, alloc: std.mem.Allocator, io: std.Io) !void {}
pub fn finish(self: *Request, alloc: std.mem.Allocator, io: std.Io) void {}
```

**An empty body is the answer when there is nothing to do.** The compile errors  
that say so are at `helper.zig:203` and `:208`, and `build.zig` asserts their  
exact text in negative programs 308 and 309.

**The helper finds the inner field by type, not by name.** Zero or two is a  
compile error naming the type — `negative/compile/306` and `307`.

**Free functions, not methods:** `takeFromSlot` `:224`, `fillSlot` `:244`,  
`moveFromSlot` `:257`, `moveToSlot` `:273`. The last two are type-blind and return  
nothing.

### `Mbox` — `mbox.zig`

`Mbox` is a struct, and a user holds `*Mbox` directly. **3tk's `Mailbox` is an  
opaque typedef.** `new(alloc, io, slot)` `:541`, `destroy` `:418` — **a method,  
using the stored allocator**.

| call | line |
|---|---|
| `send` `:133`, `sendLimited` `:150`, `sendOob` `:169` | |
| `receive` `:190`, `tryReceive` `:253`, `receiveAll` `:279` | |
| `close` `:318`, `wakeUpAll` `:347` | |
| `isClosed` `:367`, `isIdle` `:380`, `len` `:390` | |
| `receiveFuture` `:437` | |

- **`close()` and `receiveAll()` hand a `Queue` back by value.** 3tk uses an
  out-parameter. MB9 ruled that returning a value is natural in Zig.
- **Two queues inside**, out-of-band first, so the order is kept by structure.
- **`destroy` aborts in every build** unless the mailbox is closed and quiet.
  `std.debug.panic`, not `check`.
- **`sendLimited` is a separate call**, where 3tk passes `limit = 0`.
- **`receiveFuture`** and **`receiveResult`** `:570` have no 3tk counterpart.

### `Pool` — `pool.zig`

`new(...)` `:673`. The identities are fixed at creation, not empty and no  
duplicates.

| call | line |
|---|---|
| `get` `:233`, `getWait` `:297`, `getWaitFuture` `:353` | |
| `put` `:374`, `close` `:457`, `destroy` `:547` | |
| `isClosed` `:487`, `isIdle` `:501`, `countOf` `:517` | |

- **`GetMode`** `:75` — `.available_or_new`, `.new_only`, `.available_only`.
  Lower case with a leading dot; 3tk's are `AVAILABLE_OR_NEW` and so on.
- **`Hooks`** `:147` — `on_get`, `on_put`, `on_close`. **No hook takes an `io`.**
  `on_get` is reached only when nothing is stored, so its Slot is always empty.  
  `on_put` takes `extra` as an out-parameter.
- **`on_close` may be called more than once, and twice at the same time** — a
  close while the put hook runs.
- **An unknown identity is `error.UnknownIdentity` in every build**, for `get`,
  `getWait`, `put` and `countOf`.
- **The store is a stack per identity**, so reuse is last in, first out.

### `Queue` — `queue.zig`

`isEmpty` `:40`, `len` `:45`, `append` `:53`, `appendFromSlot` `:72`,  
`popFirst` `:83`, `concat` `:106`, `countOfId` `:138`.

- **The tail points at itself**, so the link test is exact and sees a chain of
  one. 3tk's last link is the same; std's is null.
- **A queue only ever comes out** — from `Mbox.close`, `Mbox.receiveAll` and a
  pool's close hook. **No bulk input.**
- **A queue value is moved, never copied.**
- **No iterator.** 3tk has `iter`; ztk has `countOfId`, a walk that stops at a
  limit.

### What the toolkit does not do

No sockets. No files. No event loop. No scheduler. No fibers. No thread  
creation. No application logic.

**What it depends on:** `std.Io` — `Mutex`, `Condition`, `Future`, `Select`,  
`Group`, `Cancelable` — `std.mem.Allocator`, `std.SinglyLinkedList`.

---

## The facts to replace

**The parameter list.** Every place 3tk's README states something that is not  
true of ztk. Five classes, because the work is different in each.

- **SWAP** — one name for another. Mechanical.
- **FIND** — the answer is in `src/`; locate it and cite the line.
- **BUILD** — no counterpart exists; something has to be written first.
- **RULE** — the owner decides.
- **NUMBER** — computed by a script, never typed.

| | 3tk README says | class | ztk answer |
|---|---|---|---|
| **P-1** | "A small C3 toolkit" | SWAP | a small Zig toolkit |
| **P-2** | "800+ lines of code", "700+ lines on this page" | NUMBER | `count_src_loc.sh`, `count_readme_loc.sh`. `src/` is 2,385 lines |
| **P-3** | the five badges, `matryoshka-3tk` workflow URLs | SWAP | ztk's own. 3tk has a sanitizers workflow; ztk has linux, mac, windows, docs |
| **P-4** | ` ```c3 ` fences | SWAP | ` ```zig ` |
| **P-5** | `struct Request { ... Inner inner; }` | SWAP | Zig struct syntax, `hdr: Inner = .{}` |
| **P-6** | `fn void? Request.init(&self, Allocator a)` | SWAP | `pub fn init(self: *Request, alloc, io) !void`. **And `O-3`** — ztk takes both |
| **P-7** | `alias REQ = helper::OF{Request};` | SWAP | `const REQ = matryoshka.helper.OuterHelper(Request);` |
| **P-8** | `look`, `must_look`, `take`, `must_take` | SWAP | `fromSlot`, `mustFromSlot`, `moveFromSlot`, `mustMoveFromSlot` |
| **P-9** | `release` | SWAP | `destroy` |
| **P-10** | `Request::typeid`, "the type" | SWAP | `REQ.ID`, an `OuterId` — **the address of a descriptor**, not a language typeid |
| **P-11** | `otrtypeid`, "The inner has two fields: `link`, `otrtypeid`" | SWAP | `node` and `id`. The node is `std.SinglyLinkedList.Node` |
| **P-12** | `AVAILABLE_OR_NEW`, `NEW_ONLY`, `AVAILABLE_ONLY` | SWAP | `.available_or_new`, `.new_only`, `.available_only` |
| **P-13** | `CLOSED`, `TIMEOUT`, `WOKEN`, `LIMIT` | SWAP | `error.Closed`, `error.Timeout`, `error.Wakeup`, `error.Limit` |
| **P-14** | `wake_all`, `send_oob`, `receive_all`, `get_wait` | SWAP | `wakeUpAll`, `sendOob`, `receiveAll`, `getWait` |
| **P-15** | `mailbox::create` takes your allocator | RULE | `newMbox(alloc, io, slot)`. **`O-3`** |
| **P-16** | `close` gives back everything still queued | SWAP | true, and it **returns a `Queue` by value** rather than filling an out-parameter |
| **P-17** | `send` with a limit | SWAP | a separate call, `sendLimited` |
| **P-18** | "Six modules: `mtk`, `mtk::inner`, ..." | FIND | **one module.** `matryoshka.zig:7` |
| **P-19** | "one of eight faults declared in `mtk`" | FIND | no list of eight. Error sets are per call, and two union with `Io.Cancelable`. See the table above |
| **P-20** | "Each module's page has the details this page leaves out" | RULE | ztk's module blocks are the generated docs. **`O-5`** — whether the README links them |
| **P-21** | `UnboundedChannel(<any>)`, `to_any`, `to_slot` | SWAP | `Io.Queue(AnyOuter)`, `moveFromSlot`, `moveToSlot`, `fromAny` |
| **P-22** | step 2 names `shc::l_bridge::from_a_channel_to_a_mailbox` | BUILD | **`B-1`.** ztk has the full bridge only |
| **P-23** | step 1: chain a few in an `InnerQueue`, iterate with `iter` | BUILD | `Queue` has **no iterator**. And **`B-2`** — no step-1 example that reads as a story |
| **P-24** | "`shc` is the show cases module" | SWAP | `examples/`, 93 files, seven `examples-*` build steps |
| **P-25** | "Threads share it. It does its own locking." | SWAP | true, through `std.Io.Mutex`. The `Io` is the reader's, not the toolkit's |
| **P-26** | the family: "Zig — matryoshka-ztk. The second. Still in progress." | RULE | **`O-2`.** On ztk's own page this is a claim about itself |
| **P-27** | *nothing* — 3tk has no cancellation, no futures, no `Select` | RULE | ztk has `Io.Cancelable`, `receiveFuture`, `getWaitFuture` and two `Result` unions. **Does the README mention them at all, or are they deep-dive only?** |

**P-27 is the one that is not a translation.** Everything above it is 3tk saying  
something ztk says differently. P-27 is ztk having something 3tk does not, and  
the required order has no step for it. A round must not smuggle it in as a  
feature bullet.

---

## Sources, and their standing

**None of these is a source of truth. `ztk/src/*.zig` is.**

| source | what it is for |
|---|---|
| the 3tk README, in the `matryoshka-3tk` repository | **the base text.** Intent, order, wording, mantra |
| 3tk's own readme-creation document, version 003, in that repository's `design/` | how that README was made. The rulings, the rejected drafts, the method. **Its 34 rulings are candidates here, not decisions** |
| `kitchen/docs/addendums/why-boring.md`, frozen root | **the reader** |
| `kitchen/docs/manifesto.md`, frozen root | the I/O part / process part split |
| `3tk-to-ztk-007.md` | the rulings this tree implements, and the documentation direction |
| `ztk/README.md` | the BRIDGE stage's context. Belongs in step 2 of the finished page |
| `design/rules-050.md` Part 5 and Part 6 | the banned list and staccato |

**3tk's README names no source of its own wording**, and neither does ztk's —  
no other AI, no phrase attributed to a person.

---

## The module mapping table

**Written for the COMMENTS stage.** Filled as the README is written.

*Source* is the README passage the `//!` block is written from. *The block owes*  
is what had to be cut from the README — the detail only the generated page can  
carry.

| file | source passage | the block owes |
|---|---|---|
| `matryoshka.zig` | *Matryoshka* — the names and what each is for | one module, not six; what `VERSION` is; that the root is the whole surface |
| `inner.zig` | *The request carries its own link*; *The request carries its own type*; *One struct, two addresses* | `OuterId` as an opaque pointer with null for unstamped; the descriptor being internal; the std node and the border to `std.SinglyLinkedList`; `AnyOuter` |
| `helper.zig` | *One helper per type does the boring part*; *The one struct you write*; the `defer` sketches in *The slot* | the field found by type and not by name; `(alloc, io)` and why; the two compile errors; `takeFromSlot`/`fillSlot` as the per-item border |
| `queue.zig` | *You do not have to use everything*; *How to start*, step 1 | the tail pointing at itself; no bulk input; moved not copied; `countOfId` in place of an iterator |
| `mbox.zig` | *A queue that answers the hard questions*; *What the mailbox adds to a channel* | the outcome set per call; `sendLimited` as its own call; what `close` returns; `destroy` aborting in every build; the futures |
| `pool.zig` | *Requests come from a pool*; *The rules of reuse are yours* | `GetMode`'s three policies; the three hooks and their real signatures; `on_close` called more than once; the stack, so reuse is last in first out; the futures |

**A row's *source* stays empty until a README passage exists for it.** An empty  
source with a non-empty debt means the whole subject is block-only.

---

## 3tk's 34 rulings — candidates, not decisions

**`O-1`.** The owner rules which carry. Listed by 3tk's own numbers.

**Likely the family's**, because they are about how the page works: 1 (systems  
not features), 2 (problem before solution), 3 (no Matryoshka term before its  
problem), 4 (ASCII, no mermaid), 5 (voice), 6 (two tiers), 9 (nothing said  
twice), 10 (every claim measured), 15 (the mailbox is not the price of entry),  
20 (more humanity), 21 (staccato), 22 (the family last), 23 (no source named),  
24 (*How to start* stays), 26 (marks have one meaning), 29 (the crossing taught  
as a cast), 30 (the inner is a handle), 31 (one heading speaks to the reader),  
34 (the three pieces are independent).

**Likely C3's, or needing a ztk answer**: 7 (the deep dive is the module block —  
true here too, but the blocks are Zig `//!`), 8 (no size limit), 11–14 and 16–19  
(the opening system, the code blocks, `any` as a border), 25 (tagged unions are  
not C3 — **Zig has them**, and the bridge example uses one), 27 (the slot holds  
an inner and the page says request), 28 (`Inner` last in the struct), 32, 33  
(no link to the docs site — **`O-5`**).

**Ruling 25 is worth the owner's eye.** 3tk names the workaround *an enum tag  
plus a union* because C3 has no tagged union. Zig has them, and  
`examples/bridge/104-server_handler_and_workers.zig:61` uses one as the message  
type. The paragraph that lists the usual workarounds and their costs is  
therefore **factually different in Zig**, and it sits in *The queue should not  
know your types* — a section the required order depends on.

---

## Changelog

| version | stage | date | what changed |
|---|---|---|---|
| `001` | planning | 2026-09-20 | Created. The rulings so far, the open questions and two debts, the reader, the required order, the tone reference, the measured inventory of `ztk/src/`, the 27-row parameter list, the sources, the module mapping table, and 3tk's 34 rulings as candidates. No README text written. |
