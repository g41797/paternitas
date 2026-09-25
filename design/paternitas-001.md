# Paternitas

Paternitas is a small Zig package for typed access to objects stored in
intrusive standard linked lists.

The name comes from the idea of a lost Parent being found again.

A list knows a Node.

A Node does not normally know its Parent.

Paternitas adds enough information to recognize the Parent and get back to it.

## The problem

Zig's current linked-list API uses intrusive nodes.

For example:

```zig
const Item = struct {
    value: u32,
    node: std.DoublyLinkedList.Node = .{},
};
```

The list stores the node.

```zig
var list: std.DoublyLinkedList = .{};
list.append(&item.node);
```

Later:

```zig
const node = list.popFirst().?;
```

The result is:

```zig
*std.DoublyLinkedList.Node
```

The relationship with `Item` is no longer present in the type.

The usual way back is:

```zig
const item: *Item = @fieldParentPtr("node", node);
```

This needs the programmer to know that the node belongs to `Item`.

With several types using the same list, this can become a footgun.

For example:

```zig
const A = struct {
    value: u32,
    node: std.DoublyLinkedList.Node = .{},
};

const B = struct {
    value: u8,
    node: std.DoublyLinkedList.Node = .{},
};
```

Both contain the same kind of Node.

Both Nodes can be put into the same standard list.

After getting a Node from the list, the Node itself does not say whether it came from `A` or `B`.

The compiler cannot check the `@fieldParentPtr` choice.

This problem was discussed in the Zig community in the
[New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853)
discussion. The example shows two different structs putting their nodes into
one list and then recovering the wrong Parent type.

Paternitas addresses this particular gap.

## The idea

The user keeps using the standard Zig list.

No replacement list.

No new list API.

No wrapper around every list operation.

The user's Parent contains:

```zig
const Item = struct {
    value: u32,

    node: std.DoublyLinkedList.Node = .{},
    type_id: TypeId = null,
};
```

There are two pieces:

```text
Parent
 |
 +-- Node
 |
 +-- TypeId
```

The Node is the standard Zig Node.

The TypeId identifies the Parent type.

The user continues to work with:

```zig
std.SinglyLinkedList
```

or:

```zig
std.DoublyLinkedList
```

Paternitas starts working when the user gets a Node back from the list.

```text
std list
   |
   | get Node
   v
 Node
   |
   | Paternitas helper
   v
 recognize
   |
   v
 Parent
```

## The mask

A Node can be thought of as wearing a mask.

The list sees only the Node.

It does not need to know the Parent.

The TypeId is the mask.

Two Parents can have the same Node type:

```text
A ---- Node ----+
                |
                +---- std list
                |
B ---- Node ----+
```

The Node alone cannot tell them apart.

With Paternitas:

```text
A ---- Node + TypeId(A)
B ---- Node + TypeId(B)
```

Now a helper can ask:

```text
Is this Node an A?
```

The answer is a runtime TypeId comparison.

The actual Parent recovery is done only after the type matches.

## TypeId

The basic type is:

```zig
pub const TypeId = ?*const anyopaque;
```

It is an optional type-erased pointer.

`null` means no type.

A non-null value identifies a type.

The pointer is not used as a data pointer.

It points to a type descriptor.

Conceptually:

```text
TypeId
   |
   v
TypeInfo
```

The descriptor can contain more information than only identity.

For example:

```text
TypeInfo
 |
 +-- Parent type
 +-- Node field information
 +-- offset
 +-- Node kind
 +-- ...
```

The descriptor can grow later.

The public TypeId can stay small:

```zig
?*const anyopaque
```

The important property is address identity.

Two objects of the same Parent type use the same TypeId.

Different Parent types use different TypeIds.

The TypeId says what the object is.

It does not say which object it is.

## Parent

`Parent` is only a name used by Paternitas for the Zig struct containing the Node.

It does not mean a parent object in a data structure.

