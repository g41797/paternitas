# Zelda and Paternitas

Zelda and Paternitas both work with intrusive data structures in Zig.

They solve different problems.

Zelda makes the **intrusive list itself type-safe**.

Paternitas makes a **type-erased intrusive Node recognizable**.

This difference is the main design boundary.

---

# Zelda

Zelda is a type-safe intrusive linked-list library.

The Parent contains the link fields directly:

```zig
const Monster = struct {
    kind: MonsterKind,
    mana: u16,
    health: u16,

    next: ?*@This(),
    previous: ?*@This(),

    pub usingnamespace zelda.doublyLinkedList(@This(), .next, .previous);
};
````

The list is specialized for `Monster`.

Conceptually:

```text
Monster
   |
   +-- next
   +-- previous
   |
   +-- Monster.DoublyLinkedList
```

The important property is that the pointers are already typed:

```text
*Monster
```

rather than:

```text
*std.DoublyLinkedList.Node
```

Zelda therefore does not need to recover the Parent with `@fieldParentPtr`.

The compiler already knows the Parent type.

Zelda's author describes this as moving the responsibility for keeping different
intrusive lists apart from the programmer to the compiler. ([Ziggit][1])

---

# Paternitas

Paternitas starts from a different requirement.

The Node is deliberately type-erased.

A Parent contains:

```text
Parent
 |
 +-- Node
 |
 +-- TypeId
 |
 +-- application data
```

The Node can travel through code that does not know the Parent type.

Later:

```text
Node
 |
 v
TypeId
 |
 v
recognize Parent
 |
 v
Parent
```

For example:

```zig
const Message = struct {
    node: std.DoublyLinkedList.Node = .{},
    type_id: paternitas.TypeId = null,

    text: []const u8,
};
```

The Node can be passed as:

```zig
*std.DoublyLinkedList.Node
```

without knowing that it belongs to `Message`.

Later:

```zig
if (MessageInfo.tryFrom(node)) |message| {
    process(message);
}
```

Paternitas checks the TypeId before recovering `Message`.

---

# The fundamental difference

The two designs can be shown side by side.

```text
ZELDA

Parent
  |
  +-- typed links
       |
       v
     *Parent
       |
       v
 typed intrusive list
```

versus:

```text
PATERNITAS

Parent
  |
  +-- Node
  +-- TypeId
       |
       v
    type-erased Node
       |
       v
   generic / erased code
       |
       v
    TypeId check
       |
       v
     *Parent
```

Zelda preserves the Parent type.

Paternitas deliberately erases it.

That is not a small implementation difference.

It is the reason for the two projects.

---

# What Zelda gives you

Zelda's main benefit is compile-time type safety for intrusive lists.

For example:

```zig
const Monster = struct {
    next: ?*@This(),
    previous: ?*@This(),

    pub usingnamespace zelda.doublyLinkedList(
        @This(),
        .next,
        .previous,
    );
};
```

The resulting list is specialized for `Monster`.

A Monster list deals with:

```text
*Monster
```

rather than an untyped intrusive Node.

This prevents a major class of mistakes:

```text
Monster list
    |
    +-- Monster       OK
    |
    +-- Job           compile-time problem
```

The list does not need to discover the type later.

The type is already part of the list.

---

# What Paternitas gives you

Paternitas allows:

```text
one erased structure
       |
       +-- Message
       +-- Job
       +-- Timer
       +-- ...
```

The common representation can be:

```text
*Node
```

The receiving code does not need to know which Parent type produced it.

It can ask:

```text
"Is this a Message?"
```

through the TypeId.

This enables:

```text
erased transport
      |
      v
Node
      |
      +-- Message
      +-- Job
      +-- Timer
```

That is the important capability that Zelda does not try to provide.

---

# Homogeneous versus heterogeneous structures

This is probably the clearest practical distinction.

## Zelda

Naturally fits:

```text
List<Monster>
```

or:

```text
List<Job>
```

or:

```text
List<Timer>
```

Each list is specialized for one Parent type.

Conceptually:

```text
Monster.DoublyLinkedList
Job.DoublyLinkedList
Timer.DoublyLinkedList
```

This is exactly what Zelda is designed to do. ([Ziggit][1])

---

## Paternitas

Naturally fits:

```text
List<Node>
```

containing:

```text
Message
Job
Timer
Message
Job
```

The structure does not know the Parent types.

The consumer can recognize them later.

This makes Paternitas suitable for heterogeneous intrusive structures.

---

# Type safety

The two projects put type safety in different places.

## Zelda

Type safety is primarily:

```text
compile time
```

The compiler knows:

```text
this is a Monster
```

There is no runtime type recognition step.

This is a strong advantage when the data structure is homogeneous.

---

## Paternitas

Type safety has two stages:

```text
comptime
    |
    +-- establish Parent / Node / TypeId relationship

