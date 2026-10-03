

---

## Two words first

Zig's std lists are intrusive and type-erased.

- What the two words mean.
- What each one costs you.

---


### Intrusive

---


- An intrusive list keeps its link inside your struct.
- A non-intrusive container wraps your item in its own node.
  - It stores a copy of your item.

```
non-intrusive                  intrusive
the container's node           your struct
+-------------------+          +--------------------+
| next              |          | data               |
| a copy of         |          | node  <-- the list |
|   your data       |          +--------------------+
+-------------------+
```

What you get:

- The list allocates nothing for each item.
- Nothing is copied. Your struct stays at its address.
- One struct can be in several lists at once.
  - It needs one Node for each list.

What it costs:

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
- Your `Message` is the _Parent_ of its Node.
- Paternitas finds the _Parent_ of a Node, and checks its type.
- Hence the name (*Paternitas* is Latin for "fatherhood").

---


### Type-erased

---


The list sees a `Node`. It never sees your `Message`.

What you get:

- One `std.DoublyLinkedList` serves every struct type.
- There is one copy of its code.

What it costs:

- The type is gone.
- A Node comes out of the list. Only you know which struct it is in.

Paternitas keeps the erasure, and adds a check.

- It writes the type into your struct, when you create the struct.
- It checks the type, when the Node comes out.

---


## The problem

---


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


---


## The same program with Paternitas

---


Copy it and run it. It prints:

```
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

- The list is still the plain std list.
- Its calls do not change.

---


## What is `Typed(P)`?

---


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

---


- `DoublyTypedNode` is for `std.DoublyLinkedList`.
- `SinglyTypedNode` is for `std.SinglyLinkedList`.
- `DTNode` and `STNode` are the short names.
- The field can have any name.
- The field can be anywhere in the struct.
- A struct has one TypedNode.

---


`Typed(P)` is a helper. It does the housekeeping, so you do not:

- It finds the TypedNode field in P, by its type.
- It does the `@fieldParentPtr` arithmetic.
- It writes P's type into the TypedNode.
- It checks the type when the Node comes back.

It gives you four calls.

`setTypeId(&p)` writes P's type into its TypedNode.

- Call it right after you create the struct.
  - Even when every field has its default value.
  - A new struct has no type.
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
- Use it where only P can be.

```zig
const m: *Message = TypedMessage.mustParentFromNode(list.popFirst().?);
```

Reset? A whole-struct write erases the type:

- `message = .{ .text = "new" };`
- a reset, clear or zero-fill of the whole struct

Call `setTypeId` again after each one. Writing one field, such as
`message.text = "new";`, keeps the type.

---

### All the calls, at a glance

---


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

---


The migration is mechanical.

- Find and replace, five times.
- No design to think about.
- The compiler finds what you missed, except step 3.

```
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


---

Before:

---


```zig
const Message = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};

var message: Message = .{ .text = "hi" };
list.append(&message.node);

const m: *Message = @fieldParentPtr("node", list.popFirst().?);
```

---


After:

---


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
  - Ask each type in turn, as in "What is `Typed(P)`?".


---

## Do you need it?

---


You do not need Paternitas when:

- each list carries one struct type, and
- you know which one.

Plain `@fieldParentPtr` is fine there.

You need it when one std list carries several struct types.

- Example: Messages and Jobs in a mailbox.
- Each comes back as itself, or you get null.

To pass a struct through a queue, a map or a union field, see "Advanced
topics".

A type check costs one pointer compare.

- No type names to compare.
- No table to register in.


---

## What Paternitas does not do

---


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

---


You do not need these to migrate a std list.

- `AnyParent`: pass a struct through a queue, a map or a union field.
  - Examples [003](https://g41797.github.io/paternitas/examples/003-timeout_list/)
    and [005](https://g41797.github.io/paternitas/examples/005-large_struct_in_union/).
- A handler per type.
  - Example [004](https://g41797.github.io/paternitas/examples/004-handler_map/).
- `Anchor` and `paternitas.container`: for your own container.
  - Example [006](https://g41797.github.io/paternitas/examples/006-anchor_chain/).

All of them are explained in the comments, and in the
[API docs](https://g41797.github.io/paternitas/apidocs/).


Have fun.

---


## Why Paternitas

---


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

---


> The Node may be unknown.
> _Paternitas_ establishes its parentage.

---


**Note.** Both Latin terms were _invented_ while this README was written.

- We believe they are real Latin.
- We did not check them in a law book.
- A joke is a joke.


---

## Install

---


Fetch the package. It writes the dependency into your `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/g41797/paternitas
```

Add the module to your `build.zig`, after your `exe`:

```zig
const paternitas = b.dependency("paternitas", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("paternitas", paternitas.module("paternitas"));
```

Import it in your code:

```zig
const paternitas = @import("paternitas");
```

- Zig 0.16.0.
- Only `std`.
- There is no release tag yet. `zig fetch` takes the main branch.
