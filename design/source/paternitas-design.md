# Paternitas

**Paternitas** is Latin for **fatherhood**.

In legal terminology, paternity is the establishment or recognition of who the
father of a child is.

The name fits the idea of this project:

> A `Node` does not carry its `Parent` type directly.
> Paternitas establishes which `Parent` the `Node` belongs to.

Paternitas is a small Zig package for **intrusive type-erased programming**.

It is extracted from the core of Matryoshka-ztk (`inner.zig`, `helper.zig`,
`internal/info.zig`).
Matryoshka is meant to use it as an external package.
A plain Zig program can use it without Matryoshka.

---

# Problem

Zig has intrusive data structures.

A Parent can contain a standard library Node.
The Node can be passed to code that does not know about the Parent.

The result is:

```zig
*std.DoublyLinkedList.Node
```

The Parent type has been erased.

Later, code may receive only the Node address.
Zig knows it is a doubly linked Node.
It does not know which Parent contains it.

`@fieldParentPtr` can recover a Parent when the Parent type is already known.
It does not establish that the Node actually belongs to that Parent.

There is a second, related problem.

Non-intrusive containers store elements by value.
Heterogeneous elements are usually a tagged union, copied into the container.
This does not work for objects that must not be copied or moved:
objects holding a mutex, a file handle, self-pointers, or a large buffer.

The problem is therefore:

> How can an intrusive object cross a type-erased boundary,
> through intrusive containers or containers of pointers,
> while still allowing the program to recognize its Parent type?

---

# Model

```text
Parent
 |
 +-- Link  (comptime glue, one per Parent)
      |
      +-- node:   std Node (SNode or DNode)
      +-- anchor: Anchor { type_id } ---> TypeInfo (static, one per Parent type)
```

Five pieces:

* **Anchor** — one stamped word inside every Parent.
  Its address is the erased reference to the Parent.
* **TypeInfo** — the static description of one Parent type.
  Its address is the TypeId.
  It knows where everything is relative to the Anchor.
* **Link** — comptime glue that pairs a std Node with an Anchor.
  The user embeds it and never calls it.
* **Info(Parent)** — the typed helper, generated at comptime.
* **AnyParent** — a dispatch view: the Parent address plus its TypeId,
  for consumers that do not want Paternitas in their hot path.

Paternitas is mechanism, not policy.
It says where things are and what type they belong to.
Ownership, move discipline, allocation and chain conventions belong to the
containers built on top of it.

---

# Why the TypeId sits next to the Node

An earlier version of this design placed the Node and the TypeId as two
independent fields anywhere in the Parent.

That is unsound for heterogeneous containers.

Example, 64-bit, illustrative offsets:

```zig
const Message = struct {
    text: []const u8,                        // 0..16
    type_id: TypeId = null,                  // 16..24
    node: std.DoublyLinkedList.Node = .{},   // 24..40
};

const Job = struct {
    node: std.DoublyLinkedList.Node = .{},   // 0..16
    type_id: TypeId = null,                  // 16..24
    id: u32,
};
```

Both Parents use `DoublyLinkedList.Node`, so both can share one list.
After `popFirst()` the program holds a `*DNode` that lives in a `Job` at `A`.

```text
MessageInfo.parentFromNode(node)
  parent  = A - 24          // Message's Node offset
  type_id = parent + 16     // = A - 8, before Job starts
```

The check reads memory outside the `Job`.
It usually reports "no match", so the bug is invisible.
The read itself is undefined behaviour.

Comptime knows the Node kind.
It does not know which Parent owns this particular Node.
The check must read the TypeId before the Parent type is known.

The fix is to make the Node and the TypeId one type: the Link.
A Link is a single Zig type, so its layout is chosen once.
From any Node inside a Link, `@fieldParentPtr("node", node)` finds the Link,
and the Anchor is always at the right place,
whichever Parent contains the Link.

Matryoshka-ztk's `Inner { node, id }` already followed this rule.

## Why not an offset in `Info`

`Info(Message)` could store "the TypeId is 16 bytes after the Node in a
`Message`". That is a true fact about `Message`.

It does not help.
`parentFromNode` is needed exactly when the owner of the Node is unknown.
To find out, the check must read a TypeId.
To read it, it needs its address.
The address depends on the owner's layout,
and the owner is what the check is trying to find out.

`MessageInfo` can only compute where the TypeId would be
*if this were a Message*.
For a Node inside a `Job`, that address is some field of the Job,
or outside it.

The check needs one rule that holds for every Parent on the container:

> From any Node, the TypeId is always at the same place.

A per-Parent comptime check of that distance fails in practice.
Parents are auto-layout, so the compiler may reorder their fields.
An `extern` Parent would fix the order, but an extern struct cannot contain a
std Node.

Link is the only way Zig allows.
Node and Anchor are one type, and a type's layout is chosen once.
Every Parent embeds the same `SLink` or `DLink`,
so the Node-to-Anchor distance is identical in all of them,
by construction rather than by convention.

If a container holds only one Parent type, there is no unknown owner,
and plain `@fieldParentPtr` is enough.
Paternitas exists for the heterogeneous case.

The same argument covers `nextField`:
the Anchor-to-`next` distance is a property of the Link, not of each Parent.

---

# Anchor

