# paternitas — Design (012)

This is the versioned design document. It says what paternitas is, records
the decisions and their reasons, and keeps the owner's rulings.

Change from 011: LOOK 01, 2026-10-04. The owner asked for it to run on
its own, while they were away.

- Paternitas has a logo, a mask picture and a favicon. They are in
  `kitchen/docs/assets/logo/`, with [ATTRIBUTION.md](../kitchen/docs/assets/logo/ATTRIBUTION.md).
- "Decisions of LOOK 01" has the details.

Change from 010, kept: EXPL 02, 2026-10-03. The owner's ruling.

- paternitas has two uses, and the README names them first: "One list,
  many types" and "Pass it on, handle by type".
- The second use passes an `AnyParent`, not a `*Anchor`. `AnyParent` is
  for the application. `*Anchor` is for container authors, and for a C
  callback's `void*` context.
- Examples 003, 004 and 005 carry `AnyParent`. 005 is now
  `005-large_struct_in_union`. 006 keeps `*Anchor`.
- The Archimedes quote moved from the README to the `Anchor` `///`.
- No behaviour changed.

Change from 009, kept: NAME 01, 2026-10-03.

- `Link(N)` is now `TypedNode(N)`. `SLink` and `DLink` are now
  `SinglyTypedNode` and `DoublyTypedNode`, with the short names `STNode`
  and `DTNode`.
- `stamp` is now `setTypeId`.
- The names say what each thing is. No behaviour changed.
- "Decisions of NAME 01" has the table and the reasons.
- After the close, the owner asked for `parentFromAnchor` and
  `mustParentFromAnchor`, in place of `fromAnchor` and `mustFromAnchor`.

Change from 008, kept: a PTRN 02 follow-up on the user docs, 2026-10-03.

- The prose follows rules Part 5, "Human voice". No earlier decision
  changed.
- The README, the comments and the source order are now written for the
  user. "Decisions of PTRN 02" has the rulings.

Change from 007, kept. The owner ruled on these points on 2026-10-02, as a
PTRN 02 follow-up.

- `Info(P)` becomes `Typed(P)`. `TypeInfo` and `Anchor.info()` keep their
  names.
- The examples put the types first, and each Parent has its `Typed` const.
- "Decisions of PTRN 02" gives the reasons.

Change from 006, kept. The owner ruled on PTRN 02 on 2026-10-02.

- There are six examples, in a flat layout, one file each.
- The README has no install section yet.
- `nameOf` moves into `Anchor`, as `typeName()`.
- "Decisions of PTRN 02" has the list.

Change from 005, kept. The owner ruled on PTRN 01 on 2026-10-02.

- A15: the address step is `container._nextFieldAt`, and it is `pub`.
- The version stays `0.0.1`.
- `VERSION` leaves the API. A new example replaces the placeholder example.
- SPDX headers appear in `src/` only.
- "Decisions of PTRN 01" has the list.

Change from 004, kept. On 2026-10-02 the owner ruled on ChatGPT's review of
design 004.

- A15: a test covers the fallback path of `nextField`.
- In ztk, `AnyParent` replaces `AnyOuter`, and `ParentHelper` stays. This
  version added the ztk vocabulary rule.
- "Decisions of AUDT 01" has the review.

Change from 003, kept. This change came from AUDT 01.

- The package design is here. It comes from the outside design, rewritten in
  rules style, with the fixes the owner approved.
- The audit and the rulings are in
  [audit-01-report-003.md](audit-01-report-003.md).
- The decisions of INTR 15 and ADPT 01, and what paternitas keeps from ztk,
  stay as they were.

The rest of the project state lives in other files.

- The current state is in [STATUS.md](STATUS.md).
- The narrative is in [STATUS-LOG.md](STATUS-LOG.md).
- The rules are in [rules-013.md](rules-013.md).
- The work still to do is in [implementation-plan-013.md](implementation-plan-013.md).
- A big task gets its own versioned `.md` under `design/`, linked from here.

---

## Purpose

paternitas is a small Zig package for intrusive, type-erased programming.

- It recovers the Parent of a std Node, after it checks the type.
- It lets a Parent that must not move travel through containers of pointers.
- It depends on `std` only.
- It came from the core of Matryoshka-ztk: `inner.zig`, `helper.zig` and
  `internal/info.zig`.
- ztk uses it as an outside package. A plain Zig program uses it without ztk.

The name comes from Latin.

- *Paternitas* is Latin for "fatherhood".
- A Node does not carry its Parent type. paternitas establishes which Parent
  the Node belongs to.

---

## The problem

Zig's std lists are intrusive.

- A Parent contains a std Node.
- The list sees only the Node: `*std.DoublyLinkedList.Node`.
- The Parent type is lost.

`@fieldParentPtr` recovers a Parent when the type is known.

- It does not check that the Node belongs to that Parent.
- Two structs can put their Nodes in one list. Then the wrong Parent can come
  back, and the compiler cannot see it.
- The Zig community ran into this in the ziggit thread
  [New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).

There is a second problem, with containers that store by value.

- A container that stores by value copies its elements.
- Mixed element types usually become a tagged union, copied in.
- Some items must not be copied or moved, such as an item with a mutex, a
  file handle, a pointer to itself, or a large buffer.

paternitas answers two questions.

- How does an intrusive item cross a type-erased boundary, through intrusive
  containers or through containers of pointers?
- How does the program still recognize its Parent type afterwards?

---

## Words

- **Parent** — the struct that contains the Node, as in `@fieldParentPtr`.
  It is not a parent in a tree.
- **Node** — the unmodified std Node: `std.SinglyLinkedList.Node` or
  `std.DoublyLinkedList.Node`.
- **Anchor** — one word inside every Parent, written by `setTypeId`. Its address is the
  erased reference to the Parent.
- **TypedNode** — the std Node with a type check added: a Node and an
  Anchor as one type. A Parent embeds exactly one.
- **TypeInfo** — the static description of one Parent type.
- **TypeId** — the address of a `TypeInfo`.
- **`Typed(P)`** — the typed helper for one Parent type, built at comptime.
- **AnyParent** — the dispatch view: the Parent address and its TypeId.

---

## The model

```text
Parent
 |
 +-- TypedNode  (one per Parent)
      |
      +-- node:   std Node (single or double)
      +-- anchor: Anchor { _type_id } ---> TypeInfo (static, one per type)
```

paternitas gives mechanism, not policy.

- It says where things are, and what type they belong to.
- Containers built on it decide the rest.
  - They decide who frees a Parent.
  - They decide how a Parent moves.
  - They decide how memory is allocated.
  - They decide what a chain looks like.

---

## Why the Anchor sits next to the Node

The first idea put two separate fields in the Parent: a Node and a TypeId.

- That layout is unsound for mixed containers.
- Here is an example on a 64-bit target.
  - `Message` has `text` at 0, `type_id` at 16, `node` at 24.
  - `Job` has `node` at 0, `type_id` at 16.
- Both share one `std.DoublyLinkedList`.
- A Node at address `A` lives in a `Job`.

```text
TypedMessage.parentFromNode(node)
  parent  = A - 24          // Message's Node offset
  type_id = parent + 16     // = A - 8, before the Job starts
```

- The check reads memory outside the `Job`. That is undefined behaviour.
- It usually answers "no match", so the bug stays hidden.

Comptime cannot fix it.

- Comptime knows the Node kind.
- It does not know which Parent contains this Node.
- The check must read the TypeId before the Parent type is known.

An offset in `Typed` does not help either.

- `Typed(Message)` knows where the TypeId is in a `Message`.
- For a Node in a `Job`, that address is some other field, or lies outside
  the `Job`.
- The check needs one rule for every Parent in the container: from any Node,
  the TypeId is at the same place.
- A per-Parent comptime check of the distance fails.
  - Parents use auto layout, so the compiler may reorder their fields.
  - An `extern` Parent would fix the order, but an extern struct cannot
    contain a std Node.

