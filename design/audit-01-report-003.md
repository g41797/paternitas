# paternitas — AUDT 01 report (003)

The audit of the outside paternitas: its build, its design against its code,
and what `paternitas-001.md` adds. Opus 5.5, 2026-10-02.

Change from 002: the owner approved Claude's advice on A1 and A11. No question
is open.

Change from 001, kept: the owner's rulings, 2026-10-02, in "The rulings"
below. A1 and A11 have a second probe and Claude's advice.

- Rules: [rules-009.md](rules-009.md).
- Plan: [implementation-plan-012.md](implementation-plan-012.md).
- Intake: [paternitas-intake-001.md](paternitas-intake-001.md).
- The outside design: `design/source/paternitas-design.md`.
- The outside code: `design/source/paternitas-and-ztk/paternitas/`.

The owner rules on each finding. The design is written after the rulings.

---

## The rulings

The owner's rulings of 2026-10-02 on 001.

| item | ruling |
|---|---|
| A1 | Not a `var` descriptor: a `var` can be changed. The owner's idea: a private tag, its pointer kept in the descriptor. Claude's advice below. Approved. |
| A2 | Yes. |
| A3 | `Link` stays `pub`. Any `N` other than the two std Nodes is a compile error. A compile negative shows it. |
| A4 | Yes. |
| A5 | Yes: the tests, and the mode-aware `fromAny` negative. |
| A6 | No. The panic text stays. |
| A7 to A10 | Yes. |
| A11 | Yes. `_type_id`, read through `Anchor.typeId()`. Claude's advice below. Approved. |
| A12 | Yes. |
| A13, A14 | Not asked. They follow the rules. |
| T1 to T3 | Yes. Into the design. |
| T4 `unstamp`, T5 `init` | Out. |
| T6 | `is` takes `*const Node`. No const recovery forms, for the same reason `AnyParent.ptr` is mutable. |
| T7 | A separate stage for the picture, the logo and the like. Not PTRN 02. |

### A1 — the private tag

The owner's idea.

- The descriptor stays a `const`.
- `Info(P)` has a private tag.
- The descriptor keeps the tag's address.
- Two descriptors then never have equal contents, so they are never merged.

The probe, in the scratch copy.

- `Info(P)` declares `var tag: u8 = 0`, not `pub`.
- `TypeInfo` gets a first field `_tag: *const u8`.
- `desc` stays `const`, with `._tag = &tag`.

| mode | `idA == idB` | `Info(A).fromAnchor` of a `B` |
|---|---|---|
| Debug | false | null |
| ReleaseSafe | false | null |
| ReleaseFast | false | null |
| ReleaseSmall | false | null |

- The 9 tests and the 7 negatives pass in all four modes.

Claude's advice: take it.

- The descriptor stays read-only. That was the cost of the `var`.
- The tag must be a `var`.
  - A `const` tag is a constant with equal contents in every `Info(P)`. The
    first probe showed such constants are merged.
  - The tag is never read or written. Only its address counts.
  - It is not `pub`. Nothing outside `Info(P)` can reach it.
- `_tag` is a field of `TypeInfo`, so it is visible in `paternitas.container`.
  - The leading `_` and its `///` say: not for use.
- The regression test of 001 stays: two modules, the same root file name, the
  same type name, two TypeIds, all four modes.

### A11 — `_type_id`

Claude's advice: rename, with an accessor.

- The leading `_` is the ztk sign for "do not touch". ztk's `Queue` has
  `_head`, `_tail`, `_count`.
- Readers still need the id.
  - ztk's `countOfId` and `Pool` buckets compare `anchor.type_id`.
  - So `Anchor` gets `pub inline fn typeId(a: *const Anchor) TypeId`.
- `stamp` stays the one writer.
- `AnyParent.ptr` and `AnyParent.type_id` keep their names.
  - A dispatch consumer reads them directly. That is what `AnyParent` is for.
- Cost: the ztk stage renames `anchor.type_id` to `anchor.typeId()`.

---

## The build

A scratch copy, outside the repo. Zig 0.16.0.

