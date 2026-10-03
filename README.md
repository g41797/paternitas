# paternitas

Put different struct types in one Zig std list, and get each one back as
itself, or get null.

Zig 0.16.0. It needs only `std`, and it allocates nothing.

*Paternitas* is Latin for "fatherhood".

## The problem

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
- `Typed(L)` gives you the calls for `L`. Declare it once per struct.
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
                             | | anchor  type: Message | |
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
const TypedMessage = paternitas.Typed(Message);

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

## Beyond the std list

Intrusive std lists do not copy your struct. The Node lives inside your
struct, and the list links the struct where it is.

Most other containers are non-intrusive. They know nothing of your struct,
and they store a copy of each item you put in: `std.Io.Queue`,
`std.ArrayList`, a hash map. A union field holds a copy too.

Put in a pointer instead, and only the pointer is copied. Your struct
stays where it is. But a `*Connection` carries only a `Connection`.

So put in a pointer into the struct. You have two to choose from:

- `*Node`. It works when every struct in the container has the same Node
  kind: all `SinglyTypedNode`, or all `DoublyTypedNode`. The receiver gets
  the struct back with `parentFromNode`.
- `*Anchor`. It works for every struct, singly or doubly. The receiver gets
  the struct back with `parentFromAnchor`.

When in doubt, use `*Anchor`. A struct can change its Node kind later, and
the container does not have to change with it.

> *Da ubi consistam, et terram movebo.*
>
> Give me a place to stand, and I will move the Earth. — Archimedes

The Anchor is that place in your struct. Any code can hold it, whatever
the struct's type or Node kind. paternitas reaches everything else from it.

```
Message                  Connection
+----------------+       +----------------+
| tnode          |       | tnode          |
|   node         |       |   node         |
|   anchor <--+  |       |   anchor <--+  |
+-------------|--+       +-------------|--+
              |                        |
       *Anchor|                 *Anchor|
     +--------+------------------------+--------+
     |  a non-intrusive container of *Anchor    |
     |  std.Io.Queue, std.ArrayList, a map      |
     |  any struct type, any Node kind          |
     +--------------------+---------------------+
                          |
                          v
       TypedConnection.parentFromAnchor(a)
          -> *Connection, or null for another type
```

```zig
var buffer: [8]*paternitas.Anchor = undefined;
var queue: std.Io.Queue(*paternitas.Anchor) = .init(&buffer);

TypedConnection.setTypeId(&connection);
try queue.putOne(io, TypedConnection.anchor(&connection));

// on the other side
const a = try queue.getOne(io);
if (TypedConnection.parentFromAnchor(a)) |c| {
    // c is the same connection, not a copy
}
```

The same `*Anchor` fits in a hash map, a union field, or a C callback's
context.

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

## License

paternitas is under the MIT license.