```zig
pub const Anchor = struct {
    type_id: TypeId = null,

    pub fn info(a: *const Anchor) ?*const TypeInfo;   // null when unstamped
    pub fn toAny(a: *Anchor) ?AnyParent;              // null when unstamped
};
```

The Anchor is the only concrete, stable struct in Paternitas.

The Anchor is not the object.
The Parent is the object.
The Anchor is one small marker inside the Parent,
and its address is the erased reference to the Parent.

`*Anchor` is the erased reference to a Parent.
It is one word and it describes itself:
the address says where the Parent is,
the stamped value says what it is.

**Why not `extern`.**
Nothing in the code relies on the Anchor's layout.
`info()` reads `type_id` by name;
`nextField` and `parent` compute addresses from `@offsetOf(Link, "anchor")`.
A plain struct already gives a distinct type:
`*Anchor` is not `*TypeId`, so a stray `*?*const anyopaque` cannot be passed
where an Anchor is expected.

`extern` would add one thing: an Anchor that can sit inside a user's
`extern struct` or cross a C ABI.
The day that is needed, it is a one-word change and breaks nothing.

The Anchor has no chain or location API of its own.
Those live in `TypeInfo`, which knows the offsets.

## Who uses what

The package has two public levels:

```text
paternitas              application API
paternitas.container    TypeInfo, NodeKind, uniform_next_offset
```

Zig has no package-private visibility, and autodoc shows every public
declaration reachable from the root.
A library built on Paternitas, in another package, must be able to call
`TypeInfo.nextField`, so `TypeInfo` cannot be internal.
The separate namespace states its audience instead,
and autodoc gives it a page of its own.

* **Application code** uses `Info(P)`, the Link types, `*Anchor` as a value,
  `AnyParent`, and `Anchor.toAny()`.
  It never touches `TypeInfo`.
* **Container authors** use `Anchor.info()` and `TypeInfo`:
  `nextField`, `parent`, `node`, and the offsets.
* **A library built on Paternitas**, such as Matryoshka, wraps `Info(P)`
  in its own typed helper. Its users then see Paternitas only through the
  types.

`Anchor.toAny()` exists so that a consumer holding a bare `*Anchor` of
unknown type can dispatch without reaching into `TypeInfo`.

---

# TypeId and TypeInfo

`TypeInfo` and `NodeKind` live in `paternitas.container`.

```zig
pub const TypeId = ?*const anyopaque;

pub const NodeKind = enum { single, double };

pub const TypeInfo = struct {
    name: []const u8,
    anchor_offset: usize,      // Parent start -> Anchor
    node_next_offset: isize,   // Anchor -> Node.next
    node_kind: NodeKind,

    pub fn nextField(ti: *const TypeInfo, a: *Anchor) *?*anyopaque;
    pub fn parent(ti: *const TypeInfo, a: *Anchor) *anyopaque;
    pub fn toAny(ti: *const TypeInfo, a: *Anchor) AnyParent;
    pub fn node(ti: *const TypeInfo, a: *Anchor, comptime N: type) *N;
};
```

For each Parent type, `Info(Parent)` holds one `const TypeInfo`.

The TypeId is the address of that `TypeInfo`.

The address is the identity.

## Fields

* `name` — `@typeName(Parent)`, for panic and log messages
* `anchor_offset` — from the Parent start to its Anchor
* `node_next_offset` — from the Anchor to the Node's `next` field;
  signed, because the Node may sit before the Anchor
* `node_kind` — `.single` or `.double`

`name` also keeps descriptors distinct.
The compiler may merge identical constants;
two Parent types never share a name, so they never share a descriptor.
Do not remove `name` to save bytes.

## `nextField`

```zig
pub fn nextField(ti: *const TypeInfo, a: *Anchor) *?*anyopaque;
```

Returns the address of the Node's `next` field, for either Node kind.

Location only.
Paternitas never reads or writes this word.

It is typed `*?*anyopaque`, not `*?*Anchor`:
what a container stores in the word is the container's decision.
A std list stores Node pointers.
Matryoshka stores Anchor pointers.

This is mechanism, not policy.
Paternitas says where the word is.
It does not say what null means, what a self-pointer means,
or who may write the word.

One fact is part of the contract:

> The `next` word is shared storage.
> A std list writes it while the Parent is in that list.
> A container that chains through `nextField` must not use the Parent
> while it is in a std list, and the other way round.

## `parent`

```zig
pub fn parent(ti: *const TypeInfo, a: *Anchor) *anyopaque;
```

The Parent address, erased, via `anchor_offset`.

For code that must hand the raw object to something that knows nothing
about Paternitas, such as a C callback's `void*` user data.

## `toAny`

```zig
pub fn toAny(ti: *const TypeInfo, a: *Anchor) AnyParent;
```

Builds the dispatch view of the Parent behind this Anchor.
See AnyParent.

## `node`

```zig
pub fn node(ti: *const TypeInfo, a: *Anchor, comptime N: type) *N;
```

The Node, typed.
Panics in every build mode if `N` does not match `node_kind`.
A wrong kind would reinterpret memory as the wrong Node type.

## Identity rules

A TypeId is a static type identity.

It is not:

* an object address
* a Node address
* an instance identifier
* a lifetime token
* a list-membership token

All instances of one Parent type share one TypeId.

There is no need for integer type numbers, a global registry,
registration tables, or runtime allocation.

