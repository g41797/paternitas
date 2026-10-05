# Type ids on their own — proposal (001)

A proposal. Not approved. Nothing in it is built.

- Date: 2026-10-05.
- From: the owner's idea, written up by Claude.
- Next: the owner reads it and rules. Then the plan gets stages. Then the
  owner names the first one.

## The idea in one line

Paternitas has two uses, and the code joins them. Make them two.

1. **Type ids.** A runtime id for any(???) Zig type. Zig has none. C3 has
   `typeid`. Odin has `typeid`.
2. **Intrusive, type-erased containers.** What Paternitas does today: the
   type id next to the Node, and the safe way back to the Parent.

Use 2 is built on use 1. Use 1 needs nothing from use 2.

## Why

Zig's `type` exists only at compile time. At run time a value of unknown
type is only an address.

People who want a runtime type id today write it by hand.

- A `var` per type, and its address as the id.
- Or `@typeName` and a string compare.
- Or an enum they keep in sync with every type by hand.

Paternitas already has the right trick. A1 showed how easy it is to get
it wrong: two types shared one id in release modes. The fix is in
Paternitas now.

So use 1 is worth having on its own.

- A handler map keyed by type, without lists.
- A pointer plus its type, passed through code that does not know the
  type: callbacks, queues, `void*` contexts.
- Logs that name the type of a value of unknown type.

## Where it came from

- Odin, matryoshka-otk: `PolyTag`, the address of a static per-type
  `{ _: u8 }`. The type id idea.
- C3, matryoshka-3tk: the language's own `typeid`. The id is built in.
  - [typeid](https://c3-lang.org/language-overview/types/#the-typeid-type)
  - [any](https://c3-lang.org/language-overview/types/#the-any-type)
- Zig, ztk: the id made again by hand. Paternitas came out of it.

Use 1 gives Zig what C3 and Odin have built in.

## How it is today

- You get a `TypeId` only from `Typed(P).typeId()`.
- `Typed(P)` needs a `TypedNode` field in `P`. Without one it does not
  compile.
- The `TypeId` is the address of `P`'s `TypeInfo`.
  - `TypeInfo` holds the name and the Node offsets.
  - `Anchor.info()` turns the id back into the `TypeInfo`.
- `AnyParent` is `{ ptr, type_id }`. Only `Typed(P).toAny` makes one.

So the id and the list are one thing in the code. A type without a
`TypedNode` has no id.

## The proposal

### Use 1: type ids

```zig
const paternitas = @import("paternitas");

const id = paternitas.typeId(Message);   // any type, at run time
paternitas.typeName(id);                 // "app.Message"

var m: Message = .{};
const any = paternitas.Any.of(&m);       // { ptr, type_id }

if (any.as(Message)) |msg| { ... }       // null for another type
const job = any.mustAs(Job);             // panics, names both types
```

- `typeId(T)`: works for any `T` that exists at run time. Structs, enums,
  unions, ints, pointers.
  - Not for `comptime_int`, `type`, and other compile-time-only types.
    Those do not compile.
- `typeName(id)`: the name, for logs and panics.
- `Any`: an address and its type id. `as(T)` and `mustAs(T)` give the
  value back, with a type check.
- No allocation. No registry. No init call.
- The same rules as today:
  - one running program only;
  - a shared library has its own ids;
  - do not save or send an id.

### Use 2: containers

- `TypedNode`, `Typed(P)`, `setTypeId`, `parentFromNode`, `Anchor`,
  `container` stay as they are.
- They are built on use 1.
- One rule ties them together:

```zig
Typed(P).typeId() == paternitas.typeId(P)
```

So one handler map serves both uses. A `Message` found on a list and a
`Message` passed as an `Any` have the same key.

- `AnyParent` becomes `Any`, or stays as another name for it. Open
  question 2.

## How the two ids become one

Today the id is the address of the `TypeInfo`. Use 1 has no `TypeInfo`:
a type without a Node has no Node offsets. Two ways.

**A. The id stays the `TypeInfo` address, when there is one.**

- `typeId(T)` looks at `T` at compile time.
  - `T` has a `TypedNode`: the id is the address of `Typed(T)`'s
    `TypeInfo`, as today.
  - `T` has none: the id is the address of a small per-type record with
    the name.
- `Anchor.info()` does not change. No extra load.
- The cost: two kinds of record behind one id. `typeName(id)` must read
  both. The name goes first in both, at the same place.

**B. The id is always the small record. `TypeInfo` points to it.**

- `typeId(T)` is always the small record.
- `Anchor` keeps the `*TypeInfo`. `Anchor.typeId()` reads
  `info.type_id`.
- Simpler to explain. One kind of id.
- The cost: one more load on every type check from a Node. And the
  `Anchor` field changes meaning: it holds the `TypeInfo`, not the id.

Claude leans to A: no cost on the list path, which is the main path
today. B is cleaner. The owner rules. Open question 1.

## What does not change

- Every call in the README works as before.
- The six examples work as before.
- The A1 trick stays: a `var` per type, never a `const`. A `const` can
  share an address with another type's in release modes.
- Zero cost for a list user who never calls `typeId(T)` directly.

## What changes for the reader

- The README names two uses first. Type ids first, short. Then lists,
  as now.
- One or two new examples for use 1. For instance:
  - a handler map keyed by `typeId`, for values that are not on a list;
  - an `Any` through a C callback's `void*` context.
- The `//!` at the top of `src/paternitas.zig` names both uses.
- The logo can stay. The diamond is the type id. The belt is use 2.
  - The subtitle could name both, for instance:
    "RUNTIME TYPE IDS FOR ZIG · SAFE INTRUSIVE CONTAINERS".

## Risks

- **Scope.** Paternitas grows from one job to two. The README must stay
  short.
- **Ids that merge.** The A1 bug again, now for any type. Tests in all
  four build modes, with many types, guard it.
- **Generic types.** `List(u8)` and `List(u16)` must get two ids. Tests.
- **Zero-sized types.** They must still get their own id. The `u8` in
  the record does it. Tests.
- **Name.** "Paternitas" is about the parent. Use 1 has no parent. The
  name still fits: the type id says whose the value is. The motto,
  *agnitio*, is recognition.

## Open questions for the owner

1. Way A or way B for the id?
2. `Any` replaces `AnyParent`, or both names stay?
3. Should `Any` hold a `*const` too, or only `*` like `AnyParent`?
4. Does `typeName` take an id, or should the id be a small struct with a
   `.name()`? A struct is nicer to read. A bare pointer is what the map
   key is today.
5. Does use 1 go in its own file, `src/typeid.zig`, re-exported from the
   root?
6. ZTK is the next stage in the plan. Does this come first?

## Stages, a first cut

For the plan, after the owner rules. Names are proposals.

1. **TYID 01, intent.** The owner's rulings on the questions above. An
   intent doc. No code.
2. **TYID 02, code.** Use 1 in `src/`, use 2 on top of it. Tests in all
   four modes. The rule `Typed(P).typeId() == typeId(P)` as a test.
3. **TYID 03, words.** The README, the `//!`, new examples, the site.
   Maybe the logo subtitle.