runtime
    |
    +-- recognize the erased Node
```

The helper knows at compile time:

```text
Message
   |
   +-- Node
   +-- TypeId
```

But after the Node is erased, runtime TypeId comparison is required.

This is the price of type erasure.

---

# `@fieldParentPtr`

This is another important difference.

Zelda's design specifically avoids needing `@fieldParentPtr` during normal list
operation because its links point directly to the Parent type. The author
describes avoiding the offset calculation as one of the safety advantages. ([Ziggit][1])

Paternitas deliberately uses the opposite model.

The erased Node does not know its Parent.

Therefore recovery needs the equivalent of:

```text
Node
  |
  v
Parent address
```

and then:

```text
Parent.type_id == expected TypeId
```

The TypeId check makes the erased crossing explicit.

---

# Zelda's safety model

Zelda makes the following mistake difficult:

```text
take Node from one Parent type
put it into another Parent-type list
```

because the links and list operations are specialized.

The compiler has the type information.

This is a strong form of safety.

---

# Paternitas' safety model

Paternitas accepts that the type has been erased.

Therefore it cannot provide the same compile-time guarantee.

Instead it provides:

```text
Node
  |
  v
candidate Parent
  |
  v
TypeId comparison
  |
  +-- wrong -> null
  |
  +-- right -> Parent
```

This is weaker than keeping the type statically.

But it solves a problem that static typing cannot solve:

```text
"I have an erased object. Which Parent type is behind it?"
```

---

# Zelda and multiple intrusive links

Zelda has another important advantage.

A Parent can contain several separate intrusive link pairs.

For example:

```zig
const Monster = struct {
    active_next: ?*@This(),
    active_previous: ?*@This(),

    visible_next: ?*@This(),
    visible_previous: ?*@This(),
};
```

Zelda can specialize the intrusive list machinery separately for the two
relationships.

The project's author explicitly describes calling the Zelda list generator
multiple times for disjoint link fields and renaming the resulting operations.
([Ziggit][1])

This is a very good fit for:

```text
Monster
 |
 +-- active list
 |
 +-- visible list
 |
 +-- another list
```

Paternitas intentionally does not try to solve this problem.

Its core model is:

```text
one Parent
    |
    +-- one Paternitas Node
    +-- one TypeId
```

Paternitas could be extended to multiple Node identities, but that would make
the core more complicated and would weaken its simple purpose.

---

# Zelda and standard library Nodes

Zelda takes a different route from the current Zig standard intrusive list API.

The standard library's intrusive `Node` is deliberately generic. Its intended
use is to embed the Node and recover the containing object with
`@fieldParentPtr`. ([GitHub][2])

Zelda instead puts typed pointers into the Parent:

```text
Parent
 |
 +-- next: ?*Parent
 +-- previous: ?*Parent
```

This removes the generic Node boundary.

Paternitas keeps that generic Node boundary.

Therefore Paternitas can work naturally with the standard intrusive Node model.

---

# Paternitas is closer to the standard Node model

This matters for Matryoshka.

Matryoshka already has an infrastructure representation similar to:

```text
erased Node
+
type identity
```

Paternitas extracts this idea.

Therefore:

```text
std.Node
   +
TypeId
```

is a natural Paternitas shape.

Zelda would instead move Matryoshka toward:

```text
*SpecificParent
```

throughout each container.

That would be a different architecture.

---

# Compile-time versus runtime cost

## Zelda

The Parent type is known at compile time.

Therefore list operations can be specialized for:

```text
Monster
Job
Timer
```

There is no TypeId comparison for normal list operations.

The tradeoff is that the compiler may generate specialized code for each
Parent type. Zelda's author explicitly identifies this as a possible downside,
especially for highly constrained embedded systems where avoiding duplicate
specialization may matter. ([Ziggit][1])

---

## Paternitas

The basic type-erased representation is shared:

```text
*Node
```

Type recognition requires a runtime TypeId comparison.

The tradeoff is:

```text
runtime type check
```

in exchange for:

```text
type-erased transport
```

The Paternitas TypeId is just an identity pointer, so recognition does not need
strings, integer registration, or a global type table.

---

# Code generation

Zelda generates operations specialized for the Parent.

Paternitas also generates code at comptime, but for a different reason.

Zelda:

```text
comptime Parent
      |
      v