The TypeId is valid only inside one running binary.
It is not a persistent or serialized identifier.
A TypeId passed across a dynamic library or plugin boundary
may not compare equal for the same type.

An unstamped Anchor holds `null`.
`null` never matches any Parent.
Zeroed memory is therefore a valid unstamped Anchor.
An unstamped Anchor has no `TypeInfo`, so it has no `nextField` either:
a container must check the stamp before touching the chain word.

---

# Link

```zig
pub fn Link(comptime N: type) type;   // struct { node: N = .{}, anchor: Anchor = .{} }

pub const SLink = Link(std.SinglyLinkedList.Node);
pub const DLink = Link(std.DoublyLinkedList.Node);
```

Link is comptime glue.
The user embeds `SLink` or `DLink` once in a Parent.
Nobody calls into it.

The Node inside is the unmodified standard Node.
Paternitas does not replace it and does not provide its own list.

## Field order and the uniform offset

Field order is declared `node`, then `anchor`.

The std Nodes are auto-layout, so a Link cannot be `extern`:

```text
error: extern structs cannot contain fields of type 'SinglyLinkedList.Node'
note: struct with automatic layout has no guaranteed in-memory representation
```

The compiler may reorder the fields.
Paternitas does not depend on the order for correctness:
every offset is computed at comptime.

The order still matters for speed.
`next` is the last word of both std Nodes.
With the Anchor after the Node, the `next` word is at the same offset from the
Anchor for both kinds.
On Zig 0.16.0, in Debug, ReleaseSafe, ReleaseFast and ReleaseSmall:

```text
SLink.node_next_offset = -8
DLink.node_next_offset = -8
```

Paternitas checks this at comptime:

```zig
pub const uniform_next_offset: ?isize =
    if (SLink.node_next_offset == DLink.node_next_offset) SLink.node_next_offset else null;
```

When it holds, `nextField` adds a constant and never loads `TypeInfo`.
When a future compiler breaks it, `nextField` falls back to
`ti.node_next_offset`: still correct, one load slower.
A test pins `uniform_next_offset != null`,
so a layout change shows up as a failing test, not a silent slowdown.

---

# Migration

Paternitas defines the struct that holds the Node.
Existing intrusive code changes by one field per Parent.

Before:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    text: []const u8,
};
```

After:

```zig
const Message = struct {
    link: paternitas.DLink = .{},
    text: []const u8,
};
```

Direct accesses change from `message.node` to `message.link.node`,
or to `MessageInfo.node(&message)`.

Nothing else changes.
Standard lists, their operations, and their Node type stay as they are.

## Initialize before stamping

`allocator.create(Parent)` returns undefined memory.
The Link's default `.{}` is applied only when the Parent is constructed
with an initializer.

```zig
const m = try allocator.create(Message);
m.* = .{ .text = "hello" };   // Link becomes .{}
MessageInfo.stamp(m);
```

`stamp` does not repair an uninitialized Link.

---

# Required Parent shape

A Paternitas Parent is a struct with exactly one `SLink` or `DLink` field.

There is no required field name and no required position.
The Link is found by its type, among top-level fields.

```text
not a struct      -> compile error
zero Links        -> compile error
one Link          -> accepted
more than one     -> compile error
```

Each compile error names the Parent type.

A Parent may contain other plain standard Nodes for other lists.
Those are not Paternitas relationships and are ignored.
`parentFromNode()` must never be used on them.

---

# `Info(Parent)`

```zig
const MessageInfo = paternitas.Info(Message);
```

At comptime it finds the single Link, builds the `TypeInfo`,
and generates typed operations for this exact Parent.

```text
typeId()                      -> TypeId
isId(TypeId)                  -> bool
stamp(*P)                     -> void
anchor(*P)                    -> *Anchor
node(*P)                      -> *Node
is(*Node)                     -> bool
fromAnchor(*Anchor)           -> ?*P
mustFromAnchor(*Anchor)       -> *P
toAny(*P)                     -> AnyParent
fromAny(AnyParent)            -> ?*P
parentFromNode(*Node)         -> ?*P
mustParentFromNode(*Node)     -> *P
parentFromNodeUnchecked(*Node)-> *P
```

`Node` is the Node type of the Parent's Link.
Passing another Node kind, or another Parent type, does not compile.

## `typeId`, `isId`

`typeId()` is the address of this Parent's `TypeInfo`.
It is the only source of a Parent's TypeId.

`isId(id)` compares a bare TypeId with it,
for code that holds a TypeId without an object:
a pool asked for "a `Message`", a count of Parents by type.

## `stamp`

Writes `TypeId(P)` into the Anchor.
Writes nothing else.
It does not touch the Node, so stamping a Parent that is already linked
is safe.

A Parent must be initialized before `stamp`,
and stamped before its Node or Anchor crosses a type-erased boundary.

## `anchor`, `node`

The Anchor and the Node inside this Parent's Link.

## `fromAnchor`, `mustFromAnchor`

```text
*Anchor
   |  read type_id, compare with TypeId(P)
   +-- mismatch -> null
   |  @fieldParentPtr("anchor") -> Link, @fieldParentPtr(link field) -> Parent
   v
