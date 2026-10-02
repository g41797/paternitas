# paternitas — Design (008)

The versioned design document: what paternitas is, the decisions, their
reasons, and the owner's rulings.

Change from 007: a PTRN 02 follow-up. Owner's rulings, 2026-10-02.

- `Info(P)` becomes `Typed(P)`. `TypeInfo` and `Anchor.info()` keep their
  names.
- The examples put the types first, each Parent with its `Typed` const.
- "Decisions of PTRN 02" has the reasons.

Change from 006, kept: PTRN 02. Owner's rulings, 2026-10-02.

- The examples: six, flat, one file each.
- The README has no install section yet.
- `nameOf` moves into `Anchor`, as `typeName()`.
- "Decisions of PTRN 02" has the list.

Change from 005, kept: PTRN 01. Owner's rulings, 2026-10-02.

- A15: the address step is `container._nextFieldAt`, `pub`.
- The version stays `0.0.1`.
- `VERSION` leaves the API. The placeholder example is replaced.
- SPDX headers in `src/` only.
- "Decisions of PTRN 01" has the list.

Change from 004, kept: the owner's rulings of 2026-10-02 on ChatGPT's review
of design 004.

- A15: the fallback path of `nextField` is tested.
- ztk: `AnyParent` replaces `AnyOuter`. `ParentHelper` stays. The ztk
  vocabulary rule.
- "Decisions of AUDT 01" has the review.

Change from 003, kept: AUDT 01.

- The package design is here. It comes from the outside design, rewritten in
  rules style, with the fixes the owner approved.
- The audit and the rulings: [audit-01-report-003.md](audit-01-report-003.md).
- The decisions of INTR 15 and ADPT 01, and what paternitas keeps from ztk,
  are kept as they were.

Where the rest lives.

- Current state: [STATUS.md](STATUS.md).
- The narrative: [STATUS-LOG.md](STATUS-LOG.md).
- The rules: [rules-005.md](rules-005.md).
- The work still to do: [implementation-plan-009.md](implementation-plan-009.md).
- A big task gets its own versioned `.md` under `design/`, linked from here.

---

## Purpose

paternitas is a small Zig package for intrusive, type-erased programming.

- It recovers the Parent of a std Node, after a check of its type.
- It lets a Parent that must not move travel through containers of pointers.
- It depends on `std` only.
- It came from the core of Matryoshka-ztk: `inner.zig`, `helper.zig`,
  `internal/info.zig`.
- ztk uses it as an outside package. A plain Zig program uses it without ztk.

The name.

- *Paternitas* is Latin for "fatherhood".
- A Node does not carry its Parent type. paternitas establishes which Parent
  the Node belongs to.

---

## The problem

Zig's std lists are intrusive.

- A Parent contains a std Node.
- The list sees only the Node: `*std.DoublyLinkedList.Node`.
- The Parent type is gone.

`@fieldParentPtr` recovers a Parent when the type is known.

- It does not check that the Node belongs to that Parent.
- Two structs can put their Nodes in one list. The wrong Parent comes back,
  and the compiler cannot see it.
- The Zig community met this: the ziggit thread
  [New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).

A second problem.

- A container that stores by value copies its elements.
- Mixed element types are usually a tagged union, copied in.
- Some items must not be copied or moved.
  - An item with a mutex, a file handle, a pointer to itself, or a large
    buffer.

The question paternitas answers.

- How does an intrusive item cross a type-erased boundary?
  - Through intrusive containers, or through containers of pointers.
- And how does the program still recognize its Parent type?

---

## Words

- **Parent** — the struct that contains the Node, as in `@fieldParentPtr`.
  - Not a parent in a tree.
- **Node** — the unmodified std Node: `std.SinglyLinkedList.Node` or
  `std.DoublyLinkedList.Node`.
- **Anchor** — one stamped word inside every Parent. Its address is the
  erased reference to the Parent.
- **Link** — a Node and an Anchor as one type. A Parent embeds exactly one.
- **TypeInfo** — the static description of one Parent type.
- **TypeId** — the address of a `TypeInfo`.
- **`Typed(P)`** — the typed helper for one Parent type, built at comptime.
- **AnyParent** — the dispatch view: the Parent address and its TypeId.

---

## The model

```text
Parent
 |
 +-- Link  (one per Parent)
      |
      +-- node:   std Node (single or double)
      +-- anchor: Anchor { _type_id } ---> TypeInfo (static, one per type)
```

paternitas is mechanism, not policy.

- It says where things are, and what type they belong to.
- Containers built on it decide the rest.
  - Who frees a Parent.
  - How a Parent moves.
  - Allocation.
  - What a chain looks like.

---

## Why the Anchor sits next to the Node

The first idea was two separate fields in the Parent: a Node and a TypeId.

- It is unsound for mixed containers.
- Example, 64-bit.
  - `Message`: `text` at 0, `type_id` at 16, `node` at 24.
  - `Job`: `node` at 0, `type_id` at 16.
- Both share one `std.DoublyLinkedList`.
- A Node at address `A` lives in a `Job`.

```text
TypedMessage.parentFromNode(node)
  parent  = A - 24          // Message's Node offset
  type_id = parent + 16     // = A - 8, before the Job starts
```

- The check reads memory outside the `Job`. That is undefined behaviour.
- It usually answers "no match", so the bug does not show.

Why comptime cannot fix it.

- Comptime knows the Node kind.
- It does not know which Parent contains this Node.
- The check must read the TypeId before the Parent type is known.

Why an offset in `Typed` does not help.