| mode | `zig build test` | `zig build negative` |
|---|---|---|
| Debug | 9/9 tests pass | 11/11 steps pass |
| ReleaseSafe | 9/9 tests pass | 11/11 steps pass |
| ReleaseFast | 9/9 tests pass | 11/11 steps pass |
| ReleaseSmall | 9/9 tests pass | 11/11 steps pass |

- All exit codes are 0.
- The negative step has 7 programs: 4 compile, 3 panic. See A2.

---

## Findings, ranked

Each finding has a proposed fix. "PTRN 01" or "PTRN 02" names the stage that
does the work.

### A1. Critical — two types can share one TypeId

The claim.

- The design: "two Parent types never share a name, so they never share a
  descriptor."

What is true.

- Zig merges constants with equal contents. A probe confirmed it.
- `@typeName` is not unique across modules.
  - Two modules, each with a root file `msg.zig` and a type `Msg`.
  - Both names are `msg.Msg`.
  - Both have the same offsets and the same Node kind.
  - So both descriptors have equal contents.

The probe.

| mode | `Info(A).typeId() == Info(B).typeId()` at run time | `Info(A).fromAnchor` of a `B` |
|---|---|---|
| Debug | false | null |
| ReleaseSafe | true | not null |
| ReleaseFast | true | not null |
| ReleaseSmall | true | not null |

- In three modes, `fromAnchor` returns a `B` as an `A`.
- This is the error paternitas exists to catch.
- The case is likely in practice.
  - Two packages, each with a root file `root.zig`, each with a type
    `Event`.

The proposed fix.

- `Info(P)` keeps its descriptor in a `var`, not a `const`.
  - A `var` is its own symbol. The linker does not merge it.
  - The probe with `var`: false in all four modes.
  - The 9 tests and the 7 negatives still pass.
- The design drops the "name keeps descriptors distinct" claim.
  - `name` stays, for panic and log text.
- A regression test, in all four modes: two modules with the same root file
  name and the same type name get two TypeIds. PTRN 01.

Cost.

- The descriptor moves from read-only data to writable data.
- The design's "one load from read-only data" becomes "one load".

### A2. High — the negative count

- The design says `zig build negative` passes 11/11.
- The 11 is build steps, not programs.
- There are 7 programs: 4 compile, 3 panic. F2 in the intake.
- Fix: the design states 7 programs, 4 and 3.

### A3. Medium — `Link(N)` accepts any `N`

- `Link` is `pub`, and takes any type.
- Its `kind` is `.double` for every `N` that is not the singly linked Node.
  - A probe: `Link(MyNode).kind` is `.double`.
- `Info` accepts only `SLink` and `DLink`. A Parent with any other Link does
  not compile.
- So a custom Link is a dead end with a wrong `kind`.
- Fix, proposed: `Link` is not `pub`. `SLink` and `DLink` stay `pub`.
- Fix, other choice: `Link` stays `pub` and is a compile error for any other
  `N`, with a compile negative.

### A4. Medium — public names the design does not list

- `Link(N).Node`, `Link(N).kind`, `Link(N).node_next_offset`.
- `Info(P).Node`.
- `nameOf` is in the design's API block, with no section of its own.
- Fix: the design lists each. PTRN 02 gives each a `///`.

### A5. Medium — test gaps

Every API entry is present and does what the design says. Some are tested
only on one path, or only through another entry.

- `mustFromAnchor`, `mustParentFromNode`: the success path is not tested.
- `is`: only the false case is tested.
- `isId`, `parentFromNodeUnchecked`: not tested directly.
- `nameOf` of a stamped Anchor: only in a panic message.
- `TypeInfo.node` with a `DLink` Parent: not tested.
- `fromAny`'s contract check: no negative.
  - A probe: a forged `AnyParent` panics in Debug, and passes in
    ReleaseFast. As designed.
- Fix, PTRN 01.
  - A test for each gap.
  - One panic negative for `fromAny` that knows the mode.
    - Debug and ReleaseSafe: it aborts and says why.
    - ReleaseFast and ReleaseSmall: it exits 0.

### A6. Low — `fromAny`'s panic text

- The text is "fromAny: the Parent was never stamped".
- It also shows when the Parent is stamped as another type.
- Fix: "fromAny: the Parent's Anchor is not stamped as this type".

