# Type-erased lists

Zig's std lists are type-erased too.

The list forgets your struct's type.

---

## The list sees a Node

The list sees a `Node`. It never sees your `Job`.

```text
Message --+
Job ------+--> Node --> std list
Task -----+
```

- One `std.DoublyLinkedList` serves every struct type.
- The code built on the list does not use your struct types.

That code is your infrastructure: a queue, a scheduler, a dispatcher.

- Add a struct type: that code does not change.
- Change a struct: that code does not change.

---

## The infrastructure stays fixed

A small program does not show the difference. A large system does.

- Struct types are added and changed all the time.
- The code built on the list is written once.
- It stays fixed while the types around it change.

That is the reason to keep the list type-erased.

---

## Why not a tagged union?

Sometimes a tagged union is exactly right.

Small values that travel by copy fit a union well:

```zig
--8<-- "examples/005-large_struct_in_union.zig:event"
```

One container of a union of all your types is different.

- A new type is a new union field.
- Every `switch` over the union without `else` must handle it.
- The container's type changes with the union.

Every new struct type touches the infrastructure.

??? question "NAQ: So a tagged union is wrong?"  
    No.

    A small, closed set of types fits a union well.

    An open set, in a large system, fits a type-erased list better.

    Both can live in one program. The `Event` above does that.

The `Event` above keeps the `Download` out of the union.

- Its field is an `Any`: the address and the type id.
- [Queues, maps, union fields](../guides/any.md) shows how.

---

## What it costs

The type is gone.

A Node comes out of the list. Only you know which struct it is in.
