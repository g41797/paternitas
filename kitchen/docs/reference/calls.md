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
| `TypedMessage.typeId()` | the type id of `Message` | [Handler map](../examples/004-handler_map.md){target="_blank" rel="noopener"}, [Type id without a node](../examples/007-type_id_without_node.md){target="_blank" rel="noopener"} |
| `TypedMessage.isId(id)` | true when `id` is the type id of `Message` | [Type id without a node](../examples/007-type_id_without_node.md){target="_blank" rel="noopener"} |
| `TypedMessage.toAny(&message)` | an `Any`: the address and the type id | [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"}, [Handler map](../examples/004-handler_map.md){target="_blank" rel="noopener"}, [Large struct in a union](../examples/005-large_struct_in_union.md){target="_blank" rel="noopener"}, [Type id without a node](../examples/007-type_id_without_node.md){target="_blank" rel="noopener"} |
| `TypedMessage.fromAny(any)` | `?*Message`: the struct, or null for another type | [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"}, [Handler map](../examples/004-handler_map.md){target="_blank" rel="noopener"}, [Large struct in a union](../examples/005-large_struct_in_union.md){target="_blank" rel="noopener"}, [Type id without a node](../examples/007-type_id_without_node.md){target="_blank" rel="noopener"} |

---

## `Typed(P)`: a struct with a TypedNode

On a struct without a TypedNode, each of these is a compile error.

| call | what you get | example |
|---|---|---|
| `TypedMessage.setTypeId(&message)` | the type id written into the struct. Again after a whole-struct write | [One struct, one list](../examples/001-set_type_id_and_recover.md){target="_blank" rel="noopener"}, [Two types, one list](../examples/002-mixed_list.md){target="_blank" rel="noopener"}, [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"}, [Handler map](../examples/004-handler_map.md){target="_blank" rel="noopener"}, [Large struct in a union](../examples/005-large_struct_in_union.md){target="_blank" rel="noopener"}, [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"} |
| `TypedMessage.node(&message)` | the std Node, for the list | [One struct, one list](../examples/001-set_type_id_and_recover.md){target="_blank" rel="noopener"}, [Two types, one list](../examples/002-mixed_list.md){target="_blank" rel="noopener"}, [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"} |
| `TypedMessage.parentFromNode(node)` | `?*Message`: the struct, or null | [One struct, one list](../examples/001-set_type_id_and_recover.md){target="_blank" rel="noopener"}, [Two types, one list](../examples/002-mixed_list.md){target="_blank" rel="noopener"}, [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"} |
| `TypedMessage.mustParentFromNode(node)` | `*Message`, or a panic | none |
| `TypedMessage.is(node)` | true when the Node is in a `Message` | [Two types, one list](../examples/002-mixed_list.md){target="_blank" rel="noopener"} |
| `TypedMessage.anchor(&message)` | the `*Anchor` | [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"} |
| `TypedMessage.parentFromAnchor(a)` | `?*Message`: the struct, or null | [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"} |
| `TypedMessage.mustParentFromAnchor(a)` | `*Message`, or a panic | none |
| `TypedMessage.parentFromNodeUnchecked(node)` | `*Message`, with no check. Only when the type is already known | none |
| `TypedMessage.Node` | the std Node type of `Message` | none |

The `must` calls panic in every build mode. The panic names both types.

---

## `Anchor`

| call | what you get | example |
|---|---|---|
| `a.info()` | the `*const TypeInfo` of the struct's type, or null | [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"} |
| `a.typeId()` | the struct's type id, or null | none |
| `a.typeName()` | the struct's type name, or `<no type>`. For logs | none |
| `a.toAny()` | an `Any`, or null | none |

Each gives null, or `<no type>`, when `setTypeId` was never called.

---

## `container.TypeInfo`

You get it from `a.info()`. There is one per struct type.

| call | what you get | example |
|---|---|---|
| `info.nextField(a)` | a pointer to the Node's `next` field, to chain through | [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"} |
| `info.node(a, N)` | the std Node, as type `N`. The wrong `N` panics | none |
| `info.parent(a)` | the struct's address, with no type | none |
| `info.toAny(a)` | an `Any` | none |
| `info.name` | the struct's type name | none |