- `Typed(Message)` knows where the TypeId is in a `Message`.
- For a Node in a `Job`, that address is some other field, or outside it.
- The check needs one rule for every Parent in the container:
  - From any Node, the TypeId is at the same place.
- A per-Parent comptime check of the distance fails.
  - Parents are auto layout. The compiler may reorder their fields.
  - An `extern` Parent would fix the order, but an extern struct cannot
    contain a std Node.

The fix: the Link.

- The Node and the Anchor are one type. A type's layout is chosen once.
- Every Parent embeds the same `SLink` or `DLink`.
- So the Node-to-Anchor distance is the same in every Parent, by
  construction.
- From any Node, `@fieldParentPtr("node", node)` finds the Link.
- ztk's `Inner { node, id }` already followed this rule.
- The same holds for the Anchor-to-`next` distance, which `nextField` uses.

When a container has one Parent type only, nothing is unknown. Plain
`@fieldParentPtr` is enough. paternitas is for the mixed case.

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

What it is.

- One word inside every Parent, in its Link.
- The Anchor is not the Parent. It is a small marker inside it.
- `*Anchor` is the erased reference to the Parent.
  - The address says where the Parent is.
  - The stamped value says what it is.

The calls.

- `typeId()` — the stamped id. Null when unstamped.
- `typeName()` — the type name, or `<unstamped>`. For panic and log text.
- `info()` — the type's `TypeInfo`. Null when unstamped. For container
  authors.
- `toAny()` — the dispatch view, without knowing the type. Null when
  unstamped.

`_type_id`. Owner's ruling, AUDT 01, A11.

- The leading `_` says: do not touch. ztk uses the same sign.
- `stamp` is the one writer.
- Readers use `typeId()`.
- Zig has no private fields. A hand-written `_type_id` passes every id
  check. The `///` says so.

Why not `extern`.

- No code depends on the Anchor's layout.
- A plain struct is already a distinct type. `*Anchor` is not
  `*?*const anyopaque`.
- `extern` adds one thing: an Anchor inside a user's `extern struct`, or
  across a C ABI. The day that is needed, it is a one-word change.

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

Who uses what.

- Application code: `Typed(P)`, `SLink`, `DLink`, `*Anchor` as a value,
  `AnyParent`, `Anchor.toAny()`.
  - It never touches `TypeInfo`.
- Container authors: `Anchor.info()` and `TypeInfo`.
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

- `_tag` — not for use. Its address makes this descriptor unique. See below.
- `name` — `@typeName(P)`, for panic and log text.
- `anchor_offset` — from the Parent start to its Anchor.
- `node_next_offset` — from the Anchor to the Node's `next` field.
  - Signed: the Node may sit before the Anchor.
- `node_kind` — `.single` or `.double`.

### Why `_tag`

Owner's ruling, AUDT 01, A1.

The fault it fixes.

- Zig merges constants with equal contents.
- `@typeName` is not unique across modules.
  - Two modules, each with a root file `msg.zig` and a type `Msg`, both give
    `msg.Msg`.
- Equal name, equal offsets, equal kind: equal descriptors.
- In ReleaseSafe, ReleaseFast and ReleaseSmall they were merged.
  - The two types had one TypeId.
  - `Typed(A).fromAnchor` returned a `B` as an `A`.

The fix.

- `Typed(P)` declares a private `var tag: u8 = 0`.
- Its descriptor keeps `._tag = &tag`.
- Two descriptors then never have equal contents. They are never merged.
- The descriptor stays `const`, in read-only data.
- The tag is a `var` because a `var` is its own symbol.
  - A `const` tag would be the same zero byte in every `Typed(P)`, and would
    be merged.
- The tag is never read or written. Only its address counts.
- A test checks it, in all four modes: two modules, the same root file name,
  the same type name, two TypeIds.

### `nextField`

- The address of the Node's `next` field, for either Node kind.
- Location only. paternitas never reads or writes this word.
- Typed `*?*anyopaque`, not `*?*Anchor`.
  - What a container keeps in the word is its own choice.
  - A std list keeps Node pointers. ztk keeps Anchor pointers.
- paternitas does not say what null means, what a pointer to itself means,
  or who may write the word.

Part of the contract.

- The `next` word is shared.
- A std list writes it while the Parent is in that list.
- A container that chains through `nextField` does not use the Parent while
  it is in a std list. The other way round too.

### `parent`

- The Parent address, erased, through `anchor_offset`.
- For code that passes the raw Parent to something that knows nothing of
  paternitas, such as a C callback's `void*`.

### `toAny`

- The dispatch view of the Parent behind this Anchor. See AnyParent.

### `node`

- The Node, typed.
- Panics in every build mode when `N` is not this type's Node kind.
  - A wrong kind would read memory as the wrong Node type.
- `N` that is not a std Node is a compile error.

### Identity rules

A TypeId is a static type identity. It is not:

- a Parent address,
- a Node address,
- an instance identifier,
- a lifetime token,
- a list membership token.

Other facts.

- All instances of one Parent type share one TypeId.
- No integer type numbers, no global registry, no registration, no runtime
  allocation.
- Valid inside one running binary only.
  - Not persistent, not serialized.
  - Across a dynamic library or plugin boundary, two ids of one type may
    differ.
- An unstamped Anchor has `null`.
  - `null` matches no Parent.
  - Zeroed memory is a valid unstamped Anchor.
  - An unstamped Anchor has no `TypeInfo`, so no `nextField`. A container
    checks the stamp before it touches the chain word.

---

## Link

```zig
pub fn Link(comptime N: type) type;   // struct { node: N = .{}, anchor: Anchor = .{} }

pub const SLink = Link(std.SinglyLinkedList.Node);
pub const DLink = Link(std.DoublyLinkedList.Node);
```