*P
```

`mustFromAnchor` panics on a mismatch in every build mode.
The message names the type asked for and the type found:

```text
mustFromAnchor: asked for app.Message, found app.Job
mustFromAnchor: asked for app.Message, found <unstamped>
```

## `toAny`, `fromAny`

`toAny(p)` builds the dispatch view of `p`.

`fromAny(any)` compares `any.type_id` with `TypeId(P)`.
On a match it casts `any.ptr` to `*P`; on a mismatch it returns `null`.
Where runtime safety is on, it also checks that the Parent's Anchor
is stamped as `P`.

## `parentFromNode` and its forms

```text
*Node
   |  @fieldParentPtr("node")    -- Link layout, same for every Parent
   v
Link
   |  read anchor.type_id, compare with TypeId(P)
   +-- mismatch -> null
   |  @fieldParentPtr(link field) -- Parent layout, only after the match
   v
*P
```

The unchecked read depends only on the Link layout.
The Parent layout is used only after the type is confirmed.

`mustParentFromNode` panics on a mismatch, like `mustFromAnchor`.

`parentFromNodeUnchecked` skips the check.
The caller must already know the type.
The name makes that assumption visible.

## `is`

True if the Node's Anchor is stamped with `TypeId(P)`.

---

# Container rule for Nodes

`parentFromNode()`, `mustParentFromNode()` and `is()` read the Anchor
next to the Node.

> Every Node in a container on which these operations are used
> must live inside a Paternitas Link.

A bare standard Node in the same container makes the check undefined behaviour.

There is deliberately no function that goes from a Node to an Anchor
without a Parent type.
It would trust that any Node lives in a Link, and nothing in its signature
would say so.
Code that owns a std list knows what it put there:

```zig
const p = MessageInfo.parentFromNode(n) orelse ...;
use(MessageInfo.anchor(p));
```

---

# Containers of `*Anchor`

Intrusive containers carry Nodes.
Containers of pointers carry `*Anchor`.
The container stores a pointer value; the Parent stays where it is.

Copying a `*Anchor` copies a reference, not the Parent,
so a Parent that must not move can travel through any container of pointers.

As one variant among small copyable ones:

```zig
const Event = union(enum) {
    tick: u64,
    resize: Size,
    object: *paternitas.Anchor,
};
```

Or as the only element type:

```zig
var q: Queue(*paternitas.Anchor) = ...;
```

"No object" is `?*Anchor`.

Recovering the Parent:

```zig
if (MessageInfo.fromAnchor(a)) |m| { ... }
```

Checking an Anchor reads object memory: the Anchor word itself.
For a live object that is free.
For a stale reference it is undefined behaviour, as any later use would be.

## Versus tagged unions

```text
                  tagged union             *Anchor
set of types      closed, fixed in union   open, any Info Parent
identity          enum tag in element      static address in object
storage           largest variant + tag    one pointer
object            copied                   stays in place
lifetime          none required            Parent outlives every reference
recovery check    exhaustive switch        runtime TypeId compare
```

Tagged unions fit small, closed, copyable payloads.
`*Anchor` fits objects that must not move or be copied,
open sets of types, and existing intrusive code.
They combine: `*Anchor` can be one variant of a tagged union.

---

# AnyParent: the dispatch view

```zig
pub const AnyParent = struct {
    ptr: *anyopaque,   // the Parent
    type_id: TypeId,
};
```

Some consumers do not want Paternitas in their code.
They keep a map from TypeId to handler.
They receive an object, look up the handler by its TypeId,
and the handler casts the pointer to its own Parent type.

`*Anchor` serves them badly:
reaching the Parent needs `TypeInfo`.
`AnyParent` carries the Parent address directly.

```text
              *Anchor                       AnyParent
role          transport                     dispatch
used by       containers: chains, Slot,     the end consumer
              mailbox, pool
size          8 bytes, self-describing      16 bytes, pointer + type
type from     the Parent                    the handle
Parent from   TypeInfo                      ptr
```

Dispatch, with no Paternitas call in the hot path:

```zig
const Handler = *const fn (parent: *anyopaque) void;
var handlers: std.AutoHashMap(paternitas.TypeId, Handler) = ...;

// registration: the only Paternitas touch
try handlers.put(paternitas.Info(Message).typeId(), onMessage);
try handlers.put(paternitas.Info(Job).typeId(), onJob);

fn onMessage(p: *anyopaque) void {
    const m: *Message = @ptrCast(@alignCast(p));
    ...
}

// dispatch
const h = handlers.get(any.type_id) orelse return error.UnknownType;
h(any.ptr);
```

The map does the type check.
The handler for `Message` is registered under `Message`'s TypeId,
so its cast is correct by construction.

> The handler's cast is unchecked.
> A wrong registration is a wrong cast, and nothing catches it.
> `Info(P).fromAny` is the checked alternative.

## Where AnyParent comes from

```text
mailbox --> *Anchor --a.toAny()--------> AnyParent --> handler(ptr)
typed code --> *P  --Info(P).toAny(p)-----> AnyParent
```

`AnyParent` is one-way.
There is no conversion from `AnyParent` back to `*Anchor`.
At the dispatch site the Anchor is still in hand,
and code that forwards or returns the Parent keeps it.
A typed handler that knows its Parent uses `Info(P).anchor(p)`.

## `ptr` is mutable

`ptr` is `*anyopaque`, not `*const anyopaque`.
Every `AnyParent` is built from a mutable `*P` or a mutable `*Anchor`,
so the address always came from mutable memory.
A const field would force every handler to write `@constCast`,
which is exactly the Paternitas detail these consumers want to avoid.

`toAny` must never be relaxed to accept `*const P`.

## Ownership

`AnyParent` is a view, like `*Anchor` a reference.
Copies are aliases.
The Parent must outlive every copy.

---

# Bridge between intrusive containers and containers of `*Anchor`

```text
std list Node --Info(P).parentFromNode--> *P --Info(P).anchor--> *Anchor --> queue