The TypedNode fixes it.

- The Node and the Anchor are one type, and a type's layout is chosen once.
- Every Parent embeds the same `SinglyTypedNode` or `DoublyTypedNode`.
- So the Node-to-Anchor distance is the same in every Parent, by
  construction.
- From any Node, `@fieldParentPtr("node", node)` finds the TypedNode.
- ztk's `Inner { node, id }` already followed this rule.
- The Anchor-to-`next` distance, which `nextField` uses, is fixed the same
  way.

When a container has one Parent type only, nothing is unknown. Plain
`@fieldParentPtr` is enough there. paternitas is for the mixed case.

---

## Anchor

```zig
pub const Anchor = struct {
    _type_id: TypeId = null,

    pub inline fn typeId(a: *const Anchor) TypeId;
    pub fn typeName(a: *const Anchor) []const u8;
    pub inline fn info(a: *const Anchor) ?*const container.TypeInfo;
    pub inline fn toAny(a: *Anchor) ?AnyParent;
};
```

The Anchor is one word inside every Parent, in its TypedNode.

- The Anchor is not the Parent. It is a small marker inside it.
- `*Anchor` is the erased reference to the Parent.
  - The address says where the Parent is.
  - The value `setTypeId` wrote says what it is.

The Anchor has four calls.

- `typeId()` returns the id `setTypeId` wrote. It returns null when
  `setTypeId` was never called.
- `typeName()` returns the type name, or `<no type>`. Panic and log text
  use it.
- `info()` returns the type's `TypeInfo`, or null when `setTypeId` was
  never called. Container authors use it.
- `toAny()` returns the dispatch view, without knowing the type. It returns
  null when `setTypeId` was never called.

The owner ruled on `_type_id` in AUDT 01, A11.

- The leading `_` tells the reader not to touch the field. ztk uses the same
  sign.
- `setTypeId` is the one writer.
- Readers use `typeId()`.
- Zig has no private fields, so a hand-written `_type_id` passes every id
  check. The `///` says so.

The Anchor is not `extern`, for these reasons.

- No code depends on the Anchor's layout.
- A plain struct is already a distinct type. `*Anchor` is not
  `*?*const anyopaque`.
- `extern` would add one thing: an Anchor inside a user's `extern struct`, or
  across a C ABI. If that is ever needed, it is a one-word change.

The Anchor has no chain or location calls. Those live in `TypeInfo`, which
knows the offsets.

---

## Two levels of public names

```text
paternitas              application API
paternitas.container    TypeInfo, NodeKind, uniform_next_offset
```

- Zig has no package-private visibility.
- Autodoc shows every public name reachable from the root.
- A library in another package must call `TypeInfo.nextField`, so
  `TypeInfo` cannot be internal.
- The separate namespace names its audience, and autodoc gives it its own
  page.

Each audience uses its own names.

- Application code uses `Typed(P)`, `SinglyTypedNode`, `DoublyTypedNode`,
  `*Anchor` as a value, `AnyParent` and `Anchor.toAny()`. It never touches
  `TypeInfo`.
- Container authors use `Anchor.info()` and `TypeInfo`.
- A library built on paternitas, such as ztk, wraps `Typed(P)` in its own
  helper. Its users see paternitas only through the types.

---

## TypeId and TypeInfo

```zig
pub const TypeId = ?*const anyopaque;

pub const NodeKind = enum { single, double };

pub const TypeInfo = struct {
    _tag: *const u8,
    name: []const u8,
    anchor_offset: usize,
    node_next_offset: isize,
    node_kind: NodeKind,

    pub inline fn nextField(ti: *const TypeInfo, a: *Anchor) *?*anyopaque;
    pub inline fn parent(ti: *const TypeInfo, a: *Anchor) *anyopaque;
    pub inline fn toAny(ti: *const TypeInfo, a: *Anchor) AnyParent;
    pub inline fn node(ti: *const TypeInfo, a: *Anchor, comptime N: type) *N;
};
```

- `TypeInfo` and `NodeKind` live in `paternitas.container`.
- `Typed(P)` builds one `const TypeInfo` per Parent type.
- The TypeId is its address. The address is the identity.

### The fields

- `_tag` is not for use. Its address makes this descriptor unique. See below.
- `name` is `@typeName(P)`, for panic and log text.
- `anchor_offset` is the distance from the Parent start to its Anchor.
- `node_next_offset` is the distance from the Anchor to the Node's `next`
  field. It is signed, because the Node may sit before the Anchor.
- `node_kind` is `.single` or `.double`.

### Why `_tag`

The owner ruled on this in AUDT 01, A1.

The tag fixes a fault in release builds.

- Zig merges constants with equal contents.
- `@typeName` is not unique across modules.
  - Two modules, each with a root file `msg.zig` and a type `Msg`, both give
    `msg.Msg`.
- Equal name, equal offsets and equal kind make equal descriptors.
- In ReleaseSafe, ReleaseFast and ReleaseSmall the compiler merged them.
  - The two types had one TypeId.
  - `Typed(A).fromAnchor` returned a `B` as an `A`.

The fix gives each descriptor a unique address to keep.

- `Typed(P)` declares a private `var tag: u8 = 0`.
- Its descriptor keeps `._tag = &tag`.
- Two descriptors then never have equal contents, so they are never merged.
- The descriptor stays `const`, in read-only data.
- The tag is a `var` because a `var` is its own symbol. A `const` tag would
  be the same zero byte in every `Typed(P)`, and would be merged.
- Nothing reads or writes the tag. Only its address counts.
- A test checks it in all four modes. It uses two modules with the same root
  file name and the same type name, and expects two TypeIds.

### `nextField`

- `nextField` returns the address of the Node's `next` field, for either Node
  kind.
- It gives the location only. paternitas never reads or writes this word.
- Its type is `*?*anyopaque`, not `*?*Anchor`.
  - What a container keeps in the word is its own choice.
  - A std list keeps Node pointers. ztk keeps Anchor pointers.
- paternitas does not say what null means, what a pointer to itself means,
  or who may write the word.

The shared word is part of the contract.

- The `next` word is shared.
- A std list writes it while the Parent is in that list.
- A container that chains through `nextField` does not use the Parent while
  it is in a std list. The reverse is also true.

### `parent`

- `parent` returns the Parent address, erased, through `anchor_offset`.
- It is for code that passes the raw Parent to something that knows nothing
  of paternitas, such as a C callback's `void*`.

### `toAny`

- `toAny` returns the dispatch view of the Parent behind this Anchor. See
  AnyParent.

### `node`

- `node` returns the Node, typed.
- It panics in every build mode when `N` is not this type's Node kind. A
  wrong kind would read memory as the wrong Node type.
- An `N` that is not a std Node is a compile error.

### Identity rules

A TypeId is a static type identity. It is not:

- a Parent address,
- a Node address,
- an instance identifier,
- a lifetime token,
- a list membership token.

A few more facts apply to a TypeId.

- All instances of one Parent type share one TypeId.
- paternitas has no integer type numbers, no global registry, no
  registration, and no runtime allocation.
- A TypeId is valid inside one running binary only.
  - It is not persistent, and it is not serialized.
  - Across a dynamic library or plugin boundary, two ids of one type may
    differ.
- An Anchor has `null` until `setTypeId` is called.
  - `null` matches no Parent.
  - Zeroed memory is a valid Anchor with no type.
  - An Anchor with no type has no `TypeInfo`, so it has no `nextField`. A
    container checks the type id before it touches the chain word.

---

## TypedNode

```zig
pub fn TypedNode(comptime N: type) type;   // struct { node: N = .{}, anchor: Anchor = .{} }

pub const SinglyTypedNode = TypedNode(std.SinglyLinkedList.Node);
pub const STNode = SinglyTypedNode;
pub const DoublyTypedNode = TypedNode(std.DoublyLinkedList.Node);
pub const DTNode = DoublyTypedNode;
```