For example:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: TypeId = null,

    text: []const u8,
};
```

`Message` is the Parent.

The Node is embedded in it.

The TypeId identifies it.

Paternitas does not require the Parent to inherit from anything.

There is no base class.

There is no interface.

There is no virtual table.

## One helper per Parent

The important part of the design is the comptime helper.

The user gives Paternitas a Parent type.

Conceptually:

```zig
const MessageInfo = Paternitas(Message);
```

The helper examines `Message` at comptime.

It looks for:

* a `std.SinglyLinkedList.Node`, or
* a `std.DoublyLinkedList.Node`
* a `TypeId`

It then generates the required information and operations.

The user does not need to provide the Node field name.

The helper finds it by type.

This follows the same useful idea already used by Matryoshka-ztk.

The Matryoshka helper finds the `Inner` field by type rather than by field name. Zero or multiple matching fields are compile-time errors.

Paternitas applies the same approach to ordinary Zig list Nodes.

For example:

```zig
const MessageInfo = Paternitas(Message);
```

can know at comptime:

```text
Message
 |
 +-- node      : DoublyLinkedList.Node
 +-- type_id   : TypeId
```

and generate the relationship between them.

## Single and double linked lists

Zig has two different intrusive Node types.

Paternitas supports both.

```text
std.SinglyLinkedList.Node
std.DoublyLinkedList.Node
```

A Parent uses the Node it needs.

For a singly linked list:

```zig
const Message = struct {
    node: std.SinglyLinkedList.Node = .{},
    type_id: TypeId = null,

    text: []const u8,
};
```

For a doubly linked list:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: TypeId = null,

    text: []const u8,
};
```

The list itself remains the standard list.

Paternitas only adds recognition and recovery.

## Normal list code stays normal

The user can keep ordinary Zig code.

For example:

```zig
var list: std.DoublyLinkedList = .{};

list.append(&message.node);
list.append(&job.node);
list.append(&timer.node);
```

Paternitas does not replace these operations.

The list does not know about Paternitas.

It does not need to.

## Paternitas starts after the list gives back a Node

This is an important part of the design.

The user works with the list first.

```zig
const node = list.popFirst() orelse return;
```

Only now does Paternitas enter the picture.

The helper can check the Node:

```zig
if (MessageInfo.is(node)) {
    const message = MessageInfo.from(node);
    // use message
}
```

The exact API can change.

The important sequence does not:

```text
1. use std list
2. get Node
3. ask helper to recognize Node
4. recover Parent
```

Paternitas does not try to make the standard list typed.

It works at the point where the standard list deliberately gives the programmer a type-erased Node.

## Checked recovery

The safe path is:

```text
Node
 |
 +-- read TypeId
 |
 +-- compare with expected TypeId
 |
 +-- match
       |
       v
   recover Parent
```

Not:

```text
Node
 |
 +-- assume Parent
 |
 v
@fieldParentPtr(...)
```

The TypeId check comes first.

The descriptor provides the information needed for the conversion.

This is the main protection Paternitas adds.

## Compile-time work

Most of the work should happen at comptime.

For each Parent, the helper can determine:

```text
Parent
 |
 +-- supported Node?
 |       |
 |       +-- SinglyLinkedList.Node
 |       |
 |       +-- DoublyLinkedList.Node
 |
 +-- TypeId?
 |
 +-- Node field offset
 |
 +-- TypeId field offset
 |
 +-- Type descriptor
```

The helper then produces the small runtime operations needed for:

* getting the TypeId
* checking the Node type
* recovering the Parent
* converting a Parent to its Node
* other small related operations

The user should not have to maintain offsets by hand.

## Type descriptor

The TypeId points to a descriptor.

The descriptor is created for a Parent type.

Conceptually:

```text
Message
   |
   v
Message TypeInfo
   |
   +-- TypeId
   +-- Node information
   +-- offsets
```

The TypeId itself remains opaque.

The user compares it.

The helper knows how to use the descriptor.

This leaves room for more information later without changing the basic TypeId representation.

## No central registry

Paternitas should not need a global type registry.

There is no table like:

```text
1 -> Message
2 -> Timer
3 -> Job
```

The TypeId is a pointer.

The descriptor itself provides the type information.

This keeps the mechanism local to the types using it.

## No allocation

The basic mechanism should not require allocation.

A Parent contains its Node and TypeId.

