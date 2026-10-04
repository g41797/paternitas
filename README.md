
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/paternitas/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/linux.yml)
[![Windows](https://github.com/g41797/paternitas/actions/workflows/windows.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/windows.yml)
[![macOS](https://github.com/g41797/paternitas/actions/workflows/mac.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/mac.yml)
[![Deploy Documentation](https://github.com/g41797/paternitas/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/docs.yml)


---
_Paternitas_ makes **intrusive**, **type-erased** containers **safer** to use in Zig.

- A wrong type gives null, or a panic that names both types. Never garbage.
- Zig's std linked lists are such containers.


---

"Intrusive" and "type-erased" sound scary?

Do not leave. The next section explains both.

Read on. One day you will build your **first big Zig system**.

Then you will remember this strange name, and use **_Paternitas_**.

---

## Two words first

Zig's std lists are intrusive and type-erased.

- What the two words mean.
- What each one costs you.

### Intrusive

- A non-intrusive list wraps your item in its own node.
  - It stores a copy of your item.

```zig
const Job = struct {
    id: u32,
};
```

```text
non-intrusive
the container's node
+-------------------+
| next              |
| id                |
+-------------------+
```

- An intrusive list keeps its link inside your struct.
  - Its `node` field is the link:

```zig
const Job = struct {
    id: u32,
    node: std.DoublyLinkedList.Node = .{},
};
```

```text
intrusive
your struct
+--------------------+
| id                 |
| node  <-- the list |
+--------------------+
```

**What you get:**

- The list allocates nothing for each item.
- Nothing is copied. Your struct stays at its address.
  - A struct that must not be copied can still be in a list.
  - Examples: it has a mutex, other code points into it, or it is too
    large to copy.

**What it costs:**

- The list does not know your struct.
  - You get it back with `@fieldParentPtr`.
  - `@fieldParentPtr` trusts you.
- The struct's memory is yours.
  - The list does not free it.
  - The list does not know when the struct is gone.

If you come from C, this is Linux's `list_head` with `container_of`.

**_Parent_** is Zig's word. _Paternitas_ did not invent it.

- Zig calls the struct that contains a field the field's _parent_.
- `@fieldParentPtr` goes from the field to its parent.
- `Job` is the _Parent_ of its `node` field.

### Type-erased

Type-erased: the list forgets your struct's type.

The list sees a `Node`. It never sees your `Job`.

**What you get:**

- One `std.DoublyLinkedList` serves every struct type.
- There is one copy of its code.
- The code built on the list never names your struct types.
  - Examples: a queue, a scheduler, a dispatcher.
  - Add a struct type: that code does not change.
  - Change a struct: that code does not change.

Compare one container of a tagged union of all your types:

- A new type is a new union field.
- Every `switch` over the union without `else` must handle it.
- The container's type changes with the union.

A small program does not show the difference. A large system does:

- Struct types are added and changed all the time.
- The infrastructure built on the list stays fixed.

**What it costs:**

- The type is gone.
- A Node comes out of the list. Only you know which struct it is in.

---

## The problem

You keep Messages and Jobs in one `std.DoublyLinkedList`.

- You pop a Node.
- Is it in a Message, or in a Job?
- The list does not know.
- `@fieldParentPtr` returns whatever type you ask for.

```zig
const Message = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};
const Job = struct {
    id: u32,
    node: std.DoublyLinkedList.Node = .{},
};

var message: Message = .{ .text = "hi" };
var job: Job = .{ .id = 42 };

var list: std.DoublyLinkedList = .{};
list.append(&message.node);
list.append(&job.node);

const node = list.popFirst().?;
const j: *Job = @fieldParentPtr("node", node); // it is a Message
```

- It compiles.
- It runs.
- `j` points into a Message.
- `j.id` reads whatever bytes are there.
- Nothing tells you.

Paternitas makes that wrong guess safe: you get null, or a panic that
names both types. Never garbage.

---

## The same program with Paternitas

Copy it and run it. It prints:

```text
Hello Message: hi
Hello Job: 42
```

```zig
const std = @import("std");
const paternitas = @import("paternitas");

const Message = struct {
    text: []const u8,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedMessage = paternitas.Typed(Message);

const Job = struct {
    id: u32,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedJob = paternitas.Typed(Job);

pub fn main() void {
    var message: Message = .{ .text = "hi" };
    TypedMessage.setTypeId(&message);
    var job: Job = .{ .id = 42 };
    TypedJob.setTypeId(&job);

    var list: std.DoublyLinkedList = .{};
    list.append(TypedMessage.node(&message));
    list.append(TypedJob.node(&job));

    while (list.popFirst()) |node| {
        if (TypedMessage.parentFromNode(node)) |m| {
            std.debug.print("Hello Message: {s}\n", .{m.text});
        } else if (TypedJob.parentFromNode(node)) |j| {
            std.debug.print("Hello Job: {d}\n", .{j.id});
        }
    }
}
```

- A Node in the wrong type gives null, not garbage.
- The list is still the plain std list.
- Its calls do not change.

---

## What goes in your code

P is the Parent: your struct.

Two things go in your code:

- A TypedNode, in the struct, where the std Node was.
- `Typed(P)`, declared once, right after the struct.

```zig
const Message = struct {
    text: []const u8,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedMessage = paternitas.Typed(Message);
```

### The TypedNode

- A struct has exactly one _**TypedNode**_.
  - `paternitas.DoublyTypedNode` instead of `std.DoublyLinkedList.Node`.
  - `paternitas.SinglyTypedNode` instead of `std.SinglyLinkedList.Node`.
- The field can have any name.
- The field can be anywhere in the struct.
- Do not touch the fields inside it. Use `Typed(P)`.

### `Typed(P)`

`Typed(P)` is a helper. It does the housekeeping for you:

- It finds the TypedNode field in your struct, by its type.
- It does the `@fieldParentPtr` arithmetic.
- It writes your struct's type into the TypedNode.
- It checks the type when the Node comes back.

The four calls you need:

`setTypeId(&p)` writes your struct's type into its TypedNode.

- Call it right after you create the struct.
  - Even when every field has its default value.
  - Paternitas does not mark a new struct by itself.
- Without it, every check returns null.

```zig
var message: Message = .{ .text = "hi" };
TypedMessage.setTypeId(&message);
```

`node(&p)` gives you the std Node for the list.

```zig
list.append(TypedMessage.node(&message));
```

`parentFromNode(n)` gives you your struct back.

- You get null when the Node is in another type.
- Ask each type in turn.

Inside a function that handles one Node:

```zig
if (TypedMessage.parentFromNode(node)) |m| {
    std.log.info("message: {s}", .{m.text});
    return;
}
if (TypedJob.parentFromNode(node)) |j| {
    std.log.info("job: {d}", .{j.id});
    return;
}
return error.UnknownParent;
```

`mustParentFromNode(n)` gives you your struct back.

- Another type panics.
- It panics in every build mode.
- Use it where only your struct's type can be.

```zig
const m: *Message = TypedMessage.mustParentFromNode(list.popFirst().?);
```

Reset? A whole-struct write erases the type:

- `message = .{ .text = "new" };`
- a reset, clear or zero-fill of the whole struct

Call `setTypeId` again after each one. Writing one field, such as
`message.text = "new";`, keeps the type.

### All the calls, at a glance

For the taste (or smell). The details are in the API docs.

| call | what you get |
|---|---|
| `TypedMessage.setTypeId(&message)` | the type written into the struct. Again after a whole-struct write |
| `TypedMessage.node(&message)` | the std Node for the list |
| `TypedMessage.parentFromNode(node)` | `?*Message`: the Message, or null |
| `TypedMessage.mustParentFromNode(node)` | `*Message`, or a panic |
| `TypedMessage.is(node)` | true when the Node is in a Message |
| `TypedMessage.typeId()` | the type id of `Message` |
| `TypedMessage.toAny(&message)` | an `AnyParent`. See "Advanced topics" |
| `TypedMessage.fromAny(any)` | `?*Message`, back from an `AnyParent` |
| `TypedMessage.anchor(&message)` | an `*Anchor`. See "Advanced topics" |
| `TypedMessage.parentFromAnchor(a)` | `?*Message`, back from an `*Anchor` |

---

## Migrate your code to Paternitas

Ten minutes of find and replace. It may save your life. At least your
weekend.

The migration is mechanical.

- Find and replace, five times.
- No design to think about.
- The compiler finds what you missed, except step 3.

```text
before                       after
Message                      Message
+--------------------+       +---------------------------+
| text               |       | text                      |
| node  <-- the list |       | tnode: DoublyTypedNode    |
+--------------------+       | +-----------------------+ |
                             | | node   <-- the list   | |
                             | | internal info...      | |
                             | +-----------------------+ |
                             +---------------------------+
```

Before:

```zig
const Message = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};

var message: Message = .{ .text = "hi" };
list.append(&message.node);

const m: *Message = @fieldParentPtr("node", list.popFirst().?);
```

After:

```zig
const Message = struct {
    text: []const u8,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedMessage = paternitas.Typed(Message); // does the @fieldParentPtr work

var message: Message = .{ .text = "hi" };
TypedMessage.setTypeId(&message);
list.append(TypedMessage.node(&message));

const m: *Message = TypedMessage.mustParentFromNode(list.popFirst().?);
```

The five steps, for each struct in the list:

| step | find | replace with |
|---|---|---|
| 1 | `std.DoublyLinkedList.Node` | `paternitas.DoublyTypedNode`. Keep the field name, or rename it |
| 1 | `std.SinglyLinkedList.Node` | `paternitas.SinglyTypedNode` |
| 2 | the end of the struct, `};` | `};` and then `const TypedMessage = paternitas.Typed(Message);` |
| 3 | after `var message: Message = .{ ... };` | add `TypedMessage.setTypeId(&message);` |
| 4 | `&message.node` | `TypedMessage.node(&message)` |
| 5 | `@fieldParentPtr("node", n)` | `TypedMessage.mustParentFromNode(n)` |

- Job: the same five steps, with `TypedJob`.
- Your code writes the whole struct somewhere, as a reset?
  - Add `TypedMessage.setTypeId(&message);` right after it, too.
- The list itself does not change.
- The compiler stops at each place you missed in steps 4 and 5.
- Missed step 3? The compiler cannot see it.
  - `mustParentFromNode` panics: "asked for Message, found <no type>".
  - Add `setTypeId` right after that struct is created.
- `mustParentFromNode` still returns `*Message`.
  - A wrong type panics, in every build mode.
- Several types in one list? Use `parentFromNode` instead.
  - Ask each type in turn, as in "What goes in your code".

---

## Recap: why you need all this mess

### Why intrusive and type-erased

Why not `std.ArrayList(Job)`, or one list of a tagged union?

| | typed container of values | intrusive, type-erased list |
|---|---|---|
| add an item | allocates. Can fail: `try` | allocates nothing. Cannot fail |
| your struct | copied into the container | stays where it is |
| a pointer into your struct | breaks when the container grows | stays valid |
| a struct with a mutex, or too large to copy | does not fit | fits |
| remove an item from the middle | search for it, then shift the rest | one call, no search |
| move an item to another list | copy it, and maybe allocate | remove, append. No allocation |
| a new struct type | a new container, or a new union field and every `switch` | the same list |
| the queue, scheduler, dispatcher code | changes with your types | written once |

The price:

- The type is gone. Only you know which struct a Node is in.
- Guess wrong, and `@fieldParentPtr` still gives you a pointer.
  - It compiles. It runs. No build mode checks the type.
  - A read gets another struct's bytes.
  - A write corrupts another struct: its mutex, its pointers, its length.
  - The crash comes later, somewhere else. Or never: just wrong data.
- One wrong guess in a large system costs days of debugging.

### Why Paternitas

Paternitas removes most of that price.

- A wrong guess gives null, or a panic that names both types.
- It does not check that the struct is still alive.
- Side by side:

| | plain std list | with Paternitas |
|---|---|---|
| a wrong type | compiles, runs, reads garbage | null, or a panic |
| the panic says | nothing | "asked for Job, found Message" |
| where the bug shows | later, somewhere else | at the call that got it wrong |
| release builds | no check | the same check, in every build mode |
| several types in one list | you track the type yourself | you ask: "is this a Message?" |
| the field name | in every `@fieldParentPtr("node", n)` | once, in the struct |
| the cost | none | one pointer compare per check |
| your list | std | still std, with the same calls |
| your memory | yours | still yours. Nothing is allocated |

---

## Do you need it?

**No**, when each list carries one struct type, and you know which one.

- Plain `@fieldParentPtr` is enough.

**Yes**, when:

- one std list carries several struct types, as Messages and Jobs in a
  mailbox, or
- a struct goes through a queue, a map or a union field. See "Advanced
  topics".

---

## What Paternitas does not do

- It has no list, queue or pool of its own.
  - You keep using std, or your own.
- It does not allocate anything.
- It does not free anything.
- It does not lock anything.
- Your struct lives where you put it.
- It tells you the type.
  - It does not tell you the struct is still alive.
- A type id is valid only inside one running program.
  - A shared library gets its own id for the same type.

---

## Advanced topics

You do not need these to migrate a std list.

But if you want an adventure, and you are brave enough for a deep dive:

- Building your own container? For example, one that mixes
  `DoublyTypedNode` and `SinglyTypedNode` structs.
  - Use `Anchor` and `paternitas.container`.
- Passing your struct through a queue, a map or a union field?
  - Use `AnyParent`.

Both are explained in the comments, and in the
[API docs](https://g41797.github.io/paternitas/apidocs/).

Have fun.

---

## Why Paternitas

*Paternitas* is Latin for "fatherhood".

Paternitas is about finding the Parent of an unknown Node.

Latin law has two terms for it:

- *Affirmatio paternitatis*: the affirmation of paternity.
- *Investigatio paternitatis*: the investigation of paternity.

Paternitas does both.

- *Affirmatio paternitatis*: a Parent gets its type.

  ```zig
  TypedMessage.setTypeId(&message);
  ```

- *Investigatio paternitatis*: an erased Node is checked, to find its
  Parent.

  ```zig
  if (TypedMessage.parentFromNode(node)) |m| { ... } // null: not a Message
  ```

The name is a small joke. The idea is literal.

> The Node may be unknown.
> _Paternitas_ establishes its parentage.

**Note.** Both Latin terms were _invented_ while this README was written.

- We believe they are real Latin.
- We did not check them in a law book.
- A joke is a joke.

---

## Install

Fetch the package. It writes the dependency into your `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/g41797/paternitas
```

Add the module to your `build.zig`, after your `exe`:

```zig
const paternitas = b.dependency("paternitas", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("paternitas", paternitas.module("paternitas"));
```

Import it in your code:

```zig
const paternitas = @import("paternitas");
```

Requirements:

- Zig 0.16.0.
- Only `std`.
- There is no release tag yet. `zig fetch` takes the main branch.

---

## Where it came from

The trigger was the Ziggit post
[New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).

_Paternitas_ grew out of **_Matryoshka_**, a toolkit for background processes:

- [matryoshka-otk](https://github.com/g41797/matryoshka-otk), in Odin: the
  first code with this approach. A hand-made tag per type.
- [matryoshka-3tk](https://github.com/g41797/matryoshka-3tk), in C3: C3's
  own `typeid`, and one helper per type.
- [matryoshka-ztk](https://github.com/g41797/matryoshka-ztk), in Zig: the
  same idea, with Zig's comptime. Still in progress.

_Paternitas_ was extracted from ztk, so that any Zig program can use it.

ztk will use it as a third-party package.

---

## Credits

- [Karl Seguin](https://github.com/karlseguin), for the article that introduced [Zig's new LinkedList API](https://www.openmymind.net/Zigs-New-LinkedList-API/).