typed list operations
```

Paternitas:

```text
comptime Parent
      |
      +-- find Node
      +-- find TypeId
      +-- create TypeInfo
      +-- create recovery operations
```

So both use Zig comptime heavily.

The generated code serves different goals.

---

# Runtime representation

This is a useful comparison.

## Zelda

A Parent can look like:

```text
Monster
+------------------+
| data             |
|                  |
| next: *Monster   |
| prev: *Monster   |
+------------------+
```

The links directly describe the Parent.

---

## Paternitas

A Parent looks like:

```text
Message
+-----------------------------+
| data                        |
|                             |
| Node                        |
| TypeId --------------------+----> Message TypeInfo
+-----------------------------+
```

The Node is generic.

The TypeId supplies the erased type information.

---

# Failure modes

## Zelda

Many type mistakes become compile-time errors.

The programmer may still make ordinary pointer/lifetime/list-state mistakes.

For example:

```text
dangling Parent
incorrect lifetime
concurrent mutation
corrupted link
```

are not magically solved.

But the Parent type of the link is known statically.

---

## Paternitas

Paternitas adds one runtime failure mode:

```text
TypeId mismatch
```

This is expected and useful for heterogeneous structures.

But Paternitas also has a fundamental limitation:

```text
TypeId does not prove pointer validity.
```

If an arbitrary pointer is already invalid, reading its TypeId is not made safe
by Paternitas.

Likewise:

```text
freed Parent
corrupted Node
incorrect Node address
data race
```

remain application-level problems.

---

# Multiple Parent types in one structure

This is where Paternitas has a capability Zelda deliberately does not target.

Suppose:

```text
Mailbox
 |
 +-- Message
 +-- Job
 +-- Timer
```

The mailbox does not need to know all three types.

It can transport:

```text
Node
```

The receiver can perform:

```text
if MessageInfo.tryFrom(node) ...
if JobInfo.tryFrom(node) ...
if TimerInfo.tryFrom(node) ...
```

This is natural type-erased programming.

With Zelda, the normal design would instead be to have typed containers:

```text
Message.DoublyLinkedList
Job.DoublyLinkedList
Timer.DoublyLinkedList
```

If a heterogeneous container is required, another type-erasure mechanism has to
be added around Zelda.

---

# When Zelda is the better fit

Use Zelda when:

* The collection has one known Parent type.
* You want compile-time type safety.
* You want list operations to work directly with `*Parent`.
* You want to avoid `@fieldParentPtr`.
* You want several intrusive lists inside one Parent.
* You want the compiler to reject mixing different Parent types.
* The list itself is an important abstraction.
* You do not need runtime type recognition.

Typical examples:

```text
List<Job>
List<Connection>
List<Monster>
List<FreeBlock>
List<Transaction>
```

Especially:

```text
one type
+
one or several intrusive relationships
```

---

# When Paternitas is the better fit

Use Paternitas when:

* The object must cross a type-erased boundary.
* Several Parent types share one erased representation.
* A generic infrastructure component should not know application types.
* The object must later be recognized and recovered.
* You want to use the standard Zig intrusive Node.
* You need runtime type identity.
* You want application types to remain independent of the infrastructure.
* The container or transport should operate on an erased Node.

Typical examples:

```text
heterogeneous queue
heterogeneous mailbox
generic dispatcher
message transport
plugin objects
event objects
work items
type-erased pools
generic intrusive infrastructure
```

---

# When neither is necessary

If there is no need for type erasure and no need for intrusive storage, a normal
typed container may be simpler.

For example:

```text
ArrayList(Job)
```

may be preferable to introducing intrusive links at all.

Intrusive structures are useful when their particular properties matter:

* no separate node allocation
* object participates directly in the structure
* stable object address
* several simultaneous intrusive relationships
* custom allocation or pooling
* low-level control

The choice between Zelda and Paternitas happens after the decision to use
intrusive structures.

---

# Side-by-side

| Question                            | Zelda                     | Paternitas                                            |
| ----------------------------------- | ------------------------- | ----------------------------------------------------- |
| Main purpose                        | Type-safe intrusive lists | Type-erased intrusive objects                         |
| Parent type known to container?     | Yes                       | No                                                    |
| Node type                           | `*Parent` links           | Standard erased Node                                  |
| Type recovery                       | Usually unnecessary       | Central operation                                     |
| Runtime TypeId                      | No                        | Yes                                                   |
| Heterogeneous collection            | Not the main model        | Natural                                               |
| Homogeneous collection              | Excellent fit             | Possible, but unnecessary                             |
| Standard `std.*LinkedList.Node`     | Not the central model     | Central model                                         |
| `@fieldParentPtr`                   | Avoided                   | Used/encapsulated for recovery                        |
| Multiple intrusive lists per Parent | Natural                   | Not core                                              |
| Compile-time type checking          | Strong                    | Strong for helper/layout, runtime check after erasure |
| Runtime type check                  | No                        | Yes                                                   |
| Global type registry                | No                        | No                                                    |
| Allocation required                 | No                        | No                                                    |
| Container implementation            | Yes                       | No                                                    |
| Generic type-erasure mechanism      | No                        | Yes                                                   |
| Matryoshka relevance                | Indirect                  | Direct                                                |

---

# The most important architectural difference

Zelda says:

> Do not erase the Parent type.

Paternitas says:

> Erase the Parent type here, but leave enough information to recognize it later.

These are both valid approaches.

They should not be merged into one abstraction.

---

# Could Paternitas use Zelda internally?

Technically, parts of the ideas could be combined.

For example:

```text
Zelda-style typed intrusive list
             |
             v
        type-erased bridge
             |
             v
         Paternitas