The descriptor is static type information.

List operations remain the operations of the Zig standard library.

Paternitas adds no heap allocation just to identify a Node.

## No new list implementation

Paternitas should not become:

```zig
Paternitas.SinglyLinkedList
Paternitas.DoublyLinkedList
```

That would miss the point.

The existing standard lists are useful.

They are intrusive.

They give the programmer control over layout and operations.

Paternitas adds one missing piece:

```text
Node -> recognize -> Parent
```

## No Matryoshka dependency

Paternitas comes from work on Matryoshka.

The idea is extracted from that work.

But Paternitas is not part of Matryoshka.

It does not know about:

* Mbox
* Pool
* Slot
* PolyNode
* Matryoshka scheduling
* Matryoshka communication

It is a small Zig package for ordinary users of the standard linked lists.

## Relation to Matryoshka

The idea is closely related to the Matryoshka `Inner` machinery.

In Matryoshka-ztk, an `Inner` contains a standard singly-linked-list Node and an opaque type ID. The type ID identifies the outer type, and the type information also carries the offset needed to move between the erased representation and the outer object.

The current Matryoshka helper generates the boring type-specific machinery at comptime.

Paternitas takes the useful Zig part of that approach:

```text
standard Node
    +
TypeId
    +
comptime helper
    +
type descriptor
    =
recognized Parent
```

Then it stops there.

No Matryoshka runtime is needed.

## What Paternitas is for

Paternitas is useful when a program has a standard intrusive list containing
different Parent types.

For example:

```text
                 std.DoublyLinkedList
                         |
             +-----------+-----------+
             |           |           |
             v           v           v
           Node        Node        Node
             |           |           |
          Message       Job        Timer
```

The standard list only knows Nodes.

Paternitas lets the program recognize what is behind a Node.

## What Paternitas is not for

Paternitas is not:

* a new linked-list implementation
* a container library
* a scheduler
* a message queue
* a memory pool
* a general RTTI system
* a replacement for `@fieldParentPtr`
* a framework

It is a small layer around the standard intrusive list Node.

## The simple picture

Without Paternitas:

```text
Parent
   |
   v
 Node
   |
   v
std list
   |
   v
 Node
   |
   ?  Parent
```

With Paternitas:

```text
Parent
   |
   +-- Node
   |
   +-- TypeId
          |
          v
       TypeInfo


std list
   |
   v
 Node
   |
   v
 helper
   |
   | recognize
   v
 Parent
```

The Parent was not really destroyed.

The list only forgot about it.

Paternitas helps find it again.

## The name

**Paternitas** is about the relationship between a Node and its Parent.

The technical mechanism is TypeId.

The user-facing story is simpler:

> The Node lost its Parent.

> Paternitas helps find it again.

The Node wears a mask.

The list sees the mask.

The helper recognizes it.

The Parent is found.



===================================
Perplexity
===================================

The core idea is useful, but the current design overstates what the `TypeId` proves and leaves the most important memory-safety invariant implicit. The improved design should make three things explicit: the `TypeId` must be stored at a known location relative to the node, recovery must validate the exact node address, and the API must distinguish “recognized type” from “valid live object.”

```md
# Paternitas

Paternitas is a small Zig package for recovering the object that contains an
intrusive standard-library linked-list node.

It addresses a specific problem:

> A standard intrusive list stores a `Node`, but the returned node does not
> retain the compile-time type of the object that contains it.

Paternitas adds a small runtime type marker and comptime-generated metadata so
that a node can be recognized before its containing object is recovered.

## The problem

Zig's intrusive linked lists store nodes embedded inside user-defined objects:

```zig
const Message = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};
```

The list operates on the embedded node:

```zig
var list: std.DoublyLinkedList = .{};

list.append(&message.node);

const node: *std.DoublyLinkedList.Node =
    list.popFirst() orelse return;
```

At this point, the static type is only:

```zig
*std.DoublyLinkedList.Node
```

The relationship between the node and `Message` is no longer represented in the
type. The usual recovery operation is:

```zig
const message: *Message =
    @fieldParentPtr("node", node);