- `TypedNode` is the std Node with a type check added.
- It is comptime glue. A Parent embeds `SinglyTypedNode` or
  `DoublyTypedNode` once, and never calls into it.
- `STNode` and `DTNode` are one-line aliases. They are short names, not
  other types.
- The Node inside is the unmodified std Node.
- paternitas has no list of its own.

The owner ruled on `N` in AUDT 01, A3.

- `TypedNode` is `pub`.
- `N` is `std.SinglyLinkedList.Node` or `std.DoublyLinkedList.Node`.
- Any other `N` is a compile error, and the error names `N`. `Typed` accepts
  only these two, so a TypedNode of another Node was a dead end, with a wrong
  `kind`.

A TypedNode has three public names.

- `Node` is the Node type, `N`.
- `kind` is `.single` or `.double`.
- `node_next_offset` is the distance from the Anchor to `next`.

### Field order and the uniform offset

- The fields are declared `node`, then `anchor`.
- A TypedNode cannot be `extern`, because the std Nodes use auto layout.

```text
error: extern structs cannot contain fields of type 'SinglyLinkedList.Node'
```

- The compiler may reorder the fields.
- Correctness does not depend on the order. Every offset is computed at
  comptime.
- Speed does depend on it.
  - `next` is the last word of both std Nodes.
  - With the Anchor after the Node, `next` is at the same distance from the
    Anchor in both TypedNodes.
  - On Zig 0.16.0, 64-bit targets, in all four modes, both distances are -8.

```zig
pub const uniform_next_offset: ?isize =
    if (SinglyTypedNode.node_next_offset == DoublyTypedNode.node_next_offset) SinglyTypedNode.node_next_offset else null;
```

- When the two distances are equal, `nextField` adds a constant and loads
  nothing.
- When a compiler makes them differ, `nextField` reads `ti.node_next_offset`.
  It stays correct, and costs one load more.
- A test pins `uniform_next_offset != null`. A layout change then fails a
  test, instead of slowing things down without notice.
- The test runs on the host only. Cross targets are built, not run, and the
  fallback keeps them correct. This is AUDT 01, A12.

A test covers the fallback, as AUDT 01, A15 requires.

- On every tested target the two distances are equal, so the fallback branch
  of `nextField` never runs.
- So the address step is a function that takes the offset:
  `container._nextFieldAt`.
  - `nextField` calls it with the uniform offset, or with
    `ti.node_next_offset`.
  - It is `pub`, so a test in `tests/` can reach it.
  - The leading `_` marks it as not for use. The owner ruled on this in
    PTRN 01.
- A test calls the step with `ti.node_next_offset`, for both kinds. The
  result must land on `next`.

---

## Required Parent shape

A Parent is a struct with exactly one `SinglyTypedNode` or
`DoublyTypedNode` field.

- The field can have any name and any position.
- `Typed` finds the TypedNode by its type, among the top-level fields.

```text
not a struct      -> compile error
zero TypedNodes   -> compile error
one TypedNode     -> accepted
more than one     -> compile error
```

- Each compile error names the Parent type.
- A Parent may contain other plain std Nodes for other lists.
  - paternitas ignores them.
  - Code never calls `parentFromNode` on them.

Moving existing code takes one field change per Parent.

```zig
const Message = struct {
    tnode: paternitas.DoublyTypedNode = .{},   // was: node: std.DoublyLinkedList.Node = .{},
    text: []const u8,
};
```

- `message.node` becomes `message.tnode.node`, or
  `TypedMessage.node(&message)`.
- The field is `tnode`, not `node`, so the path is not `message.node.node`.
- The std lists, their calls and their Node type stay.

A Parent is initialized before `setTypeId` is called on it.

- `allocator.create(P)` returns undefined memory.
- The TypedNode's `.{}` default applies only with an initializer.

```zig
const m = try allocator.create(Message);
m.* = .{ .text = "hello" };   // the TypedNode becomes .{}
TypedMessage.setTypeId(m);
```

- `setTypeId` does not repair a TypedNode that was never initialized.

---

## `Typed(P)`

```zig
const TypedMessage = paternitas.Typed(Message);
```

At comptime it finds the one TypedNode, builds the `TypeInfo`, and gives
typed calls for this Parent.

```text
Node                               the Node type of P's TypedNode
typeId()                      -> TypeId
isId(TypeId)                  -> bool
setTypeId(*P)                 -> void
anchor(*P)                    -> *Anchor
node(*P)                      -> *Node
is(*const Node)               -> bool
parentFromAnchor(*Anchor)     -> ?*P
mustParentFromAnchor(*Anchor) -> *P
toAny(*P)                     -> AnyParent
fromAny(AnyParent)            -> ?*P
parentFromNode(*Node)         -> ?*P
mustParentFromNode(*Node)     -> *P
parentFromNodeUnchecked(*Node)-> *P
```

- A call with another Node kind, or another Parent type, does not compile.

### `typeId`, `isId`

- `typeId()` is the address of this type's `TypeInfo`. It is the only source
  of the id.
- `isId(id)` compares a bare id with it. Code that has an id and no Parent
  uses it, such as a pool asked for "a `Message`", or a count by type.

### `setTypeId`

- `setTypeId` writes `TypeId(P)` into the Anchor. It writes nothing else.
- It does not touch the Node, so calling it on a Parent that is already in
  a list is safe.
- A Parent is initialized before `setTypeId`.
- `setTypeId` is called before the Parent's Node or Anchor crosses a
  type-erased boundary.
- There is no call that clears the type id, and no `init`, per AUDT 01, T4
  and T5.
  - `anchor(p).* = .{}` resets the Anchor. When to do it is container
    policy.
  - `setTypeId` after the initializer does the work of `init`.

### `anchor`, `node`

- They return the Anchor and the Node inside this Parent's TypedNode.

### `is`

- `is` returns true when the Node's Anchor has the type id of `P`.
- It takes `*const Node`, per AUDT 01, T6.
- The Node lives in a TypedNode. See "Container rule for Nodes".

### `parentFromAnchor`, `mustParentFromAnchor`

```text
*Anchor
   |  read the id, compare with TypeId(P)
   +-- mismatch -> null
   |  @fieldParentPtr("anchor") -> TypedNode
   |  @fieldParentPtr(TypedNode field) -> Parent
   v
*P
```

- `mustParentFromAnchor` panics on a mismatch, in every build mode.
- The panic text names the type asked for and the type found.

```text
mustParentFromAnchor: asked for app.Message, found app.Job
mustParentFromAnchor: asked for app.Message, found <no type>
```

### `toAny`, `fromAny`

- `toAny(p)` builds the dispatch view of `p`.
- `fromAny(any)` compares `any.type_id` with `TypeId(P)`.
  - On a match it returns `any.ptr` cast to `*P`.
  - On a mismatch it returns null.
  - Where runtime safety is on, it also checks that the Parent's Anchor has
    the type id of `P`.

### `parentFromNode` and its forms

```text
*Node
   |  @fieldParentPtr("node")    -- the TypedNode layout, the same in every Parent
   v
TypedNode
   |  read the Anchor's id, compare with TypeId(P)
   +-- mismatch -> null
   |  @fieldParentPtr(TypedNode field) -- the Parent layout, only after the match
   v
*P
```

- The unchecked read uses only the TypedNode layout.
- The Parent layout is used only after the type matches.
- `mustParentFromNode` panics on a mismatch, like `mustParentFromAnchor`.
- `parentFromNodeUnchecked` skips the check. The caller already knows the
  type, and the name says so.
- There are no const recovery forms, per AUDT 01, T6. The reason is the same
  as for `AnyParent.ptr`.

---

## Container rule for Nodes

- `parentFromNode`, `mustParentFromNode` and `is` read the Anchor next to the
  Node.
- Every Node in a container where they are used lives inside a paternitas
  TypedNode.