```

But that should be an application-level composition.

It should not make Paternitas depend on Zelda.

Paternitas' useful property is precisely that its erased representation is small
and independent of a particular list implementation.

---

# Could Zelda use Paternitas?

It is possible, but normally unnecessary.

If Zelda already knows:

```text
*Monster
```

then storing:

```text
TypeId(Monster)
```

adds information it does not need.

Paternitas becomes useful only when Zelda's typed Parent crosses into an erased
world.

For example:

```text
Zelda typed list
       |
       v
erase
       |
       v
Paternitas Node + TypeId
       |
       v
generic infrastructure
```

That is a reasonable boundary.

---

# Relation to Matryoshka

This comparison clarifies why extracting Paternitas from ztk makes sense.

Matryoshka has two different needs.

Inside a typed application:

```text
specific item type
```

is useful.

Inside infrastructure:

```text
erased item
```

is useful.

Matryoshka's `PolyNode` approach belongs to the second category.

Paternitas isolates that mechanism:

```text
Parent
   |
   +-- Node
   +-- TypeId
```

and does not bring along:

```text
Mailbox
Pool
Slot
scheduler
I/O
```

Zelda solves a different problem.

It could be useful for a Matryoshka application when a local homogeneous
intrusive list is desired.

Paternitas is more directly related to the Matryoshka type-erasure mechanism.

---

# A useful rule

A simple decision rule is:

```text
Do I know the Parent type here?

    |
    +-- YES
    |     |
    |     +-- Need a typed intrusive list?
    |             |
    |             +-- YES -> Zelda
    |
    +-- NO
          |
          +-- Must recover the Parent later?
                  |
                  +-- YES -> Paternitas
```

Or even shorter:

```text
Zelda     = keep the type

Paternitas = erase the type, recognize it later
```

---

# Final design position

Zelda and Paternitas should remain separate projects/concepts.

Zelda is about:

```text
typed intrusive containers
```

Paternitas is about:

```text
intrusive type erasure
```

The overlap is the intrusive Node.

The difference is what happens to the Parent type.

Zelda keeps it.

Paternitas deliberately removes it and adds `TypeId` so it can be recovered.

That distinction gives Paternitas a clear reason to exist beyond being another
intrusive-list implementation.


One especially important conclusion for the Paternitas design is that **Zelda does not make Paternitas redundant**. Zelda removes the need for type recovery *when the list can remain typed*. Paternitas addresses the case where the type **must actually disappear at an infrastructure boundary**. 


[1]: https://ziggit.dev/t/zelda-type-safe-intrusive-linked-lists/9665?utm_source=chatgpt.com "Zelda: Type Safe Intrusive Linked Lists - Showcase - Ziggit"
[2]: https://github.com/ziglang/zig/blob/master/lib/std/SinglyLinkedList.zig?utm_source=chatgpt.com "zig/lib/std/SinglyLinkedList.zig at master · ziglang/zig · GitHub"