```

This is correct only when the programmer already knows that `node` belongs to
`Message`.

The compiler cannot detect this mistake:

```zig
const message: *Message =
    @fieldParentPtr("node", node); // May actually be a Job or Timer.
```

The problem becomes more significant when one list contains nodes embedded in
several different object types.

## The design

A Paternitas-compatible object contains:

1. A standard Zig linked-list node.
2. A type marker.
3. Any application-specific fields.

Example:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: paternitas.TypeId = null,

    text: []const u8,
};
```

The list remains a normal standard-library list:

```zig
var list: std.DoublyLinkedList = .{};

list.append(&message.node);
list.append(&job.node);
list.append(&timer.node);
```

Paternitas is used only after the list returns a node:

```zig
const node = list.popFirst() orelse return;

if (MessageInfo.is(node)) {
    const message = MessageInfo.from(node).?;
    // Use message.
}
```

The sequence is:

```text
1. Use the standard intrusive list.
2. Receive an erased Node.
3. Read and validate its Paternitas metadata.
4. Recover the containing object.
```

Paternitas does not replace or wrap the standard list.

## TypeId

The public type marker can remain small:

```zig
pub const TypeId = ?*const anyopaque;
```

`null` means that the object is not initialized for Paternitas.

A non-null value identifies a compile-time object type. It should point to a
static descriptor rather than to an object instance:

```text
TypeId
  |
  v
static TypeInfo
```

Conceptually, the descriptor contains:

```zig
const TypeInfo = struct {
    type_id: TypeId,
    node_kind: NodeKind,
    node_offset: usize,
    type_id_offset: usize,
};
```

The exact internal representation is an implementation detail. Users should
compare `TypeId` values only through the generated helper API.

A `TypeId` identifies a type, not an object instance. It does not prove that a
pointer is alive, currently linked, or owned by a particular list.

## Required layout

The helper must know where the marker is stored relative to the node.

The simplest supported layout is:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: paternitas.TypeId = null,

    text: []const u8,
};
```

The node and marker should be fields of the same containing struct.

The implementation must reject ambiguous layouts at compile time:

- No supported linked-list node.
- More than one supported linked-list node.
- No `TypeId` field.
- More than one `TypeId` field.
- A `TypeId` field with an incompatible type.
- A node or marker that cannot be addressed through the containing object.

Finding fields by type is preferable to requiring conventional field names.
This allows the following to work:

```zig
const Message = struct {
    payload: []const u8,
    links: std.DoublyLinkedList.Node = .{},
    runtime_type: paternitas.TypeId = null,
};
```

The generated helper can still expose explicit operations such as `nodePtr`,
`typeId`, `is`, and `from`.

## Generated helper

The public entry point can be:

```zig
const MessageInfo = paternitas.Info(Message);
```

For each parent type, the helper generates:

```zig
pub fn nodePtr(parent: *Message) *std.DoublyLinkedList.Node;
pub fn typeId(parent: *const Message) TypeId;
pub fn is(node: *const std.DoublyLinkedList.Node) bool;
pub fn from(node: *std.DoublyLinkedList.Node) ?*Message;
```

The exact return types may vary depending on the supported Zig version, but the
important distinction is:

- `is` performs recognition.
- `from` performs checked recovery.
- An unchecked operation should be explicit and separately named.

Example:

```zig
const MessageInfo = paternitas.Info(Message);

if (MessageInfo.is(node)) {
    const message = MessageInfo.from(node).?;
    process(message);
}
```

A convenience operation may combine both steps:

```zig
if (MessageInfo.tryFrom(node)) |message| {
    process(message);
}
```

Prefer `tryFrom` as the main user-facing operation because it communicates that
the conversion can fail.

## Checked recovery

The safe recovery path is:

```text
Node
  |
  | locate the containing object using generated metadata
  v
Parent candidate
  |
  | read the TypeId stored in that object
  v
compare with expected TypeId
  |
  +-- mismatch --> null
  |
  +-- match -----> Parent pointer
