# All the calls

Every call, one line each.

The full signatures and comments are in the [API docs](../apidocs/index.html){target="_blank" rel="noopener"}.

In the tables, `Message` stands for your struct, and `TypedMessage` for its helper.

---

## The types

| name | what it is |
|---|---|
| `SinglyTypedNode` | the field for a struct in a `std.SinglyLinkedList`. It replaces `std.SinglyLinkedList.Node` |
| `DoublyTypedNode` | the field for a struct in a `std.DoublyLinkedList`. It replaces `std.DoublyLinkedList.Node` |
| `STNode`, `DTNode` | short names for the two above |
| `TypedNode(N)` | the type behind both. You do not call it yourself |
| `Typed(P)` | the helper for one struct type. Declare it once, right after the struct |
| `TypeId` | a runtime id for a struct type. One pointer. Null means no type |
| `Any` | a struct's address and its type id. Two words |
| `Anchor` | a one-word handle to a struct with a TypedNode. For container authors |
| `container` | tools for writing your own container: `TypeInfo`, `NodeKind` |

---

## `Typed(P)`: every struct

These work for any struct, with or without a TypedNode.

| call | what you get | example |
|---|---|---|
| `TypedMessage.typeId()` | the type id of `Message` | 004, 007 |
| `TypedMessage.isId(id)` | true when `id` is the type id of `Message` | 007 |
| `TypedMessage.toAny(&message)` | an `Any`: the address and the type id | 003, 004, 005, 007 |
| `TypedMessage.fromAny(any)` | `?*Message`: the struct, or null for another type | 003, 004, 005, 007 |

---

## `Typed(P)`: a struct with a TypedNode

On a struct without a TypedNode, each of these is a compile error.

| call | what you get | example |
|---|---|---|
| `TypedMessage.setTypeId(&message)` | the type id written into the struct. Again after a whole-struct write | 001 to 006 |
| `TypedMessage.node(&message)` | the std Node, for the list | 001, 002, 003 |
| `TypedMessage.parentFromNode(node)` | `?*Message`: the struct, or null | 001, 002, 003 |
| `TypedMessage.mustParentFromNode(node)` | `*Message`, or a panic | none |
| `TypedMessage.is(node)` | true when the Node is in a `Message` | 002 |
| `TypedMessage.anchor(&message)` | the `*Anchor` | 006 |
| `TypedMessage.parentFromAnchor(a)` | `?*Message`: the struct, or null | 006 |
| `TypedMessage.mustParentFromAnchor(a)` | `*Message`, or a panic | none |
| `TypedMessage.parentFromNodeUnchecked(node)` | `*Message`, with no check. Only when the type is already known | none |
| `TypedMessage.Node` | the std Node type of `Message` | none |

The `must` calls panic in every build mode. The panic names both types.

---

## `Anchor`

| call | what you get | example |
|---|---|---|
| `a.info()` | the `*const TypeInfo` of the struct's type, or null | 006 |
| `a.typeId()` | the struct's type id, or null | none |
| `a.typeName()` | the struct's type name, or `<no type>`. For logs | none |
| `a.toAny()` | an `Any`, or null | none |

Each gives null, or `<no type>`, when `setTypeId` was never called.

---

## `container.TypeInfo`

You get it from `a.info()`. There is one per struct type.

| call | what you get | example |
|---|---|---|
| `info.nextField(a)` | a pointer to the Node's `next` field, to chain through | 006 |
| `info.node(a, N)` | the std Node, as type `N`. The wrong `N` panics | none |
| `info.parent(a)` | the struct's address, with no type | none |
| `info.toAny(a)` | an `Any` | none |
| `info.name` | the struct's type name | none |
