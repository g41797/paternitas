# paternitas — AUDT 01 report (001)

The audit of the outside paternitas: its build, its design against its code,
and what `paternitas-001.md` adds. Opus 5.5, 2026-10-02.

- Rules: [rules-004.md](rules-004.md).
- Plan: [implementation-plan-005.md](implementation-plan-005.md).
- Intake: [paternitas-intake-001.md](paternitas-intake-001.md).
- The outside design: `design/source/paternitas-design.md`.
- The outside code: `design/source/paternitas-and-ztk/paternitas/`.

The owner rules on each finding. The rulings go in the next version of this
report. The design is written after them.

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

## Questions for the owner

1. A1: the descriptor as a `var`, and the regression test. Approve?
2. A3: `Link` not `pub`, or `Link` `pub` with a compile error?
3. A5: the tests, and the mode-aware `fromAny` negative. Approve?
4. A2, A4, A6 to A12: the fixes as proposed. Approve as a group, or name the
   ones to change.
5. T1 to T3: take into the design?
6. T4 `unstamp`, T5 `init`: not added?
7. T6: `is` takes `*const Node`, no const recovery forms?
8. T7: the mask picture for README and site, in PTRN 02?

---

## After the rulings

- The next version of this report, with the rulings. 001 moves to
  `backup/`.
- The next version of the design, `paternitas-design-NNN.md`, in rules style.
  - It absorbs the outside design, with the approved fixes.
  - It keeps what design 003 records.
  - 003 moves to `backup/`.
- No code changes in this repo. The fixes are done in PTRN 01.