- Comptime glue. A Parent embeds `SLink` or `DLink` once, and never calls
  into it.
- The Node inside is the unmodified std Node.
- paternitas has no list of its own.

`N`. Owner's ruling, AUDT 01, A3.

- `Link` is `pub`.
- `N` is `std.SinglyLinkedList.Node` or `std.DoublyLinkedList.Node`.
- Any other `N` is a compile error, naming `N`.
  - Reason: `Typed` accepts only these two. A Link of another Node was a dead
    end, with a wrong `kind`.

Public names inside a Link.

- `Node` — the Node type, `N`.
- `kind` — `.single` or `.double`.
- `node_next_offset` — from the Anchor to `next`.

### Field order and the uniform offset

- The fields are declared `node`, then `anchor`.
- A Link cannot be `extern`. The std Nodes are auto layout.

```text
error: extern structs cannot contain fields of type 'SinglyLinkedList.Node'
```

- The compiler may reorder the fields.
- Correctness does not depend on the order. Every offset is computed at
  comptime.
- Speed does.
  - `next` is the last word of both std Nodes.
  - With the Anchor after the Node, `next` is at the same distance from the
    Anchor in both Links.
  - Zig 0.16.0, 64-bit targets, all four modes: both are -8.

```zig
pub const uniform_next_offset: ?isize =
    if (SLink.node_next_offset == DLink.node_next_offset) SLink.node_next_offset else null;
```

- When it holds, `nextField` adds a constant and loads nothing.
- When a compiler breaks it, `nextField` reads `ti.node_next_offset`. Still
  correct, one load slower.
- A test pins `uniform_next_offset != null`. A layout change is a failing
  test, not a silent slowdown.
- The test runs on the host only. Cross targets are built, not run. The
  fallback keeps them correct. AUDT 01, A12.

The fallback is tested. AUDT 01, A15.

- On every tested target the uniform offset holds. The fallback branch of
  `nextField` never runs.
- So the address step is a function that takes the offset:
  `container._nextFieldAt`.
  - `nextField` calls it with the uniform offset, or with
    `ti.node_next_offset`.
  - It is `pub`, so a test in `tests/` reaches it.
  - The leading `_` says: not for use. Owner's ruling, PTRN 01.
- A test calls the step with `ti.node_next_offset`, for both kinds. It must
  land on `next`.

---

## Required Parent shape

A Parent is a struct with exactly one `SLink` or `DLink` field.

- Any field name. Any position.
- The Link is found by its type, among the top-level fields.

```text
not a struct      -> compile error
zero Links        -> compile error
one Link          -> accepted
more than one     -> compile error
```

- Each compile error names the Parent type.
- A Parent may contain other plain std Nodes for other lists.
  - paternitas ignores them.
  - `parentFromNode` is never used on them.

Moving existing code is one field per Parent.

```zig
const Message = struct {
    link: paternitas.DLink = .{},   // was: node: std.DoublyLinkedList.Node = .{},
    text: []const u8,
};
```

- `message.node` becomes `message.link.node`, or `TypedMessage.node(&message)`.
- The std lists, their calls and their Node type stay.

Initialize before stamping.

- `allocator.create(P)` returns undefined memory.
- The Link's `.{}` default applies only with an initializer.

```zig
const m = try allocator.create(Message);
m.* = .{ .text = "hello" };   // the Link becomes .{}
TypedMessage.stamp(m);
```

- `stamp` does not repair a Link that was never initialized.

---

## `Typed(P)`

```zig
const TypedMessage = paternitas.Typed(Message);
```

At comptime it finds the one Link, builds the `TypeInfo`, and gives typed
calls for this Parent.

```text
Node                               the Node type of P's Link
typeId()                      -> TypeId
isId(TypeId)                  -> bool
stamp(*P)                     -> void
anchor(*P)                    -> *Anchor
node(*P)                      -> *Node
is(*const Node)               -> bool
fromAnchor(*Anchor)           -> ?*P
mustFromAnchor(*Anchor)       -> *P
toAny(*P)                     -> AnyParent
fromAny(AnyParent)            -> ?*P
parentFromNode(*Node)         -> ?*P
mustParentFromNode(*Node)     -> *P
parentFromNodeUnchecked(*Node)-> *P
```

- Another Node kind, or another Parent type, does not compile.

### `typeId`, `isId`

- `typeId()` is the address of this type's `TypeInfo`. It is the only source
  of the id.
- `isId(id)` compares a bare id with it.
  - For code with an id and no Parent: a pool asked for "a `Message`", a
    count by type.

### `stamp`

- Writes `TypeId(P)` into the Anchor. Writes nothing else.
- It does not touch the Node. Stamping a Parent that is already in a list is
  safe.
- A Parent is initialized before `stamp`.
- A Parent is stamped before its Node or Anchor crosses a type-erased
  boundary.
- There is no `unstamp` and no `init`. AUDT 01, T4 and T5.
  - `anchor(p).* = .{}` resets the Anchor. When to do it is container
    policy.
  - `stamp` after the initializer covers `init`.

### `anchor`, `node`

- The Anchor and the Node inside this Parent's Link.

### `is`

- True when the Node's Anchor is stamped as `P`.
- Takes `*const Node`. AUDT 01, T6.
- The Node lives in a Link. See "Container rule for Nodes".

### `fromAnchor`, `mustFromAnchor`

```text
*Anchor
   |  read the id, compare with TypeId(P)
   +-- mismatch -> null
   |  @fieldParentPtr("anchor") -> Link, @fieldParentPtr(link field) -> Parent
   v
*P
```

