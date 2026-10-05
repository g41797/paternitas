# Type ids on their own — proposal (002)

A proposal. Not approved for code. Nothing in it is built.

- Date: 2026-10-05.
- From: the owner's idea, written up by Claude.
- Change from 001:
  - the owner's review, and the talk after it;
  - the owner's idea: `Typed(P)` for every struct;
  - a scratch test of that idea, in all four build modes.
- Next: the plan gets stages. Then the owner names the first one.

## The idea in one line

Paternitas has two uses. Make both open to you.

1. **Type ids.** A runtime id for a struct type. Zig has none.
2. **Intrusive, type-erased containers.** What Paternitas does today: the
   type id next to the Node, and the safe way back to the Parent.

Use 2 is built on use 1.

## Why

Zig's `type` exists only at compile time. At run time a value of unknown
type is only an address.

You have an address. You need to know whose it is.

People who need a runtime type id today write it by hand.

- A `var` per type, and its address as the id.
- Or `@typeName` and a string compare.
- Or an enum they keep in sync with every type by hand.

Paternitas already has the right trick. A1 showed how easy it is to get
it wrong: two types shared one id in release modes. The fix is in
Paternitas now.

Today you get that trick only with a TypedNode in your struct. Use 1
needs no Node:

- a handler map keyed by type, without lists;
- a pointer plus its type, passed through code that does not know the
  type: callbacks, queues, `void*` contexts.

## Where it came from

- Odin, matryoshka-otk: `PolyTag`, the address of a static per-type
  `{ _: u8 }`. The first version, made by hand.
- Zig, ztk: the same idea, by hand again. Paternitas came out of it.

## The same idea elsewhere