### A7. Low — `fn` and `inline fn`

- The design's API block says `fn`. The code says `inline fn`. F8.
- Fix: the design says once that every API function is `inline`, except
  `nameOf`.

### A8. Low — `container.zig` is not named

- The design names `src/paternitas.zig` as the source of truth. F8.
- `src/container.zig` has `TypeInfo`, `NodeKind`, `uniform_next_offset`.
- Fix: the design names both files.

### A9. Low — one compile negative matches a compiler message

- `wrong_node.zig` expects
  "expected type '*SinglyLinkedList.Node', found '*DoublyLinkedList.Node'".
- That text belongs to Zig. A Zig release may change it.
- Fix: keep the case. Match the shorter
  "found '*DoublyLinkedList.Node'".

### A10. Low — negatives run on the host only

- The panic negatives check the abort signal and the stderr text. F9.
- Gate 3 cross-compiles the default step. It does not build `negative`.
- Fix: gate 6 runs on the host only. The design says so.

### A11. Low — fields anyone can write

- `Anchor.type_id` and the two `AnyParent` fields are `pub`. Zig has no
  private fields.
- A hand-written `type_id` or `AnyParent` passes every check that compares
  ids.
- Fix: the design and the `///` say it.
  - `type_id` is written by `stamp` only.
  - An `AnyParent` is built by `toAny` only.

### A12. Low — `uniform_next_offset` is checked on the host only

- The test pins it on the host, x86_64.
- The design's value, -8, is a 64-bit value.
- The cross targets are built, not run.
- Fix: the design says -8 is for 64-bit targets. The fallback keeps other
  targets correct.

### A13. Style — the code against rules Part 2. PTRN 01

- Imports are at the top. The rules want them at the bottom, `std` last.
- Explicit types are missing in places: `const ti = @typeInfo(P)`.
- Field access through a pointer does not use `ptr.*.field`.
- The tests are inline. F3.
  - The test helper `Chain` calls `check`, which is not `pub`. In `tests/`
    it needs its own.
- Fix: the port in PTRN 01 meets Part 2.

### A14. Docs — the outside design's language. F7

- About 50 hits of rules Part 4 words, most in the custody sense or "object"
  meaning an item.
- Prose paragraphs, not staccato.
- Fix: the new design is written in rules style.

---

## What `paternitas-001.md` adds

Intake D3: the outside design comes first. Taken only where it lacks
something.

Proposed to take.

- **T1. The motivation link.** The ziggit thread "New LinkedList API
  footgun": two structs share one list and recover the wrong Parent.
- **T2. The word "Parent".** The struct that contains the Node, as in
  `@fieldParentPtr`. Not a parent in a tree.
- **T3. What a TypeId does not prove**, three more points.
  - The Anchor was not overwritten.
  - The Node is not in two lists at once.
  - The pointer is aligned.

For the owner to rule.

- **T4. `unstamp`.** A call that resets the Anchor, for a Parent returned to
  a pool.
  - The outside design has none. `anchor(p).* = .{}` does it.
  - Proposed: not added. It is policy, and Matryoshka keeps it.
- **T5. A constructor that stamps**, `init`.
  - Proposed: not added. `stamp` after the initializer covers it, and the
    design says so.
- **T6. Const forms.**
  - `is` taking `*const Node`.
  - `fromConst` returning `?*const P`.
  - Proposed: `is` takes `*const Node`. No const recovery forms, for the same
    reason `AnyParent.ptr` is mutable.
- **T7. The mask picture**, and the logo idea: two masked Zig mascots and a
  thin thread.
  - Proposed: for the README and the site, in PTRN 02. Not in the design.

Not taken.

- The two-field layout: Node and TypeId as separate fields. The outside
  design shows why it reads outside the Parent. The Link replaces it.
- The names `from`, `tryFrom`, `fromUnchecked`. The outside names stay.

---

## After the rulings

- [paternitas-design-011.md](paternitas-design-011.md), in rules style.
  - It absorbs the outside design, with the approved fixes.
  - It keeps what design 003 records.
  - 003 moves to `backup/`.
- No code changes in this repo. The fixes are done in PTRN 01.