queue --> *Anchor --Info(P).fromAnchor--> *P --Info(P).node--> std list Node
```

Dispatch, without `P`:

```text
*Anchor --a.toAny()--------> AnyParent --> handler(ptr)
```

Erased code that does not know `P`, but knows the Node kind it wants:

```text
*Anchor --a.info().node(N)--> *N
```

---

# Checks

Paternitas has two kinds of runtime checks.

**Type recognition** is part of the API.
`fromAnchor`, `fromAny`, `parentFromNode`, `is` return `null` or `false` on a mismatch,
in every build mode.
The `must` forms and the Node-kind check in `TypeInfo.node`
panic in every build mode.

**Contract checks** catch misuse.
They panic where runtime safety is on and are compiled out elsewhere.

Contract checks do not use `std.debug.assert`.
In ReleaseFast and ReleaseSmall `assert` becomes `unreachable`,
so a broken contract becomes undefined behaviour the optimizer may reason from.
Paternitas uses a check that leaves nothing behind instead:

```zig
inline fn check(ok: bool, msg: []const u8) void {
    if (std.debug.runtime_safety and !ok) @panic(msg);
}
```

Same policy as Matryoshka-ztk's `internal/check.zig`.
Internal, not exported.

---

# Two levels of type safety

Compile time, through `Info(P)`:

```text
Parent type
Node kind
```

Runtime, after erasure:

```text
Anchor.type_id -> which Parent
TypeInfo       -> where its Anchor, Node and next word are; its name
```

---

# What TypeId does not prove

## Pointer validity

Type identity, not memory validity.
It does not make valid a freed Parent, unrelated memory,
a corrupted Node address, or a stale `*Anchor`.

> The Parent must remain alive while its Node address,
> or any copy of its `*Anchor` or `AnyParent`, is in use.

## List membership

Paternitas does not know whether a Node is linked,
in which list, or available.
It never reads Node contents.
Linkage conventions differ:
std lists end a chain with `null`;
Matryoshka ends its chains with a self-pointer.
Paternitas supports both by reading neither.

## Synchronization

No mutexes, atomics, memory ordering, thread ownership,
or lifetime synchronization.

---

# Ownership

Paternitas does not define ownership.

`*Anchor` is a reference.
Copies are aliases of one Parent.
The application decides who owns and frees the Parent.

Containers that need stricter rules build them on top.
Matryoshka keeps one owner per item through its `Slot`.
A simple user gets none of these rules and needs none of them.

---

# Heterogeneous intrusive structures

```zig
const Message = struct {
    link: paternitas.DLink = .{},
    text: []const u8,
};

const Job = struct {
    id: u32,
    link: paternitas.DLink = .{},
};

const MessageInfo = paternitas.Info(Message);
const JobInfo = paternitas.Info(Job);

var list: std.DoublyLinkedList = .{};
list.append(MessageInfo.node(&message));
list.append(JobInfo.node(&job));

while (list.popFirst()) |node| {
    if (MessageInfo.parentFromNode(node)) |m| {
        processMessage(m);
        continue;
    }
    if (JobInfo.parentFromNode(node)) |j| {
        processJob(j);
        continue;
    }
}
```

The list is unaware of `Message` and `Job`.
The different Link positions in the two Parents do not matter.

An SNode Parent and a DNode Parent cannot share one std list.
They can share one container of `*Anchor`,
and one Matryoshka chain through `nextField`.

---

# Why not multiple Links

A Parent may need several intrusive relationships:
a ready list, a timeout list, a free list.

These are different relationships.
Guessing one would make the API ambiguous.

The core design allows exactly one Link.
Additional plain standard Nodes are allowed but not recognized by Paternitas.
Named multi-Link relationships are outside the core design.

---

# Non-goals

Paternitas does not provide:

* a linked list, queue, mailbox, pool, Slot, or scheduler
* ownership or move discipline
* lifetime management or synchronization
* allocation or destruction of Parents
* general RTTI or a global registry
* type identity for arbitrary non-Parent types
* linkage state (`isLinked`, `unlink`) or chain conventions
* Node initialization, linking, unlinking, or content processing
* a Node-to-Anchor conversion without a Parent type
* an AnyParent-to-Anchor conversion
* a lookup from a bare TypeId to its `TypeInfo`

No allocation anywhere.
The Parent can be stack, static, heap, custom-allocator, pool,
or embedded in another object.

Paternitas depends only on `std`.
Matryoshka depends on Paternitas, not the other way round.

---

# API

```zig
// ---- paternitas: application API

// Identity
pub const TypeId = ?*const anyopaque;

// Stamped word inside every Parent
pub const Anchor = struct {
    type_id: TypeId = null,

    pub fn toAny(a: *Anchor) ?AnyParent;                       // dispatch, type unknown
    pub fn info(a: *const Anchor) ?*const container.TypeInfo;  // container authors
};

// The type name behind an Anchor, or "<unstamped>". For panic and log text.
pub fn nameOf(a: *const Anchor) []const u8;

