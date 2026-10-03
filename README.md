# paternitas

Put different struct types in one Zig std list, and get each one back as
itself, or get null.

Zig 0.16.0. It needs only `std`, and it allocates nothing.

*Paternitas* is Latin for "fatherhood".

## Two uses

1. **One list, many types.** Several struct types share one std list. Each
   one comes back as itself, or you get null.
2. **Pass it on, handle by type.** A struct leaves its list for a queue, a
   map or a union field, as an `AnyParent`. The other side gets it back, or
   picks a handler by its type. Nothing is copied.

## Two words first

Zig's std lists are intrusive and type-erased. Here is what the two words
mean, and what each one costs you.

### Intrusive

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

### Type-erased

The list sees a `Node`, never your `Message`. That is why one
`std.DoublyLinkedList` serves every struct type, with one copy of its code.

The cost is that the type is gone. When a Node comes out of the list, only
you know which struct it is in.

paternitas keeps the erasure. It writes the type next to the Node when the
struct goes in, and checks it when the Node comes out.

## One list, many types: the problem

Zig's std lists are intrusive. You put a `Node` inside your struct, and the
list links the Nodes. To get your struct back, you call `@fieldParentPtr`.

`@fieldParentPtr` trusts you. It returns whatever type you ask for.

This comes from the ziggit thread
[New LinkedList API footgun](https://ziggit.dev/t/new-linkedlist-api-footgun/10853).
Two vendors put their items in the same list.

```zig
const L = struct {
    data: u32,
    node: std.SinglyLinkedList.Node = .{},
};
const M = struct {
    data: u8,
    node: std.SinglyLinkedList.Node = .{},
};

var l: L = .{ .data = 1234567 };
var m: M = .{ .data = 255 };

var list: std.SinglyLinkedList = .{};
list.prepend(&m.node); // vendor B
list.prepend(&l.node); // vendor A

const node = list.popFirst().?;
const x: *M = @fieldParentPtr("node", node); // it is an L
```

It compiles and it runs. `x` points at an `L`, and `x.data` reads whatever
byte is there. Nothing tells you.

## The same code with paternitas

```zig
const L = struct {
    data: u32,
    tnode: paternitas.SinglyTypedNode = .{},
};
const M = struct {
    data: u8,
    tnode: paternitas.SinglyTypedNode = .{},
};
const TypedL = paternitas.Typed(L);
const TypedM = paternitas.Typed(M);

var l: L = .{ .data = 1234567 };
var m: M = .{ .data = 255 };
TypedL.setTypeId(&l);
TypedM.setTypeId(&m);

var list: std.SinglyLinkedList = .{};
list.prepend(TypedM.node(&m)); // vendor B
list.prepend(TypedL.node(&l)); // vendor A

const node = list.popFirst().?;
const as_m: ?*M = TypedM.parentFromNode(node); // null: the Node is in an L
const as_l: ?*L = TypedL.parentFromNode(node); // the L, data 1234567
```

What changed:

- `SinglyTypedNode` replaces the std Node. It is the std Node with a type
  check added.
- `DoublyTypedNode` is the one for `std.DoublyLinkedList`. `STNode` and
  `DTNode` are short for the two.
- `Typed(L)` does the `@fieldParentPtr` work for `L`, and checks the type.
  You never write the field's name. Declare it once per struct.
- `setTypeId` writes the struct's type into its TypedNode. Call it once,
  before the struct goes in a list. Without it, `parentFromNode` returns
  null.
- `parentFromNode` checks the type first. The wrong type gets null.

The list is still the plain std list. Its calls do not change.

## Move your code to paternitas

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

## Pass it on, handle by type

Most other containers are non-intrusive: `std.Io.Queue`, `std.ArrayList`,
a hash map, a union field. They store a copy of each item you put in. A
large struct, or one that must not be copied, does not fit. A
`*Connection` fits, but it carries only a `Connection`.

Put in an `AnyParent`. It is the struct's address and its type id, two
words. The container copies the two words, never your struct.

```
Message                 Connection
   | toAny                  | toAny
   v                        v
+------------------------------------------+
|  a non-intrusive container of AnyParent  |
|  std.Io.Queue, std.ArrayList, a map      |
+---------------------+--------------------+
                      |
         +------------+-------------+
         v                          v
TypedConnection.fromAny(any)   handlers.get(any.type_id)
 -> *Connection, or null        -> the handler for its type
```

Get the struct back:

```zig
var buffer: [4]paternitas.AnyParent = undefined;
var queue: std.Io.Queue(paternitas.AnyParent) = .init(&buffer);

TypedConnection.setTypeId(&connection);
try queue.putOne(io, TypedConnection.toAny(&connection));

// on the other side
const any: paternitas.AnyParent = try queue.getOne(io);
const c: *Connection = TypedConnection.fromAny(any) orelse return error.WrongParent;
// c is the same connection, not a copy
```

Or pick a handler by type. The code that picks it never names a type:

```zig
var handlers: std.AutoHashMap(paternitas.TypeId, Handler) = .init(allocator);
try handlers.put(TypedMessage.typeId(), onMessage);
try handlers.put(TypedJob.typeId(), onJob);

// the event loop
if (handlers.get(any.type_id)) |h| h(any.ptr, counts);
```

The handler casts `ptr` to its own type. The map matched the type id, so
the type is right.

A union field works the same way: `parent: paternitas.AnyParent`.

Nothing is copied, so the struct MUST stay alive while its `AnyParent` is in
use.

## Do you need it?

You do not need paternitas when each list keeps one struct type, and you
know which one. Plain `@fieldParentPtr` is fine there.

You need it when:

- one std list carries several struct types, or
- a queue, a map or a union field carries them, and the code in between
  does not know the type: a mailbox, a dispatcher, an event loop.

A type check costs one pointer compare. There are no type names to compare
and no table to register in.

## What paternitas does not do

- It has no list, queue or pool of its own. You keep using std, or your own.
- It does not allocate, free or lock anything.
- It tells you the type. It does not tell you the struct is still alive.
- A type id is valid only inside one running program. A shared library gets
  its own id for the same type.

## More

- The [examples](https://g41797.github.io/paternitas/examples/001-set_type_id_and_recover/),
  one pattern each: mixed lists, a timeout list, dispatch by type, a union
  field, a chain of your own.
- The [API docs](https://g41797.github.io/paternitas/apidocs/).
- Writing your own container? `*Anchor` and `paternitas.container` are in
  the API docs.

## License

paternitas is under the MIT license.