- A bare std Node in the same container makes the check undefined behaviour.

No call goes from a Node to an Anchor without a Parent type.

- Such a call would trust that any Node lives in a TypedNode, and nothing in
  its signature would say so.
- Code that has a std list knows what it put there.

```zig
const p = TypedMessage.parentFromNode(n) orelse ...;
use(TypedMessage.anchor(p));
```

---

## Containers of `*Anchor`

- Intrusive containers carry Nodes. Containers of pointers carry `*Anchor`.
- The container keeps a pointer. The Parent stays where it is.
- Copying a `*Anchor` copies a reference, not the Parent. So a Parent that
  must not move can travel through any container of pointers.
- "No Parent" is `?*Anchor`.

A `*Anchor` can be one variant among small copyable ones, or the only
element type.

```zig
const Event = union(enum) {
    tick: u64,
    resize: Size,
    parent: *paternitas.Anchor,
};

var q: Queue(*paternitas.Anchor) = ...;
```

Recovery is one call.

```zig
if (TypedMessage.parentFromAnchor(a)) |m| { ... }
```

- The check reads the Anchor word, in the Parent's memory.
- For a live Parent that costs nothing.
- For a stale reference it is undefined behaviour, as any later use would be.

### Against tagged unions

```text
                  tagged union             *Anchor
set of types      closed, fixed in union   open, any Parent with a type id
identity          enum tag in element      static address in the Parent
storage           largest variant + tag    one pointer
the Parent        copied                   stays in place
lifetime          none required            Parent outlives every reference
recovery check    exhaustive switch        runtime TypeId compare
```

- Tagged unions fit small, closed, copyable payloads.
- `*Anchor` fits Parents that must not move, open sets of types, and existing
  intrusive code.
- The two combine: `*Anchor` can be one variant of a tagged union.

---

## AnyParent: the dispatch view

```zig
pub const AnyParent = struct {
    ptr: *anyopaque,   // the Parent
    type_id: TypeId,
};
```

AnyParent is for a consumer that dispatches by type.

- The consumer keeps a map from TypeId to handler, and has no paternitas in
  its code.
- It receives a Parent and finds the handler by the id. The handler casts the
  pointer to its own type.
- `*Anchor` serves it badly, because reaching the Parent needs `TypeInfo`.
- `AnyParent` carries the Parent address.

```text
              *Anchor                       AnyParent
role          transport                     dispatch
used by       containers: chains, Slot,     the end consumer
              mailbox, pool
size          8 bytes, describes itself     16 bytes, pointer + type
type from     the Parent                    the view
Parent from   TypeInfo                      ptr
```

Dispatch needs no paternitas call in the hot path.

```zig
const Handler = *const fn (parent: *anyopaque) void;
var handlers: std.AutoHashMap(paternitas.TypeId, Handler) = ...;

// registration: the only paternitas call
try handlers.put(paternitas.Typed(Message).typeId(), onMessage);
try handlers.put(paternitas.Typed(Job).typeId(), onJob);

fn onMessage(p: *anyopaque) void {
    const m: *Message = @ptrCast(@alignCast(p));
    ...
}

// dispatch
const h = handlers.get(any.type_id) orelse return error.UnknownType;
h(any.ptr);
```

- The map does the type check.
- The handler for `Message` is registered under `Message`'s id, so its cast
  is correct by construction.
- The handler's cast is unchecked. A wrong registration gives a wrong cast,
  and nothing catches it. `Typed(P).fromAny` is the checked form.

An AnyParent comes from one of two places.

```text
mailbox --> *Anchor --a.toAny()--------> AnyParent --> handler(ptr)
typed code --> *P  --Typed(P).toAny(p)-----> AnyParent
```

- The conversion goes one way. No call turns an `AnyParent` back into an
  `*Anchor`.
  - At the dispatch site the Anchor is still at hand.
  - A typed handler uses `Typed(P).anchor(p)`.
- Only `toAny` builds one.
  - The fields are `pub`, so a hand-built one is possible. The `///` says
    not to, per AUDT 01, A11.
  - The fields keep their names, because a dispatch consumer reads them
    directly.

`ptr` is mutable, for three reasons.

- Every `AnyParent` is built from a mutable `*P` or a mutable `*Anchor`.
- A const field would force every handler to write `@constCast`.
- `toAny` never accepts `*const P`.

An `AnyParent` is a view.

- Its copies are aliases.
- The Parent outlives every copy.

---

## Between the two kinds of container

```text
std list Node --Typed(P).parentFromNode--> *P --Typed(P).anchor--> *Anchor --> queue

queue --> *Anchor --Typed(P).parentFromAnchor--> *P --Typed(P).node--> std list Node
```

Dispatch works without `P`.

```text
*Anchor --a.toAny()--------> AnyParent --> handler(ptr)
```

Erased code that does not know `P`, but knows the Node kind it wants, gets
the Node this way.

```text
*Anchor --a.info().node(N)--> *N
```

Mixed Parents can share one std list.

```zig
var list: std.DoublyLinkedList = .{};
list.append(TypedMessage.node(&message));
list.append(TypedJob.node(&job));

while (list.popFirst()) |node| {
    if (TypedMessage.parentFromNode(node)) |m| {
        processMessage(m);
        continue;
    }
    if (TypedJob.parentFromNode(node)) |j| {
        processJob(j);
        continue;
    }
}
```

- The list knows nothing of `Message` and `Job`.
- The TypedNode positions in the two Parents do not matter.
- A `SinglyTypedNode` Parent and a `DoublyTypedNode` Parent cannot share
  one std list.
  - They can share a container of `*Anchor`.
  - They can share a chain through `nextField`.

---

## Checks

paternitas has two kinds of runtime check.

Type recognition is part of the API.

- `parentFromAnchor`, `fromAny`, `parentFromNode` and `is` return null or false on
  a mismatch, in every build mode.
- The `must` forms and the kind check in `TypeInfo.node` panic in every build
  mode.

Contract checks catch misuse.

- They panic where runtime safety is on. Elsewhere they compile to nothing.
- They do not use `std.debug.assert`.
  - In ReleaseFast and ReleaseSmall, `assert` becomes `unreachable`.
  - A broken contract would then become undefined behaviour the optimizer
    may reason from.

```zig
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}
```

- The policy is the same as in ztk's `internal/check.zig`.
- `check` is internal, not `pub`.

Type safety works at two levels.

```text
compile time, through Typed(P):   the Parent type, the Node kind
run time, after erasure:         the Anchor's id   -> which Parent
                                 TypeInfo          -> where its Anchor, Node
                                                      and next are; its name
```

---

## What a TypeId does not prove

A TypeId proves type identity, not memory validity. It does not prove these
things.

- It does not prove that the Parent is alive.
- It does not prove that the pointer is valid or aligned.
- It does not prove that the Node address is intact.
- It does not prove that nothing overwrote the Anchor.
- The Parent MUST stay alive while its Node address, or any copy of its
  `*Anchor` or `AnyParent`, is in use.

paternitas knows nothing of list membership.

- It does not know whether a Node is in a list, in which one, or free.
- It does not know whether a Node is in two lists at once.
- It never reads Node contents.
  - std lists end a chain with null. ztk ends its chains with a pointer to
    the last item itself.
  - paternitas supports both, because it reads neither.

paternitas does no synchronization.

- It has no mutexes, atomics, memory ordering, thread rules, or lifetime
  synchronization.

paternitas does not decide who frees a Parent.

- `*Anchor` is a reference. Copies are aliases of one Parent.
- The application decides who frees the Parent.
- Containers that need stricter rules build them on top.
  - ztk keeps one place per item, through its `Slot`.
  - A plain user gets none of these rules, and needs none.

---

## Why one TypedNode

- A Parent may need several intrusive relationships: a ready list, a timeout
  list, a free list.
- They are different relationships. If paternitas guessed one, the API would
  be ambiguous.