// Dispatch view, one-way
pub const AnyParent = struct {
    ptr: *anyopaque,
    type_id: TypeId,
};

// Glue: Node + Anchor, embedded once in a Parent
pub fn Link(comptime N: type) type;   // struct { node: N, anchor: Anchor }
pub const SLink = Link(std.SinglyLinkedList.Node);
pub const DLink = Link(std.DoublyLinkedList.Node);

// Typed side, generated per Parent
pub fn Info(comptime P: type) type;
//   typeId() TypeId
//   isId(id: TypeId) bool
//   stamp(p: *P) void
//   anchor(p: *P) *Anchor
//   node(p: *P) *Node
//   is(n: *Node) bool
//   fromAnchor(a: *Anchor) ?*P
//   mustFromAnchor(a: *Anchor) *P
//   toAny(p: *P) AnyParent
//   fromAny(any: AnyParent) ?*P
//   parentFromNode(n: *Node) ?*P
//   mustParentFromNode(n: *Node) *P
//   parentFromNodeUnchecked(n: *Node) *P

// ---- paternitas.container: for container authors

pub const NodeKind = enum { single, double };

// Type description, one const per Parent type; its address is the TypeId
pub const TypeInfo = struct {
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
```

---

# Implementation

The package is `paternitas/`:

```text
paternitas/
  build.zig        module "paternitas", steps "test" and "negative"
  build.zig.zon    no dependencies, minimum Zig 0.16.0
  src/paternitas.zig
  negative/compile/   what does not compile
  negative/panic/     what aborts, in every build mode
```

`src/paternitas.zig` is the source of truth for the API above.
This document does not repeat the code.

Tested on Zig 0.16.0 in Debug, ReleaseSafe, ReleaseFast and ReleaseSmall.

`zig build test`, 9/9 in every mode:

* the uniform `next` offset holds
* distinct ids; `TypeInfo` fields and accessors
* an SLink Parent and a DLink Parent in one Anchor chain,
  then the DLink Parent into a `std.DoublyLinkedList` and back
* unstamped Parents
* stamping Parents that are already linked
* dispatch through a `TypeId -> handler` map, with no `Info` call at dispatch
* `toAny` / `fromAny`
* `*Anchor` and `AnyParent` inside a tagged union
* the fallback offset stored in `TypeInfo` lands on `next` for both kinds,
  and so does `nextField`

`zig build negative`, 11/11 in every mode.
A test cannot reach a compile error or assert a panic, so these are
programs.

Must not compile, with that message:

* a non-struct Parent
* a Parent with a bare std Node and no Link
* two Links
* a DNode passed where an SNode is expected

Must abort, in every build mode, and say why on stderr:

* `mustFromAnchor` on another type: names both types
* `mustParentFromNode` on an unstamped Parent: names `<unstamped>`
* `TypeInfo.node` with the wrong Node kind

---

# Matryoshka-ztk changes

This section lists what changes in Matryoshka-ztk
(`design/secondary/lang/port/3tk-to-ztk/next/ztk/src`)
when it is built on Paternitas.

## Vocabulary

The ztk API now uses Zig's word: **parent**, the struct that embeds the
Link, as in `@fieldParentPtr`.
`OuterHelper` becomes `ParentHelper`, `OuterId` becomes `TypeId`.
Panic texts, doc comments, test and example names follow.

The Matryoshka model and the conceptual pages keep their own words:
the parent is the outer doll; parent, then Link, then Anchor.
ztk's `inner.zig` and README say so in one line.

**Item** keeps its meaning as a role, not a type:
an item is a parent while it is in a mailbox, a queue or a pool.
Prose and test or example names keep it
("the pool's items", `mailbox_as_item`, `sendItems`).

In code, what a container holds is an `*Anchor`, and the names say so:

* parameters and locals of type `*Anchor` are named `anchor`, not `item`
* `Mbox.Result` and `Pool.Result` carry `.anchor`, not `.item`
  (user code: `result.item` becomes `result.anchor`)
* locals of type `*Parent` are named `parent`
* the examples' folder of sample parent types is `examples/parents/`
  (`parents.Event`, `parents.Sensor`), formerly `examples/items/`

The rename was made now, in the same break as the Paternitas migration,
so ztk users migrate once.

## Principle

Paternitas is mechanism. Matryoshka is policy.

```text
Paternitas                               Matryoshka
----------                               ----------
TypeId, TypeInfo, Anchor                 Slot: one owner per item
SLink, DLink                             chain convention: self-pointing tail,
Info: stamp, anchor, node, is,             isLinked, unlink
  fromAnchor, parentFromNode             Queue, stack, Mbox, Pool
TypeInfo.nextField: where next is        what goes in next
contract-check policy                    create / destroy, init / finish hooks,
                                           allocator, Io, border checks
```

## Currency

The Matryoshka currency changes from `*Inner` to `*Anchor`.

```text
Inner { node: SNode, id }        -> the parent embeds paternitas.SLink or DLink
OuterId                          -> TypeId (alias of paternitas.TypeId)
Slot = ?*Inner                   -> Slot = ?*Anchor
AnyOuter { ptr, id }             -> removed; ?*Anchor for transport,
                                    AnyParent at the dispatch edge
OuterInfo { name, inner_offset } -> paternitas.TypeInfo
```

The word `Inner` leaves the API.
A parent contains a Link.
Containers hold Anchors.
Keeping `Inner` as an alias for `Anchor` would mix two pictures;
dropping it is cleaner.

## What users gain

A parent may carry a `DLink`.
The same object can sit in the application's own `std.DoublyLinkedList`
(a timeout list, an LRU list with O(1) removal)
and move through Matryoshka mailboxes and pools, one place at a time.

SLink and DLink Outers mix freely in one mailbox and one pool.

## File by file

### `internal/info.zig` — removed

`OuterInfo` and `infoOf` are replaced by `paternitas.TypeInfo` and
`Anchor.info()`.

### `internal/check.zig` — unchanged

Same policy as Paternitas; each package keeps its own copy.

### `inner.zig`

* `Inner` removed.
* `OuterId` renamed to `TypeId`, an alias of `paternitas.TypeId`.
* `Slot = ?*paternitas.Anchor`.
* `AnyOuter` removed.
  A foreign container of pointers stores `*Anchor`,
  taken from a Slot with `takeFromSlot` and returned with `fillSlot`.
  Move-only discipline stays with the Slot:
  a copied `*Anchor` is an alias, exactly as a copied `AnyOuter` was.
* `takeFromSlot`, `fillSlot` work on `*Anchor`. Same checks.
* `ofNode` removed. The typed way across the std-list border is
  `ParentHelper.node` and `ParentHelper.fromNode`.
* `SLink`, `DLink`, `Anchor`, `AnyParent` re-exported from Paternitas.
* `anyFromSlot(slot) ?AnyParent` — the dispatch edge.
  A view of the parent in the Slot; the Slot stays full.
  Built on `Anchor.toAny()`.
  A handler-map consumer never touches `TypeInfo`.
* The chain word, over Anchors:

```zig
pub inline fn next(a: *Anchor) *?*Anchor {
    const ti = a.info() orelse @panic("chain: the parent was never stamped");
    return @ptrCast(ti.nextField(a));
}

pub inline fn isLinked(a: *Anchor) bool {
    if (a.type_id == null) return false;   // unstamped: on no chain
    return next(a).* != null;
}

pub inline fn unlink(a: *Anchor) void {
    next(a).* = null;
}
```

`next` is the one type pun in the toolkit, and says so in its comment:
the word is declared by std as a Node pointer and holds an `*Anchor`
while the parent is on a chain.
It relies on Zig doing no type-based alias analysis.

`next` panics in every build mode on an unstamped Anchor:
without an id there is no description, and so no `next`.
`isLinked` answers false for an unstamped parent, as before:
every insert refuses one, so it cannot be on a chain.

### `helper.zig`

`OuterHelper(Outer)` becomes `ParentHelper(Parent)`.
It wraps `paternitas.Info(Parent)`.

```text
ID                -> Info(Parent).typeId()
isIt(id)          -> Info(Parent).isId(id)
stamp             -> see below
toInner           -> toAnchor = Info(Parent).anchor
fromInner         -> fromAnchor = Info(Parent).fromAnchor
mustFromInner     -> mustFromAnchor = Info(Parent).mustFromAnchor
fromSlot, mustFromSlot, moveFromSlot, mustMoveFromSlot
                  -> same, over ?*Anchor
toAny, fromAny    -> Info(Parent).toAny, Info(Parent).fromAny (AnyParent)
isLinked          -> inner.isLinked(anchor)
create, destroy   -> same, see stamp
innerFieldName    -> removed; Paternitas finds the Link
wrongType         -> uses paternitas.nameOf(anchor)
(new) Node, node(self), fromNode(n)
                  -> Info(Parent).node, Info(Parent).parentFromNode:
                     the typed std-list border
```

The Link search accepts `SLink` and `DLink`.

**stamp.**
Paternitas `stamp` writes only the Anchor.
ztk's `stamp` also reset the Node, and `create` relies on it,
because `allocator.create` returns undefined memory.
`create` now initializes the Link itself:

```zig
const parent = try allocator.create(Parent);
errdefer allocator.destroy(parent);
try parent.init(allocator, io);
@field(parent.*, link_field) = .{};   // fresh Node, unstamped Anchor
Info(Parent).stamp(parent);
```

Matryoshka's public `stamp` for user-allocated Outers keeps the ztk meaning,
"make this fresh parent usable": reset the Link, then `Info(Parent).stamp`.
Paternitas `stamp` alone is for Parents that may already be linked.

### `queue.zig`

`Queue` chains `*Anchor` through `inner.next(a)`.

```zig
pub fn append(self: *Queue, anchor: *Anchor) void {
    self._guardInsert(anchor);
    next(anchor).* = anchor;                          // self-pointing tail
    if (self._tail) |t| next(t).* = anchor else self._head = anchor;
    self._tail = anchor;
    self._count += 1;
}
```

`popFirst`, `concat`, `countOfId` follow the same pattern.
`countOfId` compares `anchor.type_id`.
The `&item.node` / `ofNode` round trips disappear.

**Public change:** `Queue` becomes a queue of `*Anchor`.
Code that drains `Mbox.receiveAll`, `Mbox.close`, `Pool` hooks
(`on_put`'s `extra`, `on_close`'s `remaining`)
recovers items with `fromAnchor` instead of `fromInner`.

### `internal/stack.zig`

`InnerStack` becomes `AnchorStack`.
Same change as the queue: chains `*Anchor` through `next`.

### `mbox.zig`

* Chains through `_oob` and `_regular` (`Queue`), so it inherits the queue
  change.
* `item.id` becomes `anchor.type_id`.
* `send`, `receive`, `tryReceive` keep their signatures;
  `Slot` changed underneath.
* `receiveAll`, `close` return a `Queue` of Anchors.
* Optional, for dispatch consumers: a receive form that hands out
  `AnyParent` instead of filling a Slot,
  so a handler-map user never sees an Anchor.
  The move-only rule then ends at that edge:
  the mailbox gives up the item, the consumer owns it.
* `Mbox` is itself a parent (mailbox as item):
  it embeds an `SLink` instead of an `Inner`.

### `pool.zig`

* Chains through `bucket.free` (`AnchorStack`) and through `Queue`s in
  `put` and `close`, so it inherits both changes.
* Buckets stay keyed by TypeId. `item.id` becomes `anchor.type_id`.
* `get(want: TypeId, ...)` unchanged in meaning.
* `Hooks` signatures change only through `Queue` and `Slot`.
* `Pool` is itself a parent: it embeds an `SLink`.

### `matryoshka.zig`

Re-exports `paternitas` so users write one import,
or documents it as a separate dependency.

### Docs and examples

Mechanical renames:
`fromInner` → `fromAnchor`, `toInner` → `toAnchor`,
`Inner` field → `SLink` or `DLink` field,
`AnyOuter` examples → `*Anchor` examples.

New examples worth adding:
a `DLink` parent kept in a user's timeout list,
moved into a mailbox, received, and put back into the list;
and a handler-map consumer dispatching `AnyParent`s from a mailbox.


### Tests, examples, negatives

* Mechanical renames across tests and examples.
* `tests/layer1_any.zig` rewritten as scenarios 320–327:
  takeFromSlot/fillSlot, `anyFromSlot`, `toAny`/`fromAny`,
  a bare Anchor through `std.Io.Queue`, dispatch through a handler map,
  and a DLink parent sharing a queue with SLink parents,
  then a `std.DoublyLinkedList`, then back.
* Queue tests that looked at `node.next` now compare Anchors through
  `inner.next`.
* `examples/bridge/104` carries `*Anchor` instead of `AnyOuter`.
* `examples/layer1/098` crosses the std-list border with
  `node` / `fromNode`.
* Scenario 328: a DLink parent goes from a `std.DoublyLinkedList`
  (removed from the middle) to a Matryoshka queue and back to the std list.
* Scenario 329: on a chain, the Node's `next` word holds an Anchor;
  read through `nextField` and through the std field it overlays;
  null again after removal.
* Negative programs 320–322 (AnyOuter) replaced by
  321 `takeFromSlot` of an unstamped parent and
  322 `takeFromSlot` of a linked parent.
* New compile negative 314: a parent with a bare std Node and no Link.
* 306, 307 and 314 expect the Paternitas compile errors:
  "no Link, so it cannot be a Paternitas Parent" and
  "more than one Link, and exactly one is allowed".

### Build

`build.zig.zon` depends on `.paternitas = .{ .path = "../paternitas" }`.
`build.zig` adds the module to the `matryoshka` module.
`matryoshka.zig` does not re-export Paternitas.
A ztk user sees it only through the types in `inner`:
`SLink`, `DLink`, `Anchor`, `AnyParent`, `TypeId`.
`TypeInfo` is used privately in `inner.zig` and appears nowhere in ztk's
public surface.

## Rules that change in the Matryoshka docs

* "One item, one chain" now covers std lists too:
  the `next` word is shared between Matryoshka chains and std lists.
* An item returning from a std list arrives with a stale `next`
  and is refused at the border, as today.
  For a `DLink` item the stale `prev` is harmless:
  Matryoshka ignores it, and std rewrites both words on insert.
* While an item is on a Matryoshka chain, its Node's `next` holds a
  `*Anchor`, not a Node pointer.
  A debugger shows it as a "wrong" Node pointer.
  The code relies on Zig not doing type-based alias analysis,
  which it does not today.

## Costs

* One chain-word computation per link operation.
  With `uniform_next_offset` it is a constant add.
  Without it, one load from read-only data.
* One more dependency.

---

# The central invariant

For a stamped, live Parent:

```text
Parent
 |
 +-- Link
      |
      +-- node      contents belong to whoever links it
      +-- anchor.type_id == TypeId(Parent) --> TypeInfo(Parent)
```

For every `*Anchor` reference to that Parent:

```text
TypeInfo.parent(anchor) == address of Parent
```

---

# Short version

The Node is a standard Node.

The Node and the Anchor live together in a Link.

The Link can be anywhere in the Parent.

The Anchor is one stamped word.
Its address is the erased reference to the Parent: the transport currency.

AnyParent is the Parent address plus its TypeId: the dispatch view.

The TypeId is the address of a static TypeInfo:
name, Anchor offset, Node `next` offset, Node kind.

`TypeInfo` says where things are.
Containers decide what to do there.

The core operations are:

```text
*Node   -- Info(P).parentFromNode() --> checked *P
*Anchor -- Info(P).fromAnchor()     --> checked *P
*Anchor -- TypeInfo.nextField()     --> where a container may chain
*Anchor -- TypeInfo.toAny()         --> AnyParent for dispatch
```
