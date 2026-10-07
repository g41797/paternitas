# Stuck on a word?

Find it here. One line each, and the page that explains it.

| term | what it means | where |
|---|---|---|
| intrusive | the link lives inside your struct. The list never copies your struct | [Intrusive lists](../background/intrusive.md) |
| type-erased | the list sees only the link, a Node. It does not know the struct type around it | [Type-erased lists](../background/type-erased.md) |
| Node | the link in your struct. The std list links Nodes | [Intrusive lists](../background/intrusive.md) |
| Parent | the struct that contains the Node. Zig's word | [Are you my Parent?](../background/parent-problem.md) |
| TypedNode | the std Node with a type check added. `SinglyTypedNode` or `DoublyTypedNode` | [Migrate your code](../guides/lists.md) |
| `Typed(P)` | the helper for one struct type `P`. It does the `@fieldParentPtr` work, and checks the type | [Migrate your code](../guides/lists.md) |
| type id | a runtime id for a struct type | [Type ids, listless and nodeless](../guides/type-ids.md) |
| `TypeId` | the type of a type id. One pointer. Null means no type | [Type ids, listless and nodeless](../guides/type-ids.md) |
| `setTypeId` | marks a struct as its type. The one rule you keep yourself | [The setTypeId rule](../guides/set-type-id.md) |
| `Any` | a struct's address and its type id. Two words | [Queues, maps, union fields](../guides/any.md) |
| `Anchor` | a one-word handle to a struct with a TypedNode | [Your own container](../guides/containers.md) |
| `TypeInfo` | what your container needs to know about one struct type | [Your own container](../guides/containers.md) |