- The core allows exactly one TypedNode.
- Other plain std Nodes are allowed, and paternitas does not recognize them.
- Named multi-TypedNode relationships are outside the core.

---

## Non-goals

paternitas does not provide:

- a linked list, queue, mailbox, pool, Slot, or scheduler,
- rules for who frees or moves a Parent,
- lifetime management or synchronization,
- allocation or destruction of Parents,
- general RTTI or a global registry,
- type identity for types that are not Parents,
- list state (`isLinked`, `unlink`) or chain conventions,
- Node initialization, linking, unlinking, or reading,
- a Node-to-Anchor call without a Parent type,
- an AnyParent-to-Anchor call,
- a lookup from a bare TypeId to its `TypeInfo`,
- a call that clears the type id, or `init` (AUDT 01, T4 and T5).

A few more facts follow from that.

- paternitas allocates nothing.
- A Parent can be on the stack, static, on the heap, in a pool, or inside
  another struct.
- paternitas depends only on `std`. ztk depends on paternitas, not the other
  way round.

---

## API

Every function is `inline`, except `Anchor.typeName`. This is AUDT 01, A7.

```zig
// ---- paternitas: application API

pub const TypeId = ?*const anyopaque;

pub const Anchor = struct {
    _type_id: TypeId = null,        // written by setTypeId only

    pub fn typeId(a: *const Anchor) TypeId;
    pub fn typeName(a: *const Anchor) []const u8;              // or "<no type>"
    pub fn toAny(a: *Anchor) ?AnyParent;                       // dispatch, type unknown
    pub fn info(a: *const Anchor) ?*const container.TypeInfo;  // container authors
};

pub const AnyParent = struct {     // dispatch view, one way, built by toAny only
    ptr: *anyopaque,
    type_id: TypeId,
};

pub fn TypedNode(comptime N: type) type;   // N: one of the two std Nodes
//   node: N = .{}
//   anchor: Anchor = .{}
//   Node, kind, node_next_offset
pub const SinglyTypedNode = TypedNode(std.SinglyLinkedList.Node);
pub const STNode = SinglyTypedNode;
pub const DoublyTypedNode = TypedNode(std.DoublyLinkedList.Node);
pub const DTNode = DoublyTypedNode;

pub fn Typed(comptime P: type) type;
//   Node
//   typeId() TypeId
//   isId(id: TypeId) bool
//   setTypeId(p: *P) void
//   anchor(p: *P) *Anchor
//   node(p: *P) *Node
//   is(n: *const Node) bool
//   parentFromAnchor(a: *Anchor) ?*P
//   mustParentFromAnchor(a: *Anchor) *P
//   toAny(p: *P) AnyParent
//   fromAny(any: AnyParent) ?*P
//   parentFromNode(n: *Node) ?*P
//   mustParentFromNode(n: *Node) *P
//   parentFromNodeUnchecked(n: *Node) *P

// ---- paternitas.container: for container authors

pub const NodeKind = enum { single, double };

pub const TypeInfo = struct {
    _tag: *const u8,           // not for use; makes the descriptor unique
    name: []const u8,
    anchor_offset: usize,      // Parent start -> Anchor
    node_next_offset: isize,   // Anchor -> Node.next
    node_kind: NodeKind,

    pub fn nextField(ti: *const TypeInfo, a: *Anchor) *?*anyopaque;
    pub fn parent(ti: *const TypeInfo, a: *Anchor) *anyopaque;
    pub fn toAny(ti: *const TypeInfo, a: *Anchor) AnyParent;
    pub fn node(ti: *const TypeInfo, a: *Anchor, comptime N: type) *N;
};

pub const uniform_next_offset: ?isize;

pub fn _nextFieldAt(a: *Anchor, off: isize) *?*anyopaque;  // not for use
```

---

## Implementation

The sources are two files, per AUDT 01, A8.

- `src/paternitas.zig` has the application API, `TypedNode` and `Typed`.
- `src/container.zig` has `TypeInfo`, `NodeKind` and `uniform_next_offset`.
- The two files are the source of truth for the API above.

The build has one module and four steps.

- The module is `paternitas`. The steps are `test`, `examples`, `docs` and
  `negative`.
- `build.zig.zon` keeps this repo's fingerprint and version `0.0.1`. Intake
  D9 said `0.0.0`, but the repo had `0.0.1`. The owner ruled on this in
  PTRN 01.
- `negative/` is not in the package paths. A package that depends on
  paternitas does not need it.
- The build uses Zig 0.16.0, in all four modes.

### Tests

The tests live in `tests/`, with `std.testing.log_level = .debug`.

These tests come from the outside code.

- The uniform `next` offset is the same for both TypedNodes.
- The ids are distinct. The `TypeInfo` fields and calls work.
- A `SinglyTypedNode` Parent and a `DoublyTypedNode` Parent share one
  Anchor chain. Then the `DoublyTypedNode` Parent goes into a
  `std.DoublyLinkedList`, and back.
- Parents without `setTypeId` behave as described.
- `setTypeId` on Parents that are already in a list is safe.
- Dispatch goes through a `TypeId -> handler` map, with no `Typed` call at
  dispatch.
- `toAny` and `fromAny` work.
- `*Anchor` and `AnyParent` work inside a tagged union.
- The offset stored in `TypeInfo` lands on `next` for both kinds, and so does
  `nextField`.

AUDT 01 added these tests. Each names its finding.

- Two modules with the same root file name and the same type name get two
  TypeIds. A1.
- The success path of `mustParentFromAnchor` and `mustParentFromNode` works. A5.
- `is` returns true. `isId` and `parentFromNodeUnchecked` are tested
  directly. A5.
- `Anchor.typeName` after `setTypeId` returns the name. A5.
- `TypeInfo.node` works for a `DoublyTypedNode` Parent. A5.
- `Anchor.typeId()` returns the id. A11.
- The fallback step of `nextField`, with the stored offset, lands on `next`
  for both kinds. A15.

### Negatives

A test cannot reach a compile error or check a panic, so these cases are
separate programs.

- `zig build negative` runs them. It is gate 6, in all four modes.
- They run on the host only. The panic programs check the abort signal and
  the stderr text, per AUDT 01, A10.

These programs must not compile, and must fail with the given message.

- A Parent that is not a struct.
- A Parent with a bare std Node and no TypedNode.
- A Parent with two TypedNodes.
- The std doubly Node passed where the std singly Node is expected. The
  message is Zig's, so only its tail is matched: "found '*DoublyLinkedList.Node'". A9.
- A TypedNode of a Node that is not a std Node. The message is
  "TypedNode(N): not a std Node, so it cannot be a Paternitas TypedNode",
  with `N`'s name. A3.

These programs must abort in every build mode, and say why on stderr.

- `mustParentFromAnchor` on another type names both types.
- `mustParentFromNode` on a Parent without `setTypeId` names `<no type>`.
- `TypeInfo.node` with the wrong Node kind aborts.

One program depends on the mode, per A5.

- It calls `fromAny` on a hand-built `AnyParent`, when `setTypeId` was never
  called on the Parent.
  - In Debug and ReleaseSafe it aborts, with "fromAny: setTypeId was never
    called on the Parent".
  - In ReleaseFast and ReleaseSmall it exits 0.

There are nine programs: five compile, four run.

### Examples

The examples live in `examples/`, one pattern each. See rules Part 2,
"Examples".

- The layout is flat: `NNN-name.zig`, one `pub fn` each. The owner ruled on
  this in PTRN 02.
- `examples/examples.zig` is a barrel. The site skips it.
- Each example has one test wrapper, in `tests/examples_tests.zig`.
- Each file is a page on the site, generated from its `//!` and its source.

```text
001-set_type_id_and_recover   one Parent, a std list, back
002-mixed_list                two Parent types in one std list
003-timeout_list              a DoublyTypedNode Parent in a timeout list,
                              through a std.Io.Queue(AnyParent), and back
004-handler_map               a TypeId -> handler map; toAny, fromAny
005-large_struct_in_union     AnyParent as one variant of a tagged union
006-anchor_chain              a stack chained through TypeInfo.nextField
```

