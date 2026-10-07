# Limits

What *Paternitas* does not do, and what it stops.

---

## What *Paternitas* does not do

*Paternitas* is not a list library.

It does not give you:

- a list, a queue or a pool;
- an allocator;
- a free;
- a lock.

You keep using the containers you already use.

*Paternitas* helps with one dangerous step:

```text
erased Node
    |
    | "I think this is a Message"
    v
*Message
```

It checks that answer first.

---

## The type, not the lifetime

*Paternitas* checks the type.

It does not check that the struct is still alive.

- If the struct is gone, *Paternitas* cannot bring it back.
- A Node, an Anchor or an `Any` does not keep the struct alive.
- The struct MUST stay alive while any of them is in use.

---

## Shared access

*Paternitas* locks nothing.

Guard a shared list yourself.

??? question "NAQ: Is it thread-safe?"  
    It locks nothing.

    `setTypeId` writes the type id. The checks read it.

    Guard them as you guard the list.

---

## Type ids have a boundary

A type id is for one running program.

Do not:

- save it to disk;
- send it over the network;
- use it as a process-to-process type number.

A shared library has its own type ids, even for the same struct type.

- A struct marked in the library fails the type check in the main program.
- The same holds the other way round.

??? question "NAQ: Does it work across a shared library?"  
    No.

    Each shared library has its own type ids, even for the same struct type.

    Pass structs across that boundary in your own way.

---

## What the compiler stops

Each message names the type. Each comes from a program in `negative/compile/`, run by the gates.

| the mistake | the message | the program |
|---|---|---|
| a list call on a struct without a TypedNode | `<P>: no TypedNode, so it has only typeId, isId, toAny and fromAny` | `bare_node.zig` |
| `Typed` of a value that is not a struct | `<P>: not a struct, and Typed takes structs only` | `not_struct.zig` |
| two TypedNodes in one struct | `<P>: more than one TypedNode, and at most one is allowed` | `two_typed_nodes.zig` |
| `TypedNode(N)` of a Node that is not a std Node | `TypedNode(<N>): not a std Node, so it cannot be a Paternitas TypedNode` | `typed_node_other_node.zig` |
| a doubly Node given to a singly struct | Zig's own type error: `found '*DoublyLinkedList.Node'` | `wrong_node.zig` |

---

## What the program stops at run time

Each comes from a program in `negative/panic/`, run by the gates.

| the mistake | the panic | when | the program |
|---|---|---|---|
| `mustParentFromNode` on a struct with no type id | `mustParentFromNode: asked for <P>, found <no type>` | every build mode | `must_parent_from_node.zig` |
| `mustParentFromAnchor` on another type | `mustParentFromAnchor: asked for <P>, found <Q>` | every build mode | `must_parent_from_anchor.zig` |
| `info.node` with the wrong Node kind | `TypeInfo.node: <P> has another Node kind` | every build mode | `wrong_node_kind.zig` |
| `fromAny` of a hand-built `Any`, with no `setTypeId` | `fromAny: setTypeId was never called on the Parent` | runtime safety on | `from_any_no_type.zig` |
| `fromAny` of an `Any` from `toAny`, with no `setTypeId` | the same | runtime safety on | `from_any_to_any_no_type.zig` |

Runtime safety is on in Debug and ReleaseSafe.

In ReleaseFast and ReleaseSmall, the last two compile to nothing.

---

## What neither can stop

A missing `setTypeId`.

- The compiler cannot see it.
- At run time, the struct just has no type id.
- `parentFromNode` gives null, and `mustParentFromNode` says `found <no type>`.

[The setTypeId rule](../guides/set-type-id.md) says where to call it.
