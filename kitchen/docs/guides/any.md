# Queues, maps, union fields

Not everything is a linked list.

- A generic queue carries different structs.
- A map keeps one handler per type.
- A union field carries a struct, but must not copy it.

Use `Any`.

---

## What an `Any` is

An `Any` is two words:

- `ptr`, the struct's address;
- `type_id`, the struct's type id.

It does not hold a copy of your struct.

A queue, a map or a union field copies the two words. Your struct stays where it is.

| call | what it does |
|---|---|
| `TypedMessage.toAny(&message)` | packs the address and the type id |
| `TypedMessage.fromAny(any)` | checks the type id, and gives you `*Message` or null |

Call `setTypeId` on the struct before `toAny`.

- `toAny` does not check it.
- `fromAny` checks it when runtime safety is on.

??? question "NAQ: Why `Any`, and not `*anyopaque`?"  
    A `*anyopaque` is an address. Nothing tells you what is behind it.

    An `Any` carries the type id next to the address.

    So `fromAny` can check the type before it gives you the struct.

---

## Through a queue

A `std.Io.Queue` stores a copy of what you put in.

A connection must not be copied. So the queue carries its `Any`.

```zig
--8<-- "examples/003-timeout_list.zig:queue"
```

The full program: [Timeout list and a queue](../examples/003-timeout_list.md){target="_blank" rel="noopener"}.

---

## A handler map

The receiver does not even have to know the type.

Keep one handler per type, in a map keyed by the type id:

```zig
--8<-- "examples/004-handler_map.zig:register"
```

The dispatch looks up the handler, and gives it `ptr`:

```zig
--8<-- "examples/004-handler_map.zig:dispatch"
```

The handler casts `ptr` to its own type:

```zig
--8<-- "examples/004-handler_map.zig:handler"
```

- The dispatch never names a type.
- The map matched the type id, so the cast is right.
- A type with no handler is counted, not cast.

The full program: [Handler map](../examples/004-handler_map.md){target="_blank" rel="noopener"}.

---

## A large struct in a union field

Small events travel by value in a tagged union.

A union field stores a copy of what you put in.

A 4 KB buffer should not be copied. So the field is an `Any`:

```zig
--8<-- "examples/005-large_struct_in_union.zig:event"
```

The handler gets the `Download` back with `fromAny`:

```zig
--8<-- "examples/005-large_struct_in_union.zig:handle"
```

Each `Event` stays small.

The full program: [Large struct in a union](../examples/005-large_struct_in_union.md){target="_blank" rel="noopener"}.

---

## The struct must stay alive

An `Any` does not keep your struct alive.

- The struct MUST stay alive while its `Any` is in a queue, a map or a union.
- *Paternitas* checks the type. It does not check the lifetime.

---

## Without a TypedNode

`toAny` and `fromAny` work for every struct.

The struct does not need a TypedNode.

[Type ids, listless and nodeless](type-ids.md) shows that case.