---

## ztk on paternitas

The ztk stage moves ztk onto paternitas. The full plan, file by file, is the
outside design's section "Matryoshka-ztk changes", in
`design/source/paternitas-design.md`. The open questions are in the intake,
"Open for the ztk stage".

paternitas gives the mechanism, and ztk keeps the policy.

```text
paternitas                               ztk
----------                               ---
TypeId, TypeInfo, Anchor                 Slot: one place per item
SinglyTypedNode, DoublyTypedNode         chain convention: the tail points
Typed: setTypeId, anchor, node, is,        to itself; isLinked, unlink
  parentFromAnchor, parentFromNode       Queue, stack, Mbox, Pool
TypeInfo.nextField: where next is        what goes in next
contract-check policy                    create / destroy, init / finish,
                                           allocator, Io, border checks
```

These are the main changes.

- The ztk currency moves from `*Inner` to `*Anchor`.
- `Inner`, `OuterId` and `OuterInfo` leave the API.
- `AnyOuter` is removed. `AnyParent` replaces it at the dispatch edge.
- A ztk parent may carry a `DoublyTypedNode`. It can sit in the
  application's own `std.DoublyLinkedList`, and move through mailboxes and
  pools, one place at a time.

AUDT 01 changed two things.

- ztk code reads the id as `anchor.typeId()`, not `anchor.type_id`. A11.
- `ParentHelper(Parent)` stays. It wraps `Typed(P)` and adds ztk policy.
  - It has the Slot calls: `fromSlot`, `moveFromSlot`, `mustMoveFromSlot`.
  - It has `create` and `destroy`, with their hooks.
  - It has `isLinked`, and ztk's `setTypeId`.

The ztk vocabulary changes too.

- The ztk API says Parent, TypedNode, Node, Anchor, TypeId, AnyParent.
- "outer" and "inner" stay only where the Matryoshka model is explained: the
  parent is the outer doll.
- The rename is not mechanical. Each `Outer` and `Inner` is read in context.
  - Some get new names: `OuterId` -> `TypeId`, `fromInner` -> `fromAnchor`.
  - Some change meaning: `Inner` -> `Anchor` or TypedNode, `inner.next` ->
    `TypeInfo.nextField`.

---

## The central invariant

For a live Parent, after `setTypeId`:

```text
Parent
 |
 +-- TypedNode
      |
      +-- node      its contents belong to whoever links it
      +-- anchor.typeId() == TypeId(Parent) --> TypeInfo(Parent)
```

For every `*Anchor` reference to that Parent:

```text
TypeInfo.parent(anchor) == address of Parent
```

## Short version

- The Node is a std Node.
- The Node and the Anchor live together in a TypedNode.
- The TypedNode can be anywhere in the Parent.
- The Anchor is one word, written by `setTypeId`. Its address is the erased reference. It is
  the transport currency.
- AnyParent is the Parent address and its TypeId. It is the dispatch view.
- The TypeId is the address of a static, unique TypeInfo.
- `TypeInfo` says where things are. Containers decide what to do there.

```text
*Node   -- Typed(P).parentFromNode() --> checked *P
*Anchor -- Typed(P).parentFromAnchor()     --> checked *P
*Anchor -- TypeInfo.nextField()     --> where a container may chain
*Anchor -- TypeInfo.toAny()         --> AnyParent for dispatch
```

---

## Decisions of NAME 01

NAME 01 gave the names that say what each thing is. The owner ruled on
2026-10-03. The intent is in [name-01-intent-002.md](name-01-intent-002.md).

A Link was the std Node with a type check added. Its new name says so.

| old | new |
|---|---|
| `Link(N)` | `TypedNode(N)` |
| `SLink` | `SinglyTypedNode`, alias `STNode` |
| `DLink` | `DoublyTypedNode`, alias `DTNode` |
| `findLink` | `findTypedNode` |
| `stamp` | `setTypeId` |
| the field `link:` in the examples | `tnode:` |
| `<unstamped>` | `<no type>` |

- Singly and Doubly come from std. std has no `DoubleLinkedList`.
- `findTypedNode` is camelCase. Only a function that returns a type starts
  with a capital.
- `setTypeId` names the value it writes. It pairs with `typeId()`, which
  reads it.
  - `setType` would read as "change the type".
  - `stamp` needed an explanation.
- One word is used in code and in prose. "link" stays only for what std
  does: "the list links the Nodes".
- The field is `tnode`, so the path is `message.tnode.node`, not
  `message.node.node`.
- The std Node is "the std singly Node" or "the std doubly Node" in prose.
  "SNode" and "DNode" would clash with `STNode` and `DTNode`.
- No old name stays as a deprecated alias. Nothing is released yet.
- The compile errors and panics use the new words. `build.zig` checks them.
- Example 001 is now `001-set_type_id_and_recover`.
- The private names follow: `typedNodeOf`, and `TN` for the TypedNode type.
- The ztk copy in `design/source/` has the new names in its code and text.
  Its own `design/` and its generated docs keep the old ones.

After the close, the owner ruled on the Anchor, 2026-10-03.

| old | new |
|---|---|
| `fromAnchor` | `parentFromAnchor` |
| `mustFromAnchor` | `mustParentFromAnchor` |
| the negative `must_from_anchor` | `must_parent_from_anchor` |

- The name pairs with `parentFromNode`. `*Node` and `*Anchor` are both a
  pointer into your struct, and both turn back into it with a type check.
- `Anchor` keeps its name.
  - A review the owner collected called it an "embedded type-erased
    reference". "Type-erased" is wrong for paternitas: the type is kept in
    the Anchor and checked. "Reference" names a pointer, and the user
    writes `*Anchor`, so `*Ref` or `*Handle` would read as a pointer to a
    pointer.
  - `Hook` is the intrusive-container word, but in Boost.Intrusive a hook
    is the node. `AnyNode` is not a Node. `TypeTag` names only the stored
    type.
- The `Anchor` doc opens with what it is to the user: the one fixed point
  in your struct. Everything else is reached from it: the struct's type,
  the struct itself, its Node.
  - The owner's image: Archimedes, "Give me a place to stand, and I will
    move the Earth". The `Anchor` `///` quotes it, in Latin and English.
    EXPL 02 moved it there from the README.
- `*Anchor` carries the struct. `AnyParent` is for picking a handler by type
  id. The module header and the `AnyParent` doc say so.
- A queue can also carry `*Node`, when every struct in it has the same Node
  kind, and the receiver uses `parentFromNode`. `*Anchor` works for any
  struct.
- EXPL 02 changed what the user is shown. The README and the module header
  show `AnyParent` for a queue, a map or a union field. `*Anchor` is for
  container authors.
- ztk's own `ParentHelper.fromAnchor` keeps its name. Only its call into
  paternitas changed.

---

## Decisions of PTRN 02

PTRN 02 covered docs and examples. The owner ruled on 2026-10-02. The intent
is in [ptrn-02-intent-001.md](ptrn-02-intent-001.md).

- There are six examples. The set is in "Examples" above. 003 and 004 are the
  two the design described.
- The layout is flat, because there are fewer examples than in ztk.
- 003 uses `std.Io.Queue(*Anchor)` as its container of pointers. EXPL 02
  changed it to `std.Io.Queue(AnyParent)`.
- The README has no install section. It comes later.
- On the landing page only the Examples button target changed. The rest is
  LOOK 01.
- The root `//!` has a fenced usage block.
- `nameOf` became `Anchor.typeName()`. The owner ruled on this after the
  gates.
  - Autodoc shows a declaration where it is declared. A file-scope `nameOf`
    sat on the root page, away from `Anchor`.
  - The name pairs with `typeId()`.
  - The outside design had it at file scope, and gave no reason.