```

The type check must happen before the pointer is exposed as a successful
`*Parent`.

Conceptually:

```zig
pub fn tryFrom(node: *Node) ?*Parent {
    const parent: *Parent = recoverParent(node);

    if (parent.type_id != info.type_id) {
        return null;
    }

    return parent;
}
```

The implementation must document the assumptions behind `recoverParent`.
Pointer arithmetic and `@fieldParentPtr` are only valid when `node` is actually
the embedded node of a live `Parent`.

The `TypeId` check prevents recovering a `Job` as a `Message`, but it cannot
make an arbitrary invalid pointer safe. Paternitas is a type-recognition
mechanism, not a general memory-safety mechanism.

## Initialization and lifetime

The type marker must be initialized before the object is inserted into a list:

```zig
var message = Message{
    .text = "hello",
    .type_id = MessageInfo.typeId,
};

list.append(&message.node);
```

A constructor is preferable because it prevents accidental omission:

```zig
var message = MessageInfo.init(.{
    .text = "hello",
});
```

If the object is removed permanently or returned to a pool, the implementation
should provide a way to clear or invalidate the marker:

```zig
MessageInfo.deinit(&message);
```

The package should clearly document whether the marker is:

- initialized manually,
- initialized by `init`,
- cleared on removal,
- required to remain valid while the node is linked.

A node must not be reused or destroyed while it is still linked into a list.

## Type identity

Type identity should be based on the address of a descriptor with static
storage duration.

For one concrete parent type:

```text
Message -> one descriptor -> one TypeId
```

All `Message` instances use the same `TypeId`.

Different parent types use different descriptors:

```text
Message -> TypeId(Message)
Job     -> TypeId(Job)
Timer   -> TypeId(Timer)
```

There is no need for:

- A global registry.
- Integer type tags.
- Runtime allocation.
- Registration and deregistration.
- A central table mapping IDs to types.

The address identity is sufficient for equality within the running program.

Paternitas should not promise stable identity across processes, shared-library
boundaries, serialization, or separately compiled runtime environments unless
those cases are explicitly supported.

## Singly and doubly linked lists

The same design can support both standard intrusive node types:

```zig
std.SinglyLinkedList.Node
std.DoublyLinkedList.Node
```

Example:

```zig
const WorkItem = struct {
    node: std.SinglyLinkedList.Node = .{},
    type_id: paternitas.TypeId = null,

    operation: Operation,
};
```

And:

```zig
const WorkInfo = paternitas.Info(WorkItem);

var list: std.SinglyLinkedList = .{};

list.prepend(&work.node);

if (WorkInfo.tryFrom(list.popFirst() orelse return)) |item| {
    execute(item);
}
```

The helper should record the node kind at comptime and reject attempts to use a
`SinglyLinkedList.Node` helper with a doubly linked list node, or vice versa.

## API boundaries

Paternitas should provide only the operations needed to connect a standard
node with its containing object:

```text
Info(Parent)
  |
  +-- init
  +-- deinit
  +-- nodePtr
  +-- typeId
  +-- is
  +-- tryFrom
  +-- fromUnchecked
```

`fromUnchecked` may exist for performance-sensitive internal code, but it should
be clearly marked as unsafe or require an explicit name such as:

```zig
const message = MessageInfo.fromUnchecked(node);
```

The normal API should be checked:

```zig
const message = MessageInfo.tryFrom(node) orelse return;
```

Avoid adding:

- A replacement linked-list implementation.
- A container abstraction.
- A scheduler.
- A queue or mailbox.
- A memory pool.
- A general reflection system.
- A global runtime registry.
- A dependency on Matryoshka.

## Safety model

Paternitas provides a limited runtime guarantee:

> If the node points to a live Paternitas-compatible object and the object's
> marker has not been corrupted, `tryFrom` will reject nodes belonging to a
> different registered parent type.

It does not guarantee:

- That the node is linked into a particular list.
- That the node is currently linked at all.
- That the containing object is still alive.
- That the pointer is aligned or valid.
- That the marker was not overwritten.
- That concurrent list access is safe.
- That a node is not present in multiple lists simultaneously.

Concurrency, ownership, list membership, and object lifetime remain the
responsibility of the caller.

This distinction should be prominent in the documentation.

## Example

```zig
const std = @import("std");
const paternitas = @import("paternitas");