- C3 has it in the language:
  [typeid](https://c3-lang.org/language-overview/types/#the-typeid-type)
  and [any](https://c3-lang.org/language-overview/types/#the-any-type).
  - C3's `any` is a pointer and a `typeid`. The same pair as Paternitas's
    `Any`.
  - The match was found later. C3 is not where the idea came from.
- C3's `typeid` covers every type. Paternitas covers structs only. On
  purpose.
- Zig may add its own one day. Then use 1 can step back to Zig's. The
  lists stay.

## How it is today

- `Typed(P)` needs a `TypedNode` field in `P`. Without one it does not
  compile.
- You get a `TypeId` only from `Typed(P).typeId()`.
- The `TypeId` is the address of `P`'s `TypeInfo`.
  - `TypeInfo` holds the name and the Node offsets.
  - `Anchor.info()` turns the id back into the `TypeInfo`.
- `AnyParent` is `{ ptr, type_id }`. `Typed(P).toAny` makes one.
  `Typed(P).fromAny` takes it back.

So a struct without a `TypedNode` has no id.

## The proposal

### `Typed(P)` for every struct

Use 1 already exists. It is locked behind the TypedNode check.

| use 1 needs | it is already |
|---|---|
| a type id | `Typed(P).typeId()` |
| a pointer and its id | `Typed(P).toAny(&p)` |
| the value back, with a check | `Typed(P).fromAny(any)` |

So the change is small.

1. `Typed(P)` accepts every struct.
   - `P` has one TypedNode: every call, as today.
   - `P` has none: `typeId`, `isId`, `toAny`, `fromAny`. Nothing else.
2. `AnyParent` becomes `Any`. No alias: there is no release yet
   (`0.0.1`).

```zig
const Point = struct { x: i32, y: i32 };   // no TypedNode
const TypedPoint = paternitas.Typed(Point);

var pt: Point = .{ .x = 1, .y = 2 };
const any = TypedPoint.toAny(&pt);         // { ptr, type_id }

if (TypedPoint.fromAny(any)) |p| { ... }   // null for another type
map.get(any.type_id);                      // a handler map, no list
```

- Structs only. Not ints, not pointers, not unions, not `opaque`.
  - Wrap a value in a struct to give it an id.
  - Wider later breaks nothing. Narrower later would.
- No allocation. No registry. No init call. No build flag.
- The same rules as today:
  - one running program only;
  - a shared library has its own ids;
  - do not save or send an id.

### Where the id lives

- With a TypedNode, the id lives inside the struct. One word carries it:
  `*Node` or `*Anchor`.
- Without one, the struct has no room for it. The id rides beside the
  pointer, in an `Any`. Two words.
- A bare pointer to a struct without a TypedNode cannot be recognized.

### The id

- `TypeId` stays `?*const anyopaque`. A `void*`, as today.
- With a TypedNode: the address of `P`'s `TypeInfo`, as today.
- Without one: the address of a per-type `var tag: u8`. No record behind
  it, no name.
- Only `Anchor.info()` reads through an id. An Anchor exists only in a
  struct with a TypedNode. So no code reads through the other kind.
- The list path does not change. No extra load.

### No type name on `Any`

- The `TypeId` is the identity: unique, a map key.
- A name is a label for people. Two types can print alike.
- A `typeName` on `Any` invites a compare by name. Two "ids".
- The name stays where Paternitas needs it: in `TypeInfo`, for panics.
  `Anchor.typeName` stays.
- Want names in your handler map? Store them next to the handler.

### Compile errors stay sharp

| you write | you get |
|---|---|
| `Typed(u32)` | `u32: not a struct, so it cannot be a Paternitas Parent` |
| two TypedNodes in `P` | `P: more than one TypedNode, and exactly one is allowed` |
| a list call, `P` has no TypedNode | `P: no TypedNode, so it has only typeId, toAny and fromAny` |

The last row matters most. A struct with a plain std Node, not a
TypedNode, gets only the id calls. The first list call says why.

### `fromAny`

- `P` has a TypedNode: it also checks that `setTypeId` was called, when
  runtime safety is on. As today.
- `P` has none: it checks the id in the `Any`. Nothing else to check.

## The scratch test

A small copy of `Typed(P)` with this design. Not in the repo.

- Debug, ReleaseSafe, ReleaseFast, ReleaseSmall: all pass.
- 8 ids, read at run time, so the compiler cannot fold the compare. No
  duplicates in any mode:
  - two structs with the same fields;
  - two empty structs;
  - `List(u8)` and `List(u16)`;
  - two structs with a TypedNode.
- No TypedNode: `toAny` then `fromAny` gives the value back. Another type
  gives null.
- With a TypedNode: the list calls and `Any` share one id. `fromAny` still
  checks `setTypeId`. `Anchor.info().name` works.
- The three compile errors above, word for word.

## What does not change

- Every list call. Every Anchor call. `container.TypeInfo`.
- The six examples, except the rename `AnyParent` to `Any`.
- The A1 trick: a `var` per type, never a `const`.
- Zero cost for a list user.

## What changes for the reader

- Code: `AnyParent` becomes `Any` in `src/`, the tests and examples 003
  to 006.
- The `///` of `Typed` and `TypeId`: every struct, not only Parents.
- The README is not touched in this change. A separate stage, later.
- One new example for use 1, in a later stage: a handler map without a
  list.

## Risks

- **Scope.** Paternitas grows from one job to two. Kept small: no new
  call, one rename.
- **Ids that merge.** The A1 bug again, now for structs without a Node.
  Tests in all four build modes guard it.
- **Generic types.** `List(u8)` and `List(u16)` get two ids. Tests.
- **A plain std Node by mistake.** The struct gets only the id calls. The
  first list call fails to compile, with the reason.
- **Name.** "Paternitas" is about the parent. Use 1 has no parent. The
  name still fits: the id says whose the value is. The motto, *agnitio*,
  is recognition.

## Ruled by the owner

1. `Any` replaces `AnyParent`. No alias.
2. Structs only.
3. `Typed(P)` for every struct. List calls only with a TypedNode.
4. `TypeId` stays `?*const anyopaque`.
5. No `typeName` on `Any`.
6. The README is a separate stage, later.

Gone from 001, no longer needed:

- `paternitas.typeId(T)`, `typeName(id)`, `Any.of`, `as`, `mustAs`.
- Way A or way B: only `Typed(P)` makes ids, so there is nothing to join.
- `src/typeid.zig`: the change is too small for its own file.
- Zero-sized types as a risk: the id is never the address of a value.

## Open for the owner

1. TYID before ZTK? Claude and the review say yes: ztk wants ids for
   dispatch that is not always on a list.

## Stages, a first cut

For the plan. Names are proposals.

1. **TYID 01, code.** `Typed(P)` for every struct, the compile errors,
   `AnyParent` to `Any`. Tests in all four modes. Doc comments.
2. **TYID 02, example.** One example: a handler map without a list.
3. **README.** A separate stage, named by the owner, later.

001 had an intent stage. This proposal now holds the rulings, so no
intent doc is needed. The owner decides.
