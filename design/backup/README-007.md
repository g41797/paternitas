![](kitchen/docs/assets/logo/paternitas-logo.svg)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/paternitas/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/linux.yml)
[![Windows](https://github.com/g41797/paternitas/actions/workflows/windows.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/windows.yml)
[![macOS](https://github.com/g41797/paternitas/actions/workflows/mac.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/mac.yml)
[![Deploy Documentation](https://github.com/g41797/paternitas/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/paternitas/actions/workflows/docs.yml)

---

Paternitas makes Zig's intrusive, type-erased lists safer.

And a bonus at the end: a runtime type id for any struct. No list, no Node.

---

## Three words first

**Intrusive.**

- The link lives inside your struct.
- The list keeps a pointer to that link.
- It never copies your struct.

**Type-erased.**

- The list sees only the link, a `Node`.
- It does not know the struct type around it.

**Parent.**

- The struct that contains the Node.
- Getting the Parent back from a Node is `@fieldParentPtr`.

---

## The problem and solution in one example

Suppose one list contains `Message` and `Job`.

```zig
const Message = struct {
    text: []const u8,
    node: std.DoublyLinkedList.Node = .{},
};

const Job = struct {
    id: u32,
    node: std.DoublyLinkedList.Node = .{},
};

list.append(&message.node);
list.append(&job.node);
```

Later:

```zig
const node = list.popFirst().?;

const job: *Job = @fieldParentPtr("node", node);
```

The code compiles.

The code runs.

But maybe `node` belongs to `Message`.

Now `job` points at a `Message`.

That is the bad part of intrusive, type-erased code:

- the container forgot the struct type,
- `@fieldParentPtr` trusts your answer,
- a wrong answer is still a pointer,
- the bug may show up much later.

Paternitas puts a type id next to the Node.

The fix, for the same two structs:

- swap the std Node for a TypedNode,
- add one `Typed` line after each struct,
- mark each new value with `setTypeId`,
- ask the Node: "are you a Message?"

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

A wrong type gives `null`.

The loop simply tries the next type.

When the wrong type is a programmer error, ask firmly:

```zig
const message = TypedMessage.mustParentFromNode(node);
```

That gives a panic with the expected and actual type.

No new container.

No allocation.

No lock.

Your std list stays your std list.

---

## Do I need it?

You probably do not need it for your first linked list.

If your list has only `Job`, and everybody knows it contains `Job`, use the plain std list.

You may want it when the list becomes part of a real system:

- a mailbox grows,
- a scheduler gets more job types,
- a dispatcher starts passing different structs through the same list.

Then you pop a `Node`, and the std list does not know what struct it is inside.

Use Paternitas when:

- one list deliberately mixes struct types,
- the code handling the list should not know every application type,
- the Node comes from somewhere else,
- you do not want to trust every `@fieldParentPtr` call by hand,
- a bad cast would turn into a very long debugging session.

The last one is a perfectly respectable reason.

Paternitas is for the moment when "I know what this is" becomes "I hope I know what this is".

---

## What you get

- Your std list stays your std list. Same type, same calls.
- Singly or doubly linked. Both std lists work.
- No allocation. No copy of your struct.
- One additional pointer per struct, for the type id.
- A wrong type gives `null`, or a panic that names both types.
- The check is the same in every build mode, release too.
- Several struct types in one list, each one checked.
- The compiler stops the easy mistakes, like two TypedNodes in one struct.
- Tools for writing your own container.

It checks the type.

Lifetime and locking stay yours.

---

## Want to know more?

The doc site has:

- moving your code, step by step,
- singly or doubly linked lists,
- why not a tagged union,
- passing structs through queues and maps,
- the one `setTypeId` rule,
- writing your own container,
- the limits,
- every call.

And seven examples you can run.

---

## Install

Fetch the package:

```sh
zig fetch --save git+https://github.com/g41797/paternitas
```

Add it to `build.zig`:

```zig
const paternitas = b.dependency("paternitas", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("paternitas", paternitas.module("paternitas"));
```

Then:

```zig
const paternitas = @import("paternitas");
```

Requirements:

- Zig 0.16.0
- `std` only

---

## Why the name?

*Paternitas* is Latin for "fatherhood".

A list gives you an unknown Node.

Paternitas helps you establish its Parent.

That is the idea.

> The Node may be unknown.
>
> Paternitas establishes its parentage.

---

## Where it came from

The trigger was the Ziggit post
[New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).

Paternitas grew out of _Matryoshka_, a toolkit for background processes:

- [Odin](https://github.com/g41797/matryoshka-otk),
- [C3](https://github.com/g41797/matryoshka-3tk),
- [Zig](https://github.com/g41797/matryoshka-ztk). Work in progress.

The same problem showed up in each one.

The useful part was small enough to stand alone.

Your project can use it too.

---

## Credits

- [Karl Seguin](https://github.com/karlseguin), for the article that introduced
  [Zig's new LinkedList API](https://www.openmymind.net/Zigs-New-LinkedList-API/).

---

## Bonus: for the curious and the brave

No list here.

No Node.

Just your struct.

Zig's `type` lives only at compile time.

At run time, a value of unknown type is just an address.

Paternitas gives any struct a runtime type id.

```zig
const Point = struct { x: i32, y: i32 }; // no TypedNode
const TypedPoint = paternitas.Typed(Point);

var point: Point = .{ .x = 3, .y = 4 };
const any = TypedPoint.toAny(&point);

if (TypedPoint.fromAny(any)) |p| {
    // It really is a Point.
}
```

`any` holds the address and the type id.

It does not hold a copy of `Point`.

Good for handler maps, queues, callbacks and `*anyopaque` contexts.

No allocation.

No registry.

No init call.

The rest of the story is on the doc site.