const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: paternitas.TypeId = null,

    text: []const u8,
};

const Job = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: paternitas.TypeId = null,

    id: u32,
};

const MessageInfo = paternitas.Info(Message);
const JobInfo = paternitas.Info(Job);

pub fn main() void {
    var message = Message{
        .text = "hello",
        .type_id = MessageInfo.typeId,
    };

    var job = Job{
        .id = 42,
        .type_id = JobInfo.typeId,
    };

    var list: std.DoublyLinkedList = .{};

    list.append(&message.node);
    list.append(&job.node);

    while (list.popFirst()) |node| {
        if (MessageInfo.tryFrom(node)) |item| {
            _ = item.text;
            continue;
        }

        if (JobInfo.tryFrom(node)) |item| {
            _ = item.id;
            continue;
        }

        // Unknown or invalid Paternitas object.
    }
}
```

## Relationship to Matryoshka

Paternitas extracts one narrow mechanism that is also useful in Matryoshka:

```text
standard intrusive Node
        +
opaque TypeId
        +
comptime-generated metadata
        =
checked recovery of the containing object
```

Paternitas should remain independent of Matryoshka and should not depend on its
scheduler, mailbox, pool, slot, or communication abstractions.

The relationship is conceptual and implementation-oriented, not an API
dependency.

## What Paternitas is

Paternitas is:

- A small layer over Zig's standard intrusive list nodes.
- A comptime helper for discovering node and marker fields.
- A runtime type-recognition mechanism.
- A checked path from an erased node to its containing object.
- A zero-allocation mechanism in its basic form.

## What Paternitas is not

Paternitas is not:

- A new linked-list implementation.
- A typed list container.
- A general-purpose RTTI framework.
- A replacement for `@fieldParentPtr`.
- A lifetime or ownership system.
- A concurrency abstraction.
- A memory-safety substitute.
- A serialization format.
- A dependency on Matryoshka.

## Short description

Paternitas helps recover the object that an intrusive list node came from.

The standard list sees only a `Node`.

Paternitas adds a type marker and comptime-generated metadata so the program can
recognize the containing object before recovering it.

```text
Parent
  |
  +-- Node
  +-- TypeId
       |
       v
   TypeInfo

standard list
  |
  v
Node
  |
  v
tryFrom
  |
  v
Parent or null
```

The node did not lose its parent permanently.

The list only erased the parent type.

Paternitas provides a small, explicit way to find it again.
``` 

The main conceptual correction is that `TypeId` should be presented as a **type check**, not as proof that the pointer is valid. That distinction will make the package’s safety claims more accurate and easier for experienced Zig users to trust.

=========================================================
Grok
=========================================================

```markdown
# Paternitas

Paternitas is a small Zig package that restores typed access to objects stored in
the standard intrusive linked lists.

The name comes from the idea of a lost Parent being found again.

A standard list knows only the Node.  
A Node does not know its Parent.  
Paternitas adds just enough information so that a Node can be recognized and the Parent recovered safely.

## The problem

Zig’s intrusive lists (`std.SinglyLinkedList` and `std.DoublyLinkedList`) store type-erased Nodes:

```zig
const Item = struct {
    value: u32,
    node: std.DoublyLinkedList.Node = .{},
};

var list: std.DoublyLinkedList = .{};
list.append(&item.node);

const node = list.popFirst().?; // *std.DoublyLinkedList.Node
```

The relationship to `Item` is gone. The usual recovery is:

```zig
const item: *Item = @fieldParentPtr("node", node);
```

This requires the programmer to know (and correctly remember) which Parent type owns the Node.  
When several different structs place their Nodes into the same list, the compiler cannot check the choice. This is a known footgun.

Paternitas solves exactly this gap.

## Design goals

- Work with the existing standard lists — no replacement list, no new container API.
- Zero allocation.
- No central type registry.
- Most work done at comptime.
- Minimal runtime cost (a pointer comparison + offset arithmetic).
- Safe by default; unchecked path available for hot code after verification.
- Support both `std.SinglyLinkedList.Node` and `std.DoublyLinkedList.Node`.

## Core idea

A Parent struct contains two things:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: Paternitas.TypeId = null,

    text: []const u8,
};
```