- `mustFromAnchor` panics on a mismatch, in every build mode.
- The text names the type asked for and the type found.

```text
mustFromAnchor: asked for app.Message, found app.Job
mustFromAnchor: asked for app.Message, found <unstamped>
```

### `toAny`, `fromAny`

- `toAny(p)` builds the dispatch view of `p`.
- `fromAny(any)` compares `any.type_id` with `TypeId(P)`.
  - A match: `any.ptr` cast to `*P`.
  - A mismatch: null.
  - Where runtime safety is on, it also checks that the Parent's Anchor is
    stamped as `P`.

### `parentFromNode` and its forms

```text
*Node
   |  @fieldParentPtr("node")    -- the Link layout, the same in every Parent
   v
Link
   |  read the Anchor's id, compare with TypeId(P)
   +-- mismatch -> null
   |  @fieldParentPtr(link field) -- the Parent layout, only after the match
   v
*P
```

- The unchecked read uses only the Link layout.
- The Parent layout is used only after the type matches.
- `mustParentFromNode` panics on a mismatch, like `mustFromAnchor`.
- `parentFromNodeUnchecked` skips the check.
  - The caller already knows the type. The name says so.
- No const recovery forms. AUDT 01, T6. The reason is the same as for
  `AnyParent.ptr`.

---

## Container rule for Nodes

- `parentFromNode`, `mustParentFromNode` and `is` read the Anchor next to the
  Node.
- Every Node in a container where they are used lives inside a paternitas
  Link.
- A bare std Node in the same container makes the check undefined behaviour.

No call goes from a Node to an Anchor without a Parent type.

- It would trust that any Node lives in a Link, and nothing in its signature
  would say so.
- Code that has a std list knows what it put there.

```zig
const p = TypedMessage.parentFromNode(n) orelse ...;
use(TypedMessage.anchor(p));
```

---

## Containers of `*Anchor`

- Intrusive containers carry Nodes. Containers of pointers carry `*Anchor`.
- The container keeps a pointer. The Parent stays where it is.
- Copying a `*Anchor` copies a reference, not the Parent.
  - A Parent that must not move travels through any container of pointers.
- "No Parent" is `?*Anchor`.

As one variant among small copyable ones, or as the only element type.

```zig
const Event = union(enum) {
    tick: u64,
    resize: Size,
    parent: *paternitas.Anchor,
};

var q: Queue(*paternitas.Anchor) = ...;
```

Recovery.

```zig
if (TypedMessage.fromAnchor(a)) |m| { ... }
```

- The check reads the Anchor word, in the Parent's memory.
- For a live Parent that costs nothing.
- For a stale reference it is undefined behaviour, as any later use would be.

### Against tagged unions

```text
                  tagged union             *Anchor
set of types      closed, fixed in union   open, any stamped Parent
identity          enum tag in element      static address in the Parent
storage           largest variant + tag    one pointer
the Parent        copied                   stays in place
lifetime          none required            Parent outlives every reference
recovery check    exhaustive switch        runtime TypeId compare
```

- Tagged unions fit small, closed, copyable payloads.
- `*Anchor` fits Parents that must not move, open sets of types, and existing
  intrusive code.
- They combine: `*Anchor` can be one variant of a tagged union.

---

## AnyParent: the dispatch view

```zig
pub const AnyParent = struct {
    ptr: *anyopaque,   // the Parent
    type_id: TypeId,
};
```

Who it is for.

- A consumer that keeps a map from TypeId to handler, and no paternitas in
  its code.
- It receives a Parent, finds the handler by the id, and the handler casts
  the pointer to its own type.
- `*Anchor` serves it badly: reaching the Parent needs `TypeInfo`.
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

Dispatch, with no paternitas call in the hot path.

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
- The handler for `Message` is registered under `Message`'s id. Its cast is
  correct by construction.
- The handler's cast is unchecked.
  - A wrong registration is a wrong cast, and nothing catches it.
  - `Typed(P).fromAny` is the checked form.

Where an AnyParent comes from.

```text
mailbox --> *Anchor --a.toAny()--------> AnyParent --> handler(ptr)
typed code --> *P  --Typed(P).toAny(p)-----> AnyParent
```

- One way. No call turns an `AnyParent` back into an `*Anchor`.
  - At the dispatch site the Anchor is still at hand.
  - A typed handler uses `Typed(P).anchor(p)`.
- Built by `toAny` only.
  - The fields are `pub`, so a hand-built one is possible. The `///` says
    not to. AUDT 01, A11.
  - The fields keep their names. A dispatch consumer reads them directly.

`ptr` is mutable.

- Every `AnyParent` is built from a mutable `*P` or a mutable `*Anchor`.
- A const field would force every handler to write `@constCast`.
- `toAny` never accepts `*const P`.

An `AnyParent` is a view.

- Copies are aliases.
- The Parent outlives every copy.

---

## Between the two kinds of container

```text
std list Node --Typed(P).parentFromNode--> *P --Typed(P).anchor--> *Anchor --> queue

queue --> *Anchor --Typed(P).fromAnchor--> *P --Typed(P).node--> std list Node
```

Dispatch, without `P`.

```text
*Anchor --a.toAny()--------> AnyParent --> handler(ptr)
```

Erased code that does not know `P`, but knows the Node kind it wants.

```text
*Anchor --a.info().node(N)--> *N
```

Mixed Parents in one std list.

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
- The Link positions in the two Parents do not matter.
- An `SLink` Parent and a `DLink` Parent cannot share one std list.
  - They can share a container of `*Anchor`.
  - They can share a chain through `nextField`.

---

## Checks

Two kinds of runtime check.

