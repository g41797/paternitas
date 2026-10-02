# paternitas

Intrusive, type-erased programming for Zig.

- A std Node does not say which Parent it lives in. paternitas says.
- It depends on `std` only. It allocates nothing.
- Zig 0.16.0.

*Paternitas* is Latin for "fatherhood".

## The problem

Zig's std lists are intrusive.

- A Parent struct contains a std Node.
- The list sees only the Node. The Parent type is gone.
- `@fieldParentPtr` gets the Parent back, but does not check it.
  - Two structs can put their Nodes in one list.
  - The wrong Parent comes back, and the compiler cannot see it.
  - The ziggit thread:
    [New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).

A second problem.

- A container that stores by value copies its items.
- Some items must not be copied: a mutex, a file handle, a large buffer.
- They need a container of pointers, and a way to know their type again.

## The model

```text
Parent
 |
 +-- Link  (one per Parent)
      |
      +-- node:   std Node (single or double)
      +-- anchor: Anchor ---> TypeInfo (static, one per Parent type)
```

- **Link** — a std Node and an Anchor, as one type. `SLink` or `DLink`.
- **Anchor** — one stamped word. Its address is the erased reference to the
  Parent.
- **TypeId** — the address of the Parent type's `TypeInfo`.
- **`Info(P)`** — the typed helper for one Parent type, built at comptime.
- **AnyParent** — the dispatch view: the Parent address and its TypeId.

## A first look

```zig
const Message = struct {
    text: []const u8,
    link: paternitas.DLink = .{},
};
const MessageInfo = paternitas.Info(Message);

var message: Message = .{ .text = "hello" };
MessageInfo.stamp(&message);

var list: std.DoublyLinkedList = .{};
list.append(MessageInfo.node(&message));

// Null when the Node belongs to another Parent type.
const m: ?*Message = MessageInfo.parentFromNode(list.popFirst().?);
```

The std list, its calls and its Node type stay as they are.

## Two audiences

Application code.

- `Info(P)`, `SLink`, `DLink`, `*Anchor`, `AnyParent`.
- Recover a Parent from a Node, from an Anchor, or from an AnyParent.
- Each recovery checks the type first.

Container authors.

- `paternitas.container`: `TypeInfo`, `NodeKind`.
- `TypeInfo.nextField` says where the Node's `next` word is.
- The container decides what goes in it.

## What paternitas does not do

paternitas is mechanism, not policy.

- No list, queue, mailbox or pool of its own.
- No allocation, no lifetime management, no synchronization.
- No rule for who frees a Parent. The application decides.
- A TypeId is a type identity. It does not prove the Parent is alive.

## Read more

- [Examples](https://g41797.github.io/paternitas/examples/001-stamp_and_recover/)
  — one pattern per page.
- [API docs](https://g41797.github.io/paternitas/apidocs/).

## License

MIT.