- `node` — the ordinary standard Node the list sees.
- `type_id` — an opaque identifier that says “this Node belongs to Message”.

Conceptually:

```
Parent
 ├── Node          (what the list sees)
 └── TypeId        (the mask that lets us recognize the Parent)
```

The list continues to work exactly as before.  
Paternitas only becomes active *after* the list returns a Node.

## TypeId

```zig
pub const TypeId = ?*const anyopaque;
```

- `null` means “no type information”.
- A non-null value is the address of a static type descriptor generated at comptime.
- Address identity is the only thing that matters: same Parent type → same TypeId.

The public TypeId stays a single optional pointer. The descriptor behind it can grow later without changing the user-facing type.

## The comptime helper

The user writes:

```zig
const MessageInfo = Paternitas(Message);
```

At comptime the helper:

1. Locates the single `std.SinglyLinkedList.Node` or `std.DoublyLinkedList.Node` field (by type, not by name).
2. Locates the `TypeId` field (by type).
3. Verifies there is exactly one of each; zero or multiple is a compile error.
4. Generates the static type descriptor and the small set of operations needed at runtime.

This is the same “find by type” approach used by Matryoshka for its `Inner` field.

## Generated API (per Parent)

```zig
const MessageInfo = Paternitas(Message);

// Recognition
MessageInfo.is(node: *const Node) bool

// Safe recovery (returns null if the TypeId does not match)
MessageInfo.from(node: *Node) ?*Message
MessageInfo.fromConst(node: *const Node) ?*const Message

// Unchecked recovery (for use after a successful is() or in trusted code)
MessageInfo.fromUnchecked(node: *Node) *Message
MessageInfo.fromConstUnchecked(node: *const Node) *const Message

// The other direction
MessageInfo.node(parent: *Message) *Node
MessageInfo.typeId() TypeId          // the static TypeId for this Parent
```

Typical usage after obtaining a Node from a standard list:

```zig
const node = list.popFirst() orelse return;

if (MessageInfo.is(node)) {
    const msg = MessageInfo.fromUnchecked(node);
    // use msg
} else if (JobInfo.is(node)) {
    const job = JobInfo.fromUnchecked(node);
    // ...
}
```

Or the shorter form:

```zig
if (MessageInfo.from(node)) |msg| {
    // ...
}
```

## Initialization of TypeId

The TypeId field must be set before a Node is inserted into a list that will later use recognition.

Recommended pattern:

```zig
var msg: Message = .{
    .text = "hello",
    .type_id = MessageInfo.typeId(),   // or MessageInfo.initTypeId(&msg)
};
list.append(&msg.node);
```

A convenience method can be provided:

```zig
MessageInfo.init(&msg);   // sets type_id and returns &msg.node
```

## Constraints (compile-time enforced)

- Exactly one Node field of either `std.SinglyLinkedList.Node` or `std.DoublyLinkedList.Node`.
- Exactly one `TypeId` field.
- The Parent must be a struct.
- No support for unions or opaque types as Parents.

## What Paternitas deliberately does *not* do

- It does not replace `std.SinglyLinkedList` / `std.DoublyLinkedList`.
- It does not allocate.
- It does not maintain a global type table.
- It does not require any base class, interface, or vtable.
- It is not a general RTTI system.
- It has no dependency on Matryoshka (the idea was extracted from it, but the packages are independent).

## The simple story

Without Paternitas:

```
Parent  →  Node  →  std list  →  Node  →  ??? Parent
```

With Paternitas:

```
Parent
 ├── Node
 └── TypeId  →  TypeInfo

std list  →  Node  →  helper.recognize  →  Parent
```

The list only forgot the Parent.  
Paternitas helps the Node find it again.

## The mask metaphor (kept intentional)

A Node can be thought of as wearing a mask.  
The list sees only the mask.  
The TypeId is the mark that lets the helper recognize who is behind it.  
Once recognized, the Parent is restored.

The visual story of the project logo is exactly this: two masked Zig mascots connected by a thin recognition thread.