Type recognition is part of the API.

- `fromAnchor`, `fromAny`, `parentFromNode`, `is` return null or false on a
  mismatch, in every build mode.
- The `must` forms and the kind check in `TypeInfo.node` panic in every build
  mode.

Contract checks catch misuse.

- They panic where runtime safety is on. Elsewhere they compile to nothing.
- They do not use `std.debug.assert`.
  - In ReleaseFast and ReleaseSmall, `assert` becomes `unreachable`.
  - A broken contract then becomes undefined behaviour the optimizer may
    reason from.

```zig
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}
```

- The same policy as ztk's `internal/check.zig`.
- Internal. Not `pub`.

Two levels of type safety.

```text
compile time, through Typed(P):   the Parent type, the Node kind
run time, after erasure:         the Anchor's id   -> which Parent
                                 TypeInfo          -> where its Anchor, Node
                                                      and next are; its name
```

---

## What a TypeId does not prove

Type identity, not memory validity.

- Not that the Parent is alive.
- Not that the pointer is valid or aligned.
- Not that the Node address is intact.
- Not that the Anchor was not overwritten.
- The Parent stays alive while its Node address, or any copy of its
  `*Anchor` or `AnyParent`, is in use.

List membership.

- paternitas does not know whether a Node is in a list, in which one, or
  free.
- It does not know whether a Node is in two lists at once.
- It never reads Node contents.
  - std lists end a chain with null. ztk ends its chains with a pointer to
    the last item itself.
  - paternitas supports both by reading neither.

Synchronization.

- No mutexes, atomics, memory ordering, thread rules, or lifetime
  synchronization.

Who frees a Parent.

- paternitas does not say.
- `*Anchor` is a reference. Copies are aliases of one Parent.
- The application decides who frees the Parent.
- Containers that need stricter rules build them on top.
  - ztk keeps one place per item, through its `Slot`.
  - A plain user gets none of these rules, and needs none.

---

## Why one Link

- A Parent may need several intrusive relationships: a ready list, a timeout
  list, a free list.
- They are different relationships. Guessing one would make the API
  ambiguous.
- The core allows exactly one Link.
- Other plain std Nodes are allowed, and not recognized.
- Named multi-Link relationships are outside the core.

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
- `unstamp` or `init`. AUDT 01, T4 and T5.

Other facts.

- No allocation anywhere.
- A Parent can be on the stack, static, on the heap, in a pool, or inside
  another struct.
- paternitas depends only on `std`. ztk depends on paternitas, not the other
  way round.

---

## API

Every function is `inline`, except `Anchor.typeName`. AUDT 01, A7.

```zig
// ---- paternitas: application API

pub const TypeId = ?*const anyopaque;

pub const Anchor = struct {
    _type_id: TypeId = null,        // written by stamp only

    pub fn typeId(a: *const Anchor) TypeId;
    pub fn typeName(a: *const Anchor) []const u8;              // or "<unstamped>"
    pub fn toAny(a: *Anchor) ?AnyParent;                       // dispatch, type unknown
    pub fn info(a: *const Anchor) ?*const container.TypeInfo;  // container authors
};

pub const AnyParent = struct {     // dispatch view, one way, built by toAny only
    ptr: *anyopaque,
    type_id: TypeId,
};

pub fn Link(comptime N: type) type;   // N: one of the two std Nodes
//   node: N = .{}
//   anchor: Anchor = .{}
//   Node, kind, node_next_offset
pub const SLink = Link(std.SinglyLinkedList.Node);
pub const DLink = Link(std.DoublyLinkedList.Node);

pub fn Typed(comptime P: type) type;
//   Node
//   typeId() TypeId
//   isId(id: TypeId) bool
//   stamp(p: *P) void
//   anchor(p: *P) *Anchor
//   node(p: *P) *Node
//   is(n: *const Node) bool
//   fromAnchor(a: *Anchor) ?*P
//   mustFromAnchor(a: *Anchor) *P
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

The sources. AUDT 01, A8.

- `src/paternitas.zig` — the application API, `Link`, `Typed`.
- `src/container.zig` — `TypeInfo`, `NodeKind`, `uniform_next_offset`.
- The two files are the source of truth for the API above.

The build.

- The module `paternitas`. Steps `test`, `examples`, `docs`, `negative`.
- `build.zig.zon` keeps this repo's fingerprint and version `0.0.1`.
  - Intake D9 said `0.0.0`. The repo had `0.0.1`. Owner's ruling, PTRN 01.
- `negative/` is not in the package paths. A package that depends on
  paternitas does not need it.
- Zig 0.16.0. All four modes.

### Tests

In `tests/`, with `std.testing.log_level = .debug`.

From the outside code.

- The uniform `next` offset holds.
- Distinct ids. `TypeInfo` fields and calls.
- An `SLink` Parent and a `DLink` Parent in one Anchor chain. Then the `DLink`
  Parent in a `std.DoublyLinkedList`, and back.
- Unstamped Parents.
- Stamping Parents that are already in a list.
- Dispatch through a `TypeId -> handler` map, with no `Typed` call at
  dispatch.
- `toAny` and `fromAny`.
- `*Anchor` and `AnyParent` inside a tagged union.
- The offset stored in `TypeInfo` lands on `next` for both kinds, and so does
  `nextField`.

Added by AUDT 01.

- Two modules, the same root file name, the same type name: two TypeIds. A1.
- The success path of `mustFromAnchor` and `mustParentFromNode`. A5.
- `is` true. `isId` and `parentFromNodeUnchecked` directly. A5.
- `Anchor.typeName` of a stamped Anchor. A5.
- `TypeInfo.node` for a `DLink` Parent. A5.
- `Anchor.typeId()`. A11.
- The fallback step of `nextField`, with the stored offset, for both kinds.
  A15.

### Negatives

A test cannot reach a compile error or check a panic. These are programs.

- `zig build negative`. Gate 6, all four modes.
- The host only. The panic programs check the abort signal and the stderr
  text. AUDT 01, A10.

Must not compile, with that message.

- A Parent that is not a struct.
- A Parent with a bare std Node and no Link.
- Two Links.
- A DNode passed where an SNode is expected.
  - The message is Zig's. Only its tail is matched:
    "found '*DoublyLinkedList.Node'". A9.
- A Link of a Node that is not a std Node. A3.
  - "Link(N): not a std Node, so it cannot be a Paternitas Link", with `N`'s
    name.

Must abort in every build mode, and say why on stderr.

- `mustFromAnchor` on another type: names both types.
- `mustParentFromNode` on an unstamped Parent: names `<unstamped>`.
- `TypeInfo.node` with the wrong Node kind.

Depends on the mode. A5.

- `fromAny` of a hand-built `AnyParent` whose Parent is not stamped.
  - Debug, ReleaseSafe: aborts, with "fromAny: the Parent was never
    stamped".
  - ReleaseFast, ReleaseSmall: exits 0.

Nine programs: five compile, four run.

### Examples

In `examples/`. One pattern each. Rules Part 2, "Examples".

- Flat: `NNN-name.zig`, one `pub fn` each. Owner's ruling, PTRN 02.
- `examples/examples.zig` is a barrel. The site skips it.
- One test wrapper each, in `tests/examples_tests.zig`.
- Each file is a page on the site, generated from its `//!` and its source.