- An example's `//!` intro has one sentence or two per line. The site's
  hard-break fixer would otherwise break a wrapped line in the middle of a
  sentence.
- `Info(P)` became `Typed(P)`. The owner ruled on this after the stage.
  - `Info` read as the same thing as `TypeInfo` and `Anchor.info()`.
    `Anchor.info()` returns a `TypeInfo`, not an `Info(P)`.
  - A review the owner collected proposed `Helper`. The owner did not take
    it. ztk has `ParentHelper(P)` and an `XxxHelper` const per Parent, in 97
    files. A paternitas `Helper` would give a ztk user two different
    `EventHelper`s.
  - `Typed` says what the layer is: the typed side of the erased Anchor.
    `TypedMessage.fromAnchor(a)` reads the way it works.
  - `TypeInfo` and `Anchor.info()` keep their names.
  - The helper is a plain `const` next to its Parent:
    `const TypedMessage = paternitas.Typed(Message);`. It is not a
    declaration inside the Parent, because that works only for a Parent you
    write yourself.
- The owner set the examples' layout by editing 002.
  - The types come first, so the reader sees them before the code that uses
    them.
  - Each Parent has its `Typed` const on the next line.
  - Then comes the `pub fn`, then the private fns, and the imports last.
  - 001 keeps its types inside the function. It has one Parent, used only
    there.

- The owner ruled on the user docs on 2026-10-03. The README, the comments
  and the design each have their own reader. Rules Part 5, "Three kinds of
  documentation", has the rule.
  - The README starts from the ziggit footgun in code. Then it shows the
    same code with paternitas. Internals do not appear in it.
  - A `///` comment says only what a caller MUST know. Each comment stands
    alone, so a reader who lands on it from a search understands it.
  - A limitation is stated plainly. A shared library gets its own TypeId for
    the same type. The reason is in "What a TypeId does not prove".
  - The order of `src/paternitas.zig` and `src/container.zig` follows the
    user's path: `SinglyTypedNode` and `DoublyTypedNode`, then `Typed`,
    then `Anchor`, `AnyParent`, `TypeId` and `container`. Rules Part 2 has the rule.
  - Autodoc groups declarations by kind and sorts the calls of a type by
    name. The source order helps the reader of the source. On the API page,
    the root `//!` steps give the order.
  - Example steps are commands. Each example opens with the situation it
    solves.

---

## Decisions of PTRN 01

PTRN 01 was the port. The owner ruled on 2026-10-02. The intent is in
[ptrn-01-intent-001.md](ptrn-01-intent-001.md).

- A15: the address step of `nextField` is `pub`, named `_nextFieldAt`.
  - A test in `tests/` cannot reach a private function.
  - The leading `_` keeps it out of normal use. ztk uses the same sign.
  - A quoted name was tried first, and autodoc broke its link.
- The version stays `0.0.1`.
- `VERSION` leaves the API, because the design's API has no such name. The
  example `set_type_id_and_recover` replaces the placeholder example
  `print_version`. PTRN 02 keeps or rewrites it.
- SPDX headers go in `src/`. They do not go in `tests/`, `negative/` or
  `examples/`.
- `negative/` is not in the package paths.
- The rules now say that an alias of `std` goes before `std`, and `std` is
  last.

---

## Decisions of AUDT 01

AUDT 01 audited the outside paternitas. The owner ruled on 2026-10-02. Each
finding, its evidence and its ruling are in
[audit-01-report-003.md](audit-01-report-003.md).

- A1: a private `var` tag keeps its address in `TypeInfo._tag`. The
  descriptor stays `const`.
  - Zig merged equal descriptors of two types with one `@typeName`, in three
    modes.
  - The owner refused a `var` descriptor, because code can change it.
- A3: `TypedNode` stays `pub`. Any other Node is a compile error.
- A6: the `fromAny` panic stays. NAME 01 changed its words.
- A11: the field is `_type_id`, read through `Anchor.typeId()`.
- T1 to T3 from `paternitas-001.md` are in this design.
- T4, a call that clears the type id, and T5 `init` are out.
- T6: `is` takes `*const Node`. There are no const recovery forms.
- T7: the picture, the logo and the like get a stage of their own.

The same day, Claude analysed ChatGPT's review of design 004, and the owner
ruled on it.

- The review approves the design.
- The design 004 or the outside design had already decided most of its
  points: `Parent` in the ztk API, "outer" in the model only, the boundary,
  `*Anchor` as the currency, no `Inner` alias, and the `DoublyTypedNode`
  scenarios.
- The owner took three points.
  - A15: the `nextField` fallback branch had no test.
  - `AnyParent` is named as the replacement of `AnyOuter`.
  - ztk gets no mechanical rename.
- The owner did not take one point, dropping the ztk wrapper. `ParentHelper`
  carries ztk policy.
- The owner changed one point. The review put a ztk checkpoint after step 8
  of 16, and it cannot pass there, because Queue, stack, Mbox and Pool chain
  through `Inner`. The checkpoint goes after the containers.

---

## Decisions of INTR 15

INTR 15 moved the development process from next/ztk into paternitas. The
owner ruled on 2026-09-25.

### Q1 — the rules file

- The rules file is a trimmed copy of `ZTK/design/rules-050.md`.
- It keeps Part 0, adapted, and the parts on Zig style, comments and autodoc,
  banned words, and writing documents.
- It drops the Master pattern, stories, dispatch, and Matryoshka's
  invariants.
- It adds the git rules.
  - `git status` is the only git command a session runs.
  - A plain `mv` replaces `git mv`.
- It links back to the source rules, with a note that their version may have
  moved on.
- The process rules carry over. The Matryoshka-specific rules describe a
  toolkit paternitas is not.

### Q2 — the layout

- The layout has the same shape as next/ztk.
  - It has `build.zig`, `build.zig.zon`, and the module `paternitas`.
  - `src/`, `tests/` and `examples/` each start with a placeholder file.
  - `kitchen/` has the gate scripts, the site tools and the site sources.
  - `design/` has the documents.
- At first there is no `negative/` and no gate 6.
  - They wait for the first stage where paternitas refuses something,
    because a gate with no cases proves nothing.
  - That stage is PTRN 01. See "Negatives" above.

### Q3 — ztk knowledge

- paternitas keeps paths into the ztk sources, and never copies them.
- It keeps ztk's smell, process, mantra and intent. See the section below.
- A copy rots, while a path points at the current text.

### Q4 — process audit

The audit has two passes.

- INTR 15 does a quick pass before the first rules file is written. It fixes
  what is clearly wrong or outdated. The findings are in `STATUS-LOG.md`,
  under INTR 15.
- ADPT 01 goes deeper and tunes the workflow.

### Q5 — the site

- The site has the same structure as next/ztk: an mkdocs landing page, plus
  `zig build docs` for the API docs.
- The content starts as a placeholder.
  - The title is "paternitas".
  - It has one line from the owner's text. The owner ruled on 2026-09-25
    that the line is "Paternitas". It replaced a proposed sentence from
    `paternitas-001.md`.
  - A badge links to `apidocs/`.
  - There is no logo yet. AUDT 01, T7 gives it a stage of its own.
- The API docs are generated from the sources.

### Q6 — CI

- Every `.github` workflow of matryoshka-ztk is copied: linux, mac, windows,
  and docs (GitHub Pages).
- Each is adapted to paternitas' names and paths.
- The gates pass locally before the owner pushes, so CI starts green.

### The first sources are placeholders

- They exist to check that the scripts, the build, the tests and the doc
  generation work.
- They implement nothing. PTRN 01 replaces them.

### Kitchen tools changed on the way in

- `gen_examples_docs.sh` regenerates the whole of `kitchen/docs/examples/`.
  next/ztk listed its own example groups by name, and mirrored `stories/`.
  paternitas has neither.
