# Which page you need

Find your case. Read its page. Open its example.

| your case | the calls | the page | the example |
|---|---|---|---|
| one std list, several struct types | `parentFromNode` | [Several types in one list](mixed-list.md) | [Two types, one list](../examples/002-mixed_list.md){target="_blank" rel="noopener"}, [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"} |
| a std list where another type is a bug | `mustParentFromNode` | [Migrate your code](lists.md) | [One struct, one list](../examples/001-set_type_id_and_recover.md){target="_blank" rel="noopener"} |
| a queue, a map or a union field | `toAny`, `fromAny` | [Queues, maps, union fields](any.md) | [Handler map](../examples/004-handler_map.md){target="_blank" rel="noopener"}, [Large struct in a union](../examples/005-large_struct_in_union.md){target="_blank" rel="noopener"} |
| a type id, no list at all | `typeId`, `isId` | [Type ids, listless and nodeless](type-ids.md) | [Type id without a node](../examples/007-type_id_without_node.md){target="_blank" rel="noopener"} |
| your own container | `anchor`, `anchor.info()` | [Your own container](containers.md) | [Your own stack](../examples/006-anchor_chain.md){target="_blank" rel="noopener"} |
| one list, one known type | none | plain `@fieldParentPtr` is enough | none |

Every case with a TypedNode has one rule: [call `setTypeId`](set-type-id.md).

Every call, one line each: [All the calls](../reference/calls.md).