```text
001-stamp_and_recover   one Parent, a std list, back
002-mixed_list          two Parent types in one std list
003-timeout_list        a DLink Parent in a timeout list, through a
                        std.Io.Queue(*Anchor), and back
004-handler_map         a TypeId -> handler map; toAny, fromAny
005-anchor_in_union     *Anchor as one variant of a tagged union
006-anchor_chain        a stack chained through TypeInfo.nextField
```

---

## ztk on paternitas

The ztk stage moves ztk onto paternitas. The full plan, file by file, is the
outside design's section "Matryoshka-ztk changes", in
`design/source/paternitas-design.md`. The open questions are in the intake,
"Open for the ztk stage".

The principle.

```text
paternitas                               ztk
----------                               ---
TypeId, TypeInfo, Anchor                 Slot: one place per item
SLink, DLink                             chain convention: the tail points
Typed: stamp, anchor, node, is,            to itself; isLinked, unlink
  fromAnchor, parentFromNode             Queue, stack, Mbox, Pool
TypeInfo.nextField: where next is        what goes in next
contract-check policy                    create / destroy, init / finish,
                                           allocator, Io, border checks
```

The main changes.

- The ztk currency moves from `*Inner` to `*Anchor`.
- `Inner`, `OuterId`, `OuterInfo` leave the API.
- `AnyOuter` is removed. `AnyParent` replaces it at the dispatch edge.
- A ztk parent may carry a `DLink`. It can sit in the application's own
  `std.DoublyLinkedList`, and move through mailboxes and pools, one place at a
  time.

Changed by AUDT 01.

- ztk code reads the id as `anchor.typeId()`, not `anchor.type_id`. A11.
- `ParentHelper(Parent)` stays. It wraps `Typed(P)` and adds ztk policy.
  - The Slot calls: `fromSlot`, `moveFromSlot`, `mustMoveFromSlot`.
  - `create` and `destroy`, with their hooks.
  - `isLinked`, and ztk's `stamp`.

The vocabulary.

- The ztk API says Parent, Link, Node, Anchor, TypeId, AnyParent.
- "outer" and "inner" stay only where the Matryoshka model is explained: the
  parent is the outer doll.
- No mechanical rename. Each `Outer` and `Inner` is read in context.
  - Some are new names: `OuterId` -> `TypeId`, `fromInner` -> `fromAnchor`.
  - Some change meaning: `Inner` -> `Anchor` or Link, `inner.next` ->
    `TypeInfo.nextField`.

---

## The central invariant

For a stamped, live Parent:

```text
Parent
 |
 +-- Link
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
- The Node and the Anchor live together in a Link.
- The Link can be anywhere in the Parent.
- The Anchor is one stamped word. Its address is the erased reference: the
  transport currency.
- AnyParent is the Parent address and its TypeId: the dispatch view.
- The TypeId is the address of a static, unique TypeInfo.
- `TypeInfo` says where things are. Containers decide what to do there.

```text
*Node   -- Typed(P).parentFromNode() --> checked *P
*Anchor -- Typed(P).fromAnchor()     --> checked *P
*Anchor -- TypeInfo.nextField()     --> where a container may chain
*Anchor -- TypeInfo.toAny()         --> AnyParent for dispatch
```

---

## Decisions of PTRN 02

Docs and examples. Owner's rulings, 2026-10-02. The intent:
[ptrn-02-intent-001.md](ptrn-02-intent-001.md).

- Six examples. The set is in "Examples" above.
  - The design's two: 003 and 004.
- The layout is flat. There are fewer examples than in ztk.
- 003 uses `std.Io.Queue(*Anchor)` as its container of pointers.
- The README has no install section. Later.
- The landing page: only the Examples button target changed. The rest is
  LOOK 01.
- The root `//!` has a fenced usage block.
- `nameOf` became `Anchor.typeName()`. Owner's ruling, after the gates.
  - Reason: autodoc shows a declaration where it is declared. A file-scope
    `nameOf` sat on the root page, away from `Anchor`.
  - The name pairs with `typeId()`.
  - The outside design had it at file scope, with no reason given.