- `fix_md_hardbreaks.sh` fixes `kitchen/docs/` only, not every `.md` in the
  repo. `paternitas-001.md` stays untouched, and nobody edits
  `STATUS-LOG.md`, so a site build must not rewrite either.
- `fix_md_hardbreaks.sh` and `fix_md_lists.sh` skip a page's leading front
  matter block. In next/ztk they rewrote the landing page's front matter. The
  `---` line got trailing spaces, and a blank line appeared inside the
  `hide:` list.
- `check_next_docs.sh` became `check_docs.sh`.
  - It still checks dead references and banned words.
  - It no longer checks the retired-word list, or the plan version against
    the log.

---

## Decisions of ADPT 01

ADPT 01 tuned the workflow before any real code. The owner ruled on
2026-09-25. The process rulings are in the rules file. The list is in
[backup/adpt-01-intent-002.md](backup/adpt-01-intent-002.md).

### The gates

- `kitchen/gates.sh` runs the five gates, with fixed log names. The gates
  cost round trips, and the log names used to change per stage.
- `check_docs.sh` enforces every entry of the banned list: the words, their
  other forms, and the phrases.
  - `grep -w` matches whole words only, so a banned word with an `-ed` ending
    passed the gate.
  - The words whose meaning decides stay a hand scan.
- The test wrappers keep `std.testing.log_level = .debug`.
  - The owner wants all four levels in the test output.
  - Zig 0.16 prints it under a `failed command:` line. The owner accepted
    that cost.

### The site

- The favicon stays ztk's until paternitas has a logo.
  - The reason is the same as for the placeholder sources: there is nothing
    to show yet.
  - The duplicate `kitchen/docs/favicon.ico` was deleted, with the owner's
    approval.
- The landing page hides the navigation. An "Examples" button sits beside the
  lines-of-code badge. The nav entry stays, for every other page.
- `fix_md_hardbreaks.sh` skips raw HTML. It used to add trailing spaces
  inside the landing page's `<style>` block and hero `<div>`, where they
  meant nothing.

---

## What paternitas keeps from ztk

paternitas keeps paths only. The ztk repo root is
`/home/g41797/dev/root/github.com/g41797/matryoshka-ztk`, written `ZTK` below.
`NEXT` is `ZTK/design/secondary/lang/port/3tk-to-ztk/next`.

A path here may go stale when ztk moves a file. When it does, fix the path in a
new version of this document.

### Smell — how the code looks

- The rewritten toolkit is in `NEXT/ztk/src/`.
  - The module root is `NEXT/ztk/src/matryoshka.zig`.
  - Code hidden from the docs is in `NEXT/ztk/src/internal/`.
- The tests and examples are in `NEXT/ztk/tests/` and `NEXT/ztk/examples/`.
- What the toolkit refuses is in `NEXT/ztk/negative/`, and its `README.md`.
- The build is `NEXT/ztk/build.zig`.

### Process — how the work is done

- The full rules are in `ZTK/design/rules-050.md`.
- The state file of the new tree is `NEXT/next-status.md`. Its **Rules** and
  **The gates** sections are the source of Part 0 and Part 1 of the rules
  file.
- The narrative of the new tree is `NEXT/next-log.md`.
- The stage menu is `NEXT/next-staging-plan-NNN.md`, the highest number.
- The old tree's state and narrative are `ZTK/design/STATUS.md` and
  `ZTK/design/STATUS-LOG.md`.
- The gate scripts and site tools are in `NEXT/ztk/kitchen/`.
- CI is in `ZTK/.github/workflows/`.

### Mantra — what ztk keeps to

- An item sits in exactly one place, in exactly one state, at any moment.
  See `ZTK/design/rules-050.md`, Part 4, **Exclusive access, in comments**.
- The work is observable by a human: a coordinator plus named steps. See
  `ZTK/design/rules-050.md`, Part 1.
- Text is Staccato, everywhere it is written. See
  `ZTK/design/rules-050.md`, Part 6.

### Intent — why ztk is shaped the way it is

- The backport rulings are in `ZTK/design/secondary/lang/port/3tk-to-ztk/3tk-to-ztk-007.md`.
  - See section **BKP 2 — the rulings**.
  - See section **The direction change**.
  - See section **The documentation direction**.
- The old tree's design folder is `ZTK/design/`.
  - The index is `ZTK/design/context.md`.
  - The concepts are in `ZTK/design/matryoshka-concepts-003.md`.

---

## Decisions of EXPL 02

The owner ruled on 2026-10-03.

- paternitas has two uses. The README names them first, in plain English.
  - One list, many types: several struct types share one std list.
    `parentFromNode`.
  - Pass it on, handle by type: the struct goes through a queue, a map or a
    union field as an `AnyParent`. The receiver calls `fromAny`, or picks a
    handler by `type_id`.
- `AnyParent` is two words, and it is a plain value. A non-intrusive
  container copies the two words and never the struct.
- The README section "Beyond the std list" is gone. Its `*Node` / `*Anchor`
  choice is advanced material for container authors, so it lives in the
  comments now.
- The `Anchor` `///` says it is for container authors, and for a C
  callback's single `void*` context. It quotes Archimedes.
- Examples 003, 004 and 005 carry `AnyParent`. The README's snippets are
  taken from them. 005 was renamed, because its name said Anchor.
- 004 no longer logs the type name of an unhandled item. An `AnyParent` has
  no `typeName()`.

## Decisions of LOOK 01

The owner asked for LOOK 01a and LOOK 01b to run without them, on
2026-10-04. Claude made the small choices below. The owner can undo any of
them.

The images.

- The logo shows Zero and Ziggy, the two official Zig mascots.
  - Both come from Wikimedia Commons, under CC BY 4.0.
  - Zero is by Andrew Kelley. Ziggy is by Luke Holder.
  - The mascots are not redrawn. Each holds up a blue mask on a stick, in
    front of its eye. A thin orange thread joins the two sticks.
  - The mask is held, not worn, because the Node is not the struct. The
    struct carries its Node, the way a guest at a masquerade carries a
    stick mask.
  - The two masks are the same. Every struct in a list carries the same
    kind of Node.
  - The owner asked for the stick masks on 2026-10-05. The first version
    had masks tied on, and a thick thread from mask to mask that read as a
    hose.
- The mask picture shows three structs on one list: Message, Job, Message.
  - The list sees three equal masks. A thread joins their sticks.
  - Paternitas sees the type behind each one.
- The favicon is the mask and its stick, seen from the front, on Zig
  orange.
  - A mascot at 16 pixels cannot be read. The mask can.
- The new images are under CC BY 4.0, like their sources.
- `kitchen/tools/gen_logo.py` draws all of them from the two unchanged
  copies of the mascots. The SVGs carry a width and a height. Without them
  the landing page shrank the logo to nothing.

Where they go.

- The README shows the logo under its title.
- A new README section, "The mask", sits after "The problem in one
  example". It has six short lines and the picture.
  - The picture says what the text says. It does not replace the code.
  - There is no ASCII copy of it. The README has an ASCII layout diagram
    already, in "Why intrusive lists at all?".
- The README credits the two authors and links [ATTRIBUTION.md](../kitchen/docs/assets/logo/ATTRIBUTION.md).
- The landing page shows the logo above the name. The logo links to the
  README on GitHub.
  - In dark mode the logo sits on a light card, because the mascots have
    dark outlines.
- The site's header logo and favicon are the new mask.
- The old ztk favicon, `kitchen/docs/assets/images/favicon.ico`, is no
  longer used. It is not deleted. The owner deletes it.

The Archimedes quote stays in the `Anchor` `///`.

- EXPL 02 put it there. LOOK 01 does not move it.
- An Anchor picture, a lever or an anchor, was not drawn. The README's
  Anchor text is for container authors, and most readers stop before it.

A bug on the landing page was fixed on the way.

- Its hidden `<h1>` showed, because the hiding rule used `:first-child`
  and a `<style>` element came first. The rule now uses `:first-of-type`.
