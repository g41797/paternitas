

---

## Two words first

Zig's std lists are intrusive and type-erased. Here is what the two words
mean, and what each one costs you.

---


### Intrusive

---


An intrusive list keeps its link inside your struct. A non-intrusive
container wraps your item in a node of its own, and stores a copy.

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
- One struct can be in several lists at once, with one Node for each.

What it costs:

- The list does not know your struct. You get it back with
  `@fieldParentPtr`, and `@fieldParentPtr` trusts you.
- The struct's memory is yours. The list does not free it, and it does not
  know when the struct is gone.

If you come from C, this is Linux's `list_head` with `container_of`.

Zig calls the struct that contains a field its parent: `@fieldParentPtr`
goes from the field to the parent. paternitas uses the same word. Your
`Message` is the Parent of its Node, and paternitas finds the Parent of a
Node, with its type checked. Hence the name: *paternitas*, fatherhood.

---


### Type-erased

---


The list sees a `Node`, never your `Message`. That is why one
`std.DoublyLinkedList` serves every struct type, with one copy of its code.

The cost is that the type is gone. When a Node comes out of the list, only
you know which struct it is in.

paternitas keeps the erasure. It writes the type next to the Node when the
struct goes in, and checks it when the Node comes out.

---


## The problem

---


You keep Messages and Jobs in one `std.DoublyLinkedList`. You pop a Node.
Is it in a Message or in a Job?

The list does not know. `@fieldParentPtr` returns whatever type you ask
for:

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

It compiles and it runs. `j` points into a Message, and `j.id` reads
whatever bytes are there. Nothing tells you.


---


## What is `Typed(P)`?

---


P is the Parent: your struct. `Typed(P)` is a helper you declare next to
it, once. It does the housekeeping, so you do not:

- It finds the TypedNode field in P, by its type.
- It does the `@fieldParentPtr` arithmetic.
- It writes P's type next to the Node, and checks it when the Node comes
  back.

Two lines go in your code. A TypedNode goes in the struct, where the std
Node was, and the helper goes next to the struct:

```zig
const Message: type = struct {
    text: []const u8,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedMessage: type = paternitas.Typed(Message);
```

- `DoublyTypedNode` is for `std.DoublyLinkedList`. `SinglyTypedNode` is for
  `std.SinglyLinkedList`. `DTNode` and `STNode` are short for the two.
- It is the std Node, with the type kept next to it.
- The field can have any name, anywhere in the struct. A struct has one
  TypedNode.

Then the helper gives you four calls.

`setTypeId(&p)` writes P's type into its TypedNode. Call it once, before
the struct goes in a list. Without it, every check returns null.

```zig
TypedMessage.setTypeId(&message);
```

`node(&p)` gives you the std Node for the list.

```zig
list.append(TypedMessage.node(&message));
```

`parentFromNode(n)` gives you your struct back, or null when the Node is in
another type. Ask each type in turn:

```zig
if (TypedMessage.parentFromNode(node)) |m| {
    std.log.info("message: {s}", .{m.*.text});
    return;
}
if (TypedJob.parentFromNode(node)) |j| {
    std.log.info("job: {d}", .{j.*.id});
    return;
}
return error.UnknownParent;
```

`mustParentFromNode(n)` gives you your struct back, and panics for another
type, in every build mode. Use it where only P can be.

```zig
const m: *Message = TypedMessage.mustParentFromNode(list.popFirst().?);
```

The first three snippets come from examples 001 and 002.

---


## The same program with paternitas

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
const Job = struct {
    id: u32,
    tnode: paternitas.DoublyTypedNode = .{},
};
const TypedMessage = paternitas.Typed(Message);
const TypedJob = paternitas.Typed(Job);

pub fn main() void {
    var message: Message = .{ .text = "hi" };
    var job: Job = .{ .id = 42 };
    TypedMessage.setTypeId(&message);
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

The list is still the plain std list. Its calls do not change.

---


## Migrate your code to paternitas

---


Put a TypedNode where the Node was. It is the same std Node, with the
struct's type kept next to it.

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

Before:

```zig
const Message = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};

var message: Message = .{ .text = "hello" };
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

var message: Message = .{ .text = "hello" };
TypedMessage.setTypeId(&message);
list.append(TypedMessage.node(&message));

const m: *Message = TypedMessage.mustParentFromNode(list.popFirst().?);
```

Job gets the same change: its `std.DoublyLinkedList.Node` becomes a
`paternitas.DoublyTypedNode`, and it gets its own
`const TypedJob = paternitas.Typed(Job);`.

Do it this way, for each struct in the list:

1. `std.SinglyLinkedList.Node` becomes `paternitas.SinglyTypedNode`.
   `std.DoublyLinkedList.Node` becomes `paternitas.DoublyTypedNode`.
2. Add `const TypedMessage = paternitas.Typed(Message);`, once.
3. Call `TypedMessage.setTypeId(&message)` once, after the struct is set
   up and before it goes in a list.
4. `&message.node` becomes `TypedMessage.node(&message)`.
5. `@fieldParentPtr("node", n)` becomes `TypedMessage.mustParentFromNode(n)`.
   It still returns `*Message`. A wrong type panics, in every build mode.

The list itself does not change. The compiler stops at each place you
missed in steps 4 and 5.

Then, where a Node of another type is expected, use `parentFromNode`.
It returns null for another type.

## Do you need it?

You do not need paternitas when each list keeps one struct type, and you
know which one. Plain `@fieldParentPtr` is fine there.

You need it when one std list carries several struct types, as Messages
and Jobs in a mailbox. Each comes back as itself, or you get null.

To pass a struct on, through a queue, a map or a union field, see
"Advanced topics".

A type check costs one pointer compare. There are no type names to compare
and no table to register in.

## What paternitas does not do

- It has no list, queue or pool of its own. You keep using std, or your own.
- It does not allocate, free or lock anything. Your struct lives where you
  put it, for as long as you keep it.
- It tells you the type. It does not tell you the struct is still alive.
- A type id is valid only inside one running program. A shared library gets
  its own id for the same type.

## Advanced topics

You do not need these to move a std list to paternitas. Each one is in the
[API docs](https://g41797.github.io/paternitas/apidocs/), and has an
[example](https://g41797.github.io/paternitas/examples/001-set_type_id_and_recover/).

- `AnyParent`: pass a struct through a queue, a map or a union field, as its
  address and its type. Get it back with `fromAny`. Examples 003 and 005.
- A handler per type: `typeId()` as a map key, and an `AnyParent` to call
  the handler. Example 004.
- `Anchor` and `paternitas.container`: for writing your own container.
  Example 006.