- An example's `//!` intro has one sentence or two per line.
  - Reason: the site's hard-break fixer breaks a wrapped line in the middle
    of a sentence.
- `Info(P)` became `Typed(P)`. Owner's ruling, after the stage.
  - Reason: `Info` read as the same thing as `TypeInfo` and `Anchor.info()`.
    `Anchor.info()` returns a `TypeInfo`, not an `Info(P)`.
  - `Helper` was proposed, from a review the owner collected. Not taken. ztk
    has `ParentHelper(P)` and an `XxxHelper` const per Parent, in 97 files.
    A paternitas `Helper` would give a ztk user two different `EventHelper`s.
  - `Typed` says what the layer is: the typed side of the erased Anchor.
    `TypedMessage.fromAnchor(a)` reads as it works.
  - `TypeInfo` and `Anchor.info()` keep their names.
  - The helper is a plain `const` next to its Parent:
    `const TypedMessage = paternitas.Typed(Message);`. Not a declaration
    inside the Parent: that works only for a Parent you write yourself.
- The examples' layout. Owner's ruling, from the owner's edit of 002.
  - What exists comes before what happens.
  - The types first, each Parent with its `Typed` const on the next line.
  - Then the `pub fn`, then the private fns, the imports last.
  - 001 keeps its types inside the function. It has one Parent, used there
    only.

---

## Decisions of PTRN 01

The port. Owner's rulings, 2026-10-02. The intent:
[ptrn-01-intent-001.md](ptrn-01-intent-001.md).

- A15: the address step of `nextField` is `pub`, named `_nextFieldAt`.
  - Reason: a test in `tests/` cannot reach a private function.
  - The leading `_` keeps it out of normal use. ztk uses the same sign.
  - A quoted name was tried first. Autodoc broke its link.
- The version stays `0.0.1`.
- `VERSION` leaves the API. The design's API has no such name.
  - The placeholder example `print_version` is replaced by
    `stamp_and_recover`. PTRN 02 keeps or rewrites it.
- SPDX headers in `src/`. Not in `tests/`, `negative/`, `examples/`.
- `negative/` is not in the package paths.
- Rules: an alias of `std` goes before `std`. `std` is last.

---

## Decisions of AUDT 01

The audit of the outside paternitas. Owner's rulings, 2026-10-02. Each
finding, its evidence and its ruling:
[audit-01-report-003.md](audit-01-report-003.md).

- A1: a private `var` tag, its address in `TypeInfo._tag`. The descriptor
  stays `const`.
  - Reason: Zig merged equal descriptors of two types with one
    `@typeName`, in three modes.
  - A `var` descriptor was refused: it can be changed.
- A3: `Link` stays `pub`. Any other Node is a compile error.
- A6: the `fromAny` panic text stays.
- A11: `_type_id`, read through `Anchor.typeId()`.
- T1 to T3 from `paternitas-001.md` are in this design.
- T4 `unstamp` and T5 `init`: out.
- T6: `is` takes `*const Node`. No const recovery forms.
- T7: the picture, the logo and the like get a stage of their own.

ChatGPT's review of design 004. Claude's analysis, owner's rulings,
2026-10-02.

- It approves the design.
- Most of its points were already decided, in design 004 or in the outside
  design: `Parent` in the ztk API, "outer" in the model only, the boundary,
  `*Anchor` as the currency, no `Inner` alias, the `DLink` scenarios.
- Taken.
  - A15: the `nextField` fallback branch had no test.
  - `AnyParent` named as the replacement of `AnyOuter`.
  - No mechanical rename in ztk.
- Not taken: dropping the ztk wrapper. `ParentHelper` carries ztk policy.
- Changed: its ztk checkpoint after step 8 of 16 cannot pass. Queue, stack,
  Mbox and Pool chain through `Inner`. The checkpoint goes after the
  containers.

---

## Decisions of INTR 15

INTR 15 moved the development process from next/ztk into paternitas. Owner's
rulings, 2026-09-25.

### Q1 — the rules file

- The rules file is a trimmed copy of `ZTK/design/rules-050.md`.
- Kept: Part 0 adapted, Zig style, comments and autodoc, banned words, writing
  documents.
- Dropped: the Master pattern, stories, dispatch, Matryoshka's invariants.
- Added: the git rules.
  - `git status` is the only git command a session runs.
  - A plain `mv` replaces `git mv`.
- It links back to the source rules, with a note that their version may have
  moved on.
- Reason: the process rules are what carries over. The Matryoshka-specific
  rules describe a toolkit paternitas is not.

### Q2 — the layout

- The same shape as next/ztk.
  - `build.zig`, `build.zig.zon`, module `paternitas`.
  - `src/`, `tests/`, `examples/`, each with a placeholder file.
  - `kitchen/` for the gate scripts, the site tools and the site sources.
  - `design/` for the documents.
- No `negative/` and no gate 6 at first.
  - Deferred to the first stage where paternitas refuses something.
  - Reason: a gate with no cases proves nothing.
  - That stage is PTRN 01. See "Negatives" above.

### Q3 — ztk knowledge

- paternitas keeps paths into the ztk sources, never copies.
- What it keeps is ztk's smell, process, mantra and intent. See the section
  below.
- Reason: a copy rots. A path points at the current text.

### Q4 — process audit

- Two passes.
  - INTR 15 does a quick pass before the first rules file is written. It
    fixes what is clearly wrong or outdated. The findings are in
    `STATUS-LOG.md`, under INTR 15.
  - ADPT 01 goes deeper and tunes the workflow.

### Q5 — the site

- The same structure as next/ztk: an mkdocs landing page, plus `zig build
  docs` for the API docs.
- Placeholder content.
  - Title "paternitas".
  - One line from the owner's text.
    - The line is "Paternitas". Owner's ruling, 2026-09-25.
    - It replaced a proposed sentence from `paternitas-001.md`.
  - A badge that links to `apidocs/`.
  - No logo yet. AUDT 01, T7: a stage of its own.
- The API docs are generated from the sources.

### Q6 — CI

- Every `.github` workflow of matryoshka-ztk is copied: linux, mac, windows,
  docs (GitHub Pages).
- Each is adapted to paternitas' names and paths.
- The gates pass locally before the owner pushes, so CI starts green.

### The first sources are placeholders

- They exist to check that the scripts, the build, the tests and the doc
  generation work.
- They implement nothing. PTRN 01 replaces them.

### Kitchen tools changed on the way in

- `gen_examples_docs.sh` regenerates the whole of `kitchen/docs/examples/`.
  - Reason: next/ztk listed its own example groups by name, and mirrored
    `stories/`. paternitas has neither.
- `fix_md_hardbreaks.sh` fixes `kitchen/docs/` only, not every `.md` in the
  repo.
  - Reason: `paternitas-001.md` is kept untouched, and `STATUS-LOG.md` is never
    edited. A site build must not rewrite either.
- `fix_md_hardbreaks.sh` and `fix_md_lists.sh` skip a page's leading front
  matter block.
  - Reason: in next/ztk they rewrote the landing page's front matter. The `---`
    line got trailing spaces, and a blank line appeared inside the `hide:` list.
- `check_next_docs.sh` became `check_docs.sh`.
  - Checks kept: dead references, banned words.
  - Dropped: the retired-word list, and the plan-version check against the log.

---

## Decisions of ADPT 01

ADPT 01 tuned the workflow before any real code. Owner's rulings, 2026-09-25.
The process rulings are in the rules file. The list is in
[backup/adpt-01-intent-002.md](backup/adpt-01-intent-002.md).

### The gates

- `kitchen/gates.sh` runs the five gates, with fixed log names.
  - Reason: the gates cost round trips, and the log names changed per stage.
- `check_docs.sh` enforces every entry of the banned list: the words, their
  other forms, the phrases.
  - Reason: `grep -w` matches whole words only. A banned word with an `-ed`
    ending passed the gate.
  - The words whose meaning decides stay a hand scan.
- The test wrappers keep `std.testing.log_level = .debug`.
  - Reason: the owner wants all four levels in the test output.
  - Cost: Zig 0.16 prints it under a `failed command:` line. Accepted.

### The site

- The favicon stays ztk's until paternitas has a logo.
  - Reason: the same as the placeholder sources. Nothing to show yet.
  - The duplicate `kitchen/docs/favicon.ico` was deleted, with the owner's
    approval.
- The landing page hides the navigation. An "Examples" button sits beside the
  lines-of-code badge.
  - The nav entry stays, for every other page.
- `fix_md_hardbreaks.sh` skips raw HTML.
  - Reason: it added trailing spaces inside the landing page's `<style>`
    block and hero `<div>`. They meant nothing there.

---

## What paternitas keeps from ztk

Paths only. The ztk repo root is
`/home/g41797/dev/root/github.com/g41797/matryoshka-ztk`, written `ZTK` below.
`NEXT` is `ZTK/design/secondary/lang/port/3tk-to-ztk/next`.

A path here may go stale when ztk moves a file. When it does, fix the path in a
new version of this document.

### Smell — how the code looks

- The rewritten toolkit: `NEXT/ztk/src/`.
  - The module root: `NEXT/ztk/src/matryoshka.zig`.
  - Code hidden from the docs: `NEXT/ztk/src/internal/`.
- The tests and examples: `NEXT/ztk/tests/`, `NEXT/ztk/examples/`.
- What the toolkit refuses: `NEXT/ztk/negative/`, and its `README.md`.
- The build: `NEXT/ztk/build.zig`.

### Process — how the work is done

- The full rules: `ZTK/design/rules-050.md`.
- The state file of the new tree: `NEXT/next-status.md`.
  - Its **Rules** and **The gates** sections are the source of Part 0 and
    Part 1 of the rules file.
- The narrative of the new tree: `NEXT/next-log.md`.
- The stage menu: `NEXT/next-staging-plan-NNN.md`, the highest number.
- The old tree's state and narrative: `ZTK/design/STATUS.md`,
  `ZTK/design/STATUS-LOG.md`.
- The gate scripts and site tools: `NEXT/ztk/kitchen/`.
- CI: `ZTK/.github/workflows/`.

### Mantra — what ztk keeps to

- An item sits in exactly one place, in exactly one state, at any moment.
  - `ZTK/design/rules-050.md`, Part 4, **Exclusive access, in comments**.
- Observable by human: a coordinator plus named steps.
  - `ZTK/design/rules-050.md`, Part 1.
- Staccato, everywhere text is written.
  - `ZTK/design/rules-050.md`, Part 6.

### Intent — why ztk is shaped the way it is

- The backport rulings: `ZTK/design/secondary/lang/port/3tk-to-ztk/3tk-to-ztk-007.md`.
  - Section **BKP 2 — the rulings**.
  - Section **The direction change**.
  - Section **The documentation direction**.
- The old tree's design folder: `ZTK/design/`.
  - Index: `ZTK/design/context.md`.
  - Concepts: `ZTK/design/matryoshka-concepts-003.md`.
