![](kitchen/docs/assets/matryoshka-ztk-logo.png)

---

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/matryoshka-ztk/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/linux.yml)
[![Windows](https://github.com/g41797/matryoshka-ztk/actions/workflows/windows.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/windows.yml)
[![macOS](https://github.com/g41797/matryoshka-ztk/actions/workflows/mac.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/mac.yml)
[![Docs](https://github.com/g41797/matryoshka-ztk/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/docs.yml)

---

A small Zig toolkit.

- 800+ lines of code.
- 800+ lines on this page, about the ideas behind it.

You can read all of it in an evening. The code, and the reasons for it.

It is for one part of a background process:

- not the I/O part
- the part that works with your data

---

This page:

- starts with a process you have probably built
- then looks at the everyday problems that process runs into
- brings in the toolkit only when a problem needs it

---


# A process you have probably built

---


A background process often starts with something simple.

Several threads work together.

Each thread has a responsibility:

- one part receives requests
- another does the actual work
- another sends results back

```text
   clients            the I/O part                 the process part

   client 1 ---->  handler 1 ---\
   client 2 ---->  handler 2 ----\
                                  >---- shared queue ----> worker A
   client 3 ---->  handler 3 ----/                    \--> worker B
   client 4 ---->  handler 4 ---/
```

The I/O side deals with:

- sockets
- parsing
- timeouts
- and the rest of it

In Zig 0.16 that side has a name. It is `std.Io`, and your process already
holds one.


The process side deals with your data:

- `Customer`
- `Order`
- `Invoice`
- `Payment`
- whatever your application needs

The process side should not care how a request arrived:

- over TCP
- or from a file

The two sides:

- need to work together
- should not need to know much about each other

Starting the threads is usually not the hard part.

The hard part is everything that happens between the threads.

That is where the boring problems start...



---

## Threads need to exchange work

---


A handler and a worker run on different threads.

- The handler turns an incoming request into an application struct.
- The worker processes it.
- The result has to get back.

Neither can do the other's job.

So we need a way to pass work between threads.

```text
   handler 1 ---\                              /---> worker A
   handler 2 ----+---> requests queue ---------+
   handler 3 ---/                              \---> worker B

   handler 1 <--\                              /---- worker A
   handler 2 <---+---- replies queue ----------+
   handler 3 <--/                              \---- worker B
```


---

## The queue is at the centre

---


- Every request crosses it.
- Every reply crosses back.

So sooner or later, every hard question in the process becomes a question
about the queue.

- **A worker waits for work.**
    - For how long?
    - What stops the wait?
- **The process shuts down.**
    - Requests are still queued. Who frees them?
    - How do you stop without losing track of work that is still on its way?
- **A handler is too fast.**
    - How many requests may it queue before it must stop?
- **A cancel arrives.**
    - It should not wait behind a hundred requests.
    - And the wait itself may be cancelled, because `std.Io` can cancel a wait.

A queue written in an afternoon rarely answers these.

Each answer added later is one more thing to get right.


---

## Moving work should not allocate

---


This is where a normal queue can become surprisingly expensive.

The request already exists.

The handler built it.

There is usually no reason to create another copy of it just to put it into a
queue.

A typical queue stores a copy of whatever you push:

- it allocates room for the copy
- it grows its buffer when it is full

Count the pushes:

- every request is pushed once
- every reply is pushed once

That is an allocation at every crossing.

And it is on the busiest path of the process.

A request should not be copied just because it moved from one thread to
another.


---

## The queue should not know your types

---


The queue is infrastructure.

It is written once.

Today it may carry:

- `CreateOrder`
- `PayInvoice`

Tomorrow it may carry:

- `CancelOrder`
- `SendEmail`
- `Shutdown`

Changing the application should not mean changing the queue.

The usual workarounds, and what each one costs:

- **An `*anyopaque`.**
    - The type is gone.
    - The cast back is a guess, and the alignment is a guess too.
- **A tagged union of every message.**
    - Zig has them, and they are pleasant to write.
    - But the union changes with every feature, and so does everything that
      switches on it.
    - Every value is as large as the largest member.
- **An interface, a vtable in every message.**
    - Every message carries the pointer.
    - The queue still stores something it cannot name.

What the worker needs is simple:

- **ask what arrived**
- **get a checked answer**


---

## Some structs should not be copied

---


Consider a request that contains a large buffer.

Or other structs:

- a struct that contains a mutex
- a struct that keeps an OS resource, such as a file handle
- a struct with pointers that point into the struct itself
- a struct whose address has already been given to another part of the process

Some structs simply should not be copied.

A copy is a different struct at a different address.

The useful thing to move is their address.

```text
        +-------------------+
        | Request           |
        |                   |
        | application data  |
        +-------------------+
                 ^
                 |
              address
                 |
        +--------+--------+
        |      queue      |
        +-----------------+
```

So the request stays where it is.

**Only its address moves.**

And moving that address should still not allocate.


---

## Where requests come from

---


Now look at the handler again.

```text
   client connects
         |
         v
   handler allocates a request
         |
         v
   request goes to a worker, the reply comes back
         |
         v
   handler frees the request
         |
         v
   next client: allocate again
```

One allocation and one free per client.

Thousands per second:

- the same struct
- the same size
- every time

Often we can do better.

Keep freed requests and reuse them.

That raises a new question:

- **Kept where?**
- **Shared by which threads?**


---

## Reuse needs rules

---


Keeping a request is not enough.

- **It still contains the previous client's data.**
    - Someone must clear it.
- **A load spike leaves thousands of them kept.**
    - How many should stay?
- **None are free.**
    - Make a new one, wait for one, or refuse?
- **Different types want different answers.**
    - A small request and a large buffer are not kept the same way.
- **The process stops.**
    - Everything still kept must be freed.

These are decisions about your types.

The code that keeps them:

- should provide the mechanism
- should not invent the policy


---

# The same process, with this toolkit

---


- Same handlers.
- Same workers.
- Same threads, created by your process.
- Same `Io`, made by your process.

What changes is the line between them.

**The idea in one sentence:**

- the process passes around pointers to structs that already exist
- the code in the middle does not need to know what those structs are

The sections below answer the problems above, in the same order.


---

## A queue that answers the hard questions

---


The shared queue becomes a **mailbox**.

- **A wait has an end.**
    - `receive` takes a timeout in nanoseconds, or null to wait forever.
    - It fails with `error.Closed`, `error.Timeout` or `error.Wakeup`.
    - And with `error.Canceled`, because a `std.Io` wait can be cancelled.
- **A wait can be stopped.**
    - `wakeUpAll` returns every waiter with `error.Wakeup`.
- **Shutdown loses nothing.**
    - `close` gives back everything still queued.
    - You release it by your own rules.
    - Nothing leaks.
- **A fast handler hits a limit.**
    - `sendLimited` fails with `error.Limit`.
    - It fails once that many requests of its type are queued.
- **Urgent work goes first.**
    - `sendOob` puts it at the front.
- **A batch arrives in one call.**
    - `receiveAll`.

`close` and `receiveAll` hand you back a `Queue`, by value.

- Not an out-parameter. You get the chain as a value and it is yours.
- Never write `_ = mbx.close()`. That drops the requests it just gave you.

A mailbox is made by its own call, not by your helper.

- `mbox.new` takes your allocator and your `Io`.
- `destroy` gives the memory back, and it is a method on the mailbox.

**Why two, where one used to do.** Zig 0.16 moved files, sockets, time and
concurrency behind `std.Io`. An allocator is no longer the whole environment,
so every call that might make or release something takes both.


---

## The request carries its own link

---


The problem is a queue that allocates a node per push.

So the link lives inside the request.

That is what *intrusive* means.

```text
   mailbox
      |
      v
   +- Request 1 -------------------+
   |  client_id   path             |
   |  [ inner | link ]---+         |
   +---------------------|---------+
                         |
                         v
   +- Request 2 -------------------+
   |  client_id   path             |
   |  [ inner | link ]---+         |
   +---------------------|---------+
                         |
                         v
   +- Request 3 -------------------+
   |  client_id   path             |
   |  [ inner | link: itself ]     |   the last one links to itself
   +-------------------------------+
```

- Sending links the request in.
    - Nothing is allocated.
- Receiving unlinks it.
    - Nothing is freed.
- The request never moves.
    - Only its address travels.

The last link points at itself, and that is not decoration.

- A null last link cannot tell a chain of one from a request on no chain.
- This one can, with a single compare.


---

## The request carries its own type

---


The link lives in a small embedded part, the **inner**.

The application struct around it is the **outer**.

Your `Request` is an outer.

```text
   Outer: Request
   +---------------------------+
   | client_id                 |
   | path                      |
   |                           |
   | +-----------------------+ |
   | | Inner                 | |
   | |   node                | |
   | |   id                  | |
   | +-----------------------+ |
   +---------------------------+
```

The inner has two fields:

- `node` — the next inner in the chain
- `id` — what the struct it sits in is

That second field is written once, when the struct is made.

- The toolkit writes it. You do not.
- It stays there for as long as the struct exists.
- So the struct always knows what type it is, even after it has been passed
  around as a plain `*Inner`.

**The id is not a language type id.** Zig has no runtime one.

- Each outer type has exactly one description, and it is `const`, so it lives
  in read-only memory at an address that never changes.
- The id is that address.
- Two outers of one type answer the same id. Two types answer two.
- You never read anything out of it. You pass it, and you compare it.

An outer that was never stamped has a null id.

- So a zeroed struct is an unstamped outer, not an accidental one.
- `std.mem.zeroes` gives you a valid unstamped `Inner`, and so does `.{}`.

The mailbox only sees an `*Inner`.

It never learns what a `Request` is.

When the worker needs its type back, it asks and gets a checked answer.

```text
              *Inner
                 |
                 v
            check the id
                 |
          +------+------+
          |             |
      *Request         null
```

- `fromSlot` returns the outer.
    - Or null, if it is not the type asked for.
- `mustFromSlot` panics on a mismatch, and the message names both types.
- An outer whose type was never written is refused.
    - It is not guessed at.

**`node` is `std.SinglyLinkedList.Node`.**

- So an outer of yours may go onto a plain `std.SinglyLinkedList`.
- One at a time, and out of this toolkit's `Queue` first.
- The two chains disagree about the last link — ours points at itself, std's
  is null — and one field cannot hold both.
- `std` hands a node back still pointing into the list it left, so the way
  back in refuses it until you clear it.


---

## One struct, two addresses

---


Think of the crossing as a cast that the helper makes safe.

Your `Request` and the inner inside it are at two different addresses.

```text
   one Request in memory
   +-------------+---------------+---------------------------+
   |  client_id  |     path      |           Inner           |
   +-------------+---------------+---------------------------+
   ^                             ^
   |                             |
   |                             +-- *Inner
   |                                 this address travels
   |                                 the mailbox and the pool see only this
   |
   +-- *Request
       this address your code works with
```

A plain cast only changes how an address is read.

- It does not move the address.
- It has nothing to check the type against.
- In Zig it loses the alignment too, so `@alignCast` becomes your problem.

The helper does all of it.

- It moves the address, from the inner back to the start of your struct.
- It checks the type first, because the inner carries it.

So the crossing back is one call.

- `fromSlot` gives you your `*Request`, or `null` if it is not one.
- `mustFromSlot` panics instead of returning `null`.

**And you never work out the distance yourself.**

- Move the inner to another place in the struct and the distance changes.
- Your code does not.
- A cast you wrote by hand would be wrong from that moment on.

**Think of the inner as a handle.**

```text
                        _____
                       |     |          <- the inner
   +-------------------|     |-------+      the handle, bolted on
   |  Request                        |
   |     client_id                   |
   |     path                        |
   +---------------------------------+
```

- The handle belongs to one case, and it is bolted to that one.
- Pick the case up by the handle, and the whole case comes.
- The porter carries it by the handle, and never opens it.

The mailbox and the pool are the porter.

**So when this page says a request moves, it is the inner that moves.**

The request comes along, because the request is around it.

The rest of this page says a request is in the slot.

What is in the slot is the inner inside that request.

Both are true. The helper is what turns one into the other.


---

## The one struct you write

---


```zig
const Request = struct {
    client_id: i32 = 0,
    path: [256]u8 = undefined,
    inner: Inner = .{},
};
```

The `Inner` can sit anywhere in the struct.

- First, last, or in the middle.
- Here it is last, and nothing about that is special.

**The field's name is yours.** The helper finds it by type.

- Call it `inner`, `hdr`, `link`, anything.
- The examples in this repository call it `hdr` as often as `inner`.

**The Request's address is computed from the inner's.**

- The offset of the field in `Request` is known at compile time.
- So nothing has to be stored to find the way back:
    - no back-pointer
    - no registry
    - no map
- Exactly one `Inner` per struct of yours, as a direct field of the struct.
    - The check runs when the toolkit first uses the struct as an outer.
    - Zero or two is a compile error, and it names your type.
    - Declaring such a struct alone is not an error.

Two methods go with it:

```zig
pub fn init(self: *Request, alloc: std.mem.Allocator, io: std.Io) !void {}
pub fn finish(self: *Request, alloc: std.mem.Allocator, io: std.Io) void {}
```

- Both are required as soon as the helper creates or destroys your struct.
- An empty body is fine.
    - It means there is nothing to do when the struct is created or released.
    - Write `_ = .{ alloc, io };` and the compiler is satisfied.
- The compiler checks that they are there, and the error tells you what to
  write.

A struct you always allocate yourself needs neither.


---

## One helper per type does the boring part

---


There is nothing to be afraid of here.

- You never work out that distance yourself.
- You never write the type into the struct yourself.

One line makes a helper for your type.

```zig
const REQ = matryoshka.helper.OuterHelper(Request);

var slot: Slot = null;
try REQ.create(alloc, io, &slot);       // allocate, init, write the id, fill the slot
const req = REQ.mustFromSlot(&slot);    // the outer back, type checked
REQ.destroy(alloc, io, &slot);          // finish, empty the slot, free
```

```text
   create:   allocate --> init --> write the id --> fill the slot
                                                          |
                                                         use
                                                          |
   destroy:  free <-- empty the slot <-- finish <---------+
```

- `create` frees the outer if `init` fails.
    - The slot stays empty then.
- `destroy` on an empty slot does nothing.
    - That keeps cleanup paths simple.
- `create` calls your `init`, `destroy` calls your `finish`.
- Reading the outer back:
    - `fromSlot` and `mustFromSlot` read, and leave the slot full.
    - `moveFromSlot` and `mustMoveFromSlot` read and empty the slot.

There is nothing to instantiate and nothing to keep. A helper is a type.

**`create` is not the only way in.**

You may allocate the struct yourself.

- From your own allocator.
- On the stack.
- Or as a field of something bigger you already have.

Then write the id into it once:

```zig
var msg: Message = .{ .text = "hello", .priority = 1 };
MessageHelper.stamp(&msg);     // write the id into its inner, once
```

- Do it once per struct, before it is used anywhere.
- From then on the mailbox and the pool take it like any other request.
- `create` is the same three steps done for you: allocate, call `init`, write
  the id.

**Two questions stay apart.**

- Where does this struct come from, and when does it go away?
- How does it get from this thread to the next one?

The helper and the pool answer the first.

The mailbox answers the second.

- Change how your structs are made, and the sending code is untouched.
- Send them some other way, and the making code is untouched.


---

## The slot — read this one twice, at least

---


A request passes to someone else a few times in its life.

- You send it to a mailbox.
- You give it back to a pool.
- You destroy it.
- You pass it to an `Io.Queue`, or to any container of your own.

Each of those calls either took the request, or did not.

**So the question is: did it go, or is it still mine?**

This is not a threading question.

The same question is there in a program with one thread.

Matryoshka borrows the word from the everyday thing.

```text
   +---------------------+        +---------------------+
   |                     |        |     [ Request ]     |
   +---------------------+        +---------------------+

          empty                          full
```

- A slot is a place with room for exactly one thing.
- You can see which of the two states it is in.
- A second thing does not go in.
- Handing the thing over empties your slot.

A **slot** answers it.

You read the answer by looking at the slot.

- **Empty** — it went. It is not yours anymore.
- **Full** — it did not go. It is still yours, and still your job.

A slot is `?*Inner`. One address, or nothing.

- `send` empties your slot.
    - A refused `send` leaves the request in it.
- `put` empties it, if the pool took the request.
    - A closed pool refuses, and the request stays with you.
- `destroy` empties it, and frees the request.
- `receive` and `get` fill an empty slot.
    - Passing a full one is a checked error.

**Every one of those is a place where a request passes to someone else, and the
slot is where you look afterwards.**

```text
   handler thread                          worker thread

   slot: [ Request 1 ]                     slot: [ empty ]
        |                                        ^
        |  send                         receive  |
        |  empties this slot   fills that slot   |
        v                                        |
   slot: [ empty ]  ----->  mailbox  ------------+
```

The slot also makes cleanup simple.

Zig's `defer` and a slot are made for each other.

You can set up the cleanup first, before you create or receive anything.

```zig
var slot: Slot = null;
defer REQ.destroy(alloc, io, &slot);   // runs on every way out of the function

try REQ.create(alloc, io, &slot);      // if this fails, the slot stays empty
// ... fill in the request ...
try mbx.send(&slot);                   // if this succeeds, the slot is now empty
```

- If `create` fails:
    - the slot is empty
    - `destroy` does nothing
- If `send` fails:
    - the request is still in the slot
    - `destroy` frees it
- If `send` succeeds:
    - the slot is empty
    - `destroy` does nothing

Every path out of the function is covered by one line.

- Nothing is freed twice.
- Nothing is forgotten.

**Why is the error not enough?**

An error tells you that the call failed.

- It does not tell you where the request is.
- You would have to remember which failures took it, and which left it with you.

With a slot there is nothing to remember. You look.

- `destroy` on an empty slot does nothing.
- `destroy` on a full one frees the request.
- The same line is right on every path out, and it does not depend on a check
  you wrote.

**Cleanups also stack.**

```zig
var slot: Slot = null;
defer REQ.destroy(alloc, io, &slot);               // last resort: free it
defer pool.put(&slot) catch {};                    // first choice: give it back

try pool.get(REQ.ID, .available_or_new, &slot);
// ... use the request ...
```

- The `put` runs first, because deferred lines run in reverse order.
    - It empties the slot if the pool took the request.
- The `destroy` runs after it.
    - By then the slot is empty, so it does nothing.
- A closed pool refuses the `put`, and the slot stays full.
    - Then the `destroy` frees the request.

Neither line asks what happened. Both look.

**One more thing about all these calls.**

None of them takes the request's own address.

- `create`, `destroy`, `send`, `receive`, `get`, `put` — every call that moves
  one request takes a `*Slot`.
- A slot is not the request.
    - It is the place where the address of its inner may be, or may not.

Most libraries take the pointer instead.

This one makes you go through a slot, and that is deliberate.

- A call that takes a pointer cannot tell you whether it took the request.
- A call that takes your slot empties it, so the answer is in front of you.
- Sending twice from the same slot is a checked error, and not a request that
  went out twice.

**Why this one takes a second pass.**

- The inner and the outer are a fact about your struct. You learn it once.
- The slot is about when a request passes on, and that changes at every call
  you write.
- Nothing else here is as easy to get wrong.


---

## Requests come from a pool

---


A **pool** keeps used structs and gives them out again.

```text
        +------+
        | pool | <---------------------+
        +--+---+                       |
           |  get                      |  put
           v                           |
        Request ------->  work  -------> Request
```

- Threads share it.
    - It does its own locking, through `std.Io.Mutex`.
    - The `Io` is the one you gave it.
- It works with `*Inner`.
    - It does not depend on your outer types.
- It keeps each type separate.
    - The set of types is fixed when the pool is created.
    - Asking for one that is not in the set fails with
      `error.UnknownIdentity`, in every build.
- `get` returns a kept outer or a new one.
- `put` gives one back.

Reuse is last in, first out. What went back most recently is what comes out
next, and it is the one most likely to still be warm.

`get` takes a mode.

*None are free* can be answered in more than one way:

- `.available_or_new` — a kept one if there is one, otherwise a new one
- `.new_only` — always a new one
- `.available_only` — a kept one, or it fails with `error.NotAvailable`

`getWait` waits, with a timeout, for a kept one.

A pool is made by its own call too.

- `pool.new` takes your allocator, your `Io`, the ids it will keep, and your
  hooks.
- `destroy` gives the memory back, and it is a method on the pool.


---

## The rules of reuse are yours

---


The pool makes no decisions about your types.

It calls **hooks** you write:

- `on_get` — none are free.
    - Create a new outer.
    - Or leave the slot empty.
- `on_put` — an outer came back.
    - To keep it, clear it and leave it in the slot.
    - To drop it, free it.
- `on_close` — the pool is closing.
    - Everything still kept is passed to you, as one queue.

```zig
pub fn onPut(ptr: *anyopaque, _: usize, slot: *Slot, _: *Queue) void {
    const self: *Self = @ptrCast(@alignCast(ptr));

    if (self.count >= self.cap) {
        items.destroySlot(slot, self.alloc, self.io);
    } else {
        items.resetOnPut(slot);
        self.count += 1;
    }
}
```

The pool manages the collection.

Your code decides what reuse means for your structs.

**One thing to know about `on_close`.** A close that arrives while a `put` hook
is still running hands you both lots — what that call took, and what the hook
added. So `on_close` may be called more than once, and twice at the same time.
Write it so that is fine.


---

## Putting the pieces together

---


There is not much to the model.

We started with an ordinary background process.

The problems were ordinary ones:

- Threads need to exchange work.
- Transfer should not allocate on the normal path.
- The queue should not depend on application types.
- Some structs should not be copied.
- Repeated allocation and release can be wasteful.
- Reuse needs application rules.
- Shutdown needs a clear way to deal with what is still queued or kept.

```text
                         your application

   +------------------------------------------------+
   |                                                |
   |   Request       Order       Payment            |
   |      |            |            |               |
   |      +------------+------------+               |
   |                   |                            |
   |            each has an Inner                   |
   |                   |                            |
   +-------------------+----------------------------+
                       |
                     *Inner
                       |
              +--------+--------+
              |                 |
              v                 v
           Mbox               Pool
              |                 |
              v                 v
       between threads        reuse
```

Your application still defines the process.

The toolkit stays on the line in the middle.

That is all it needs to be.


---

## You do not have to use everything

---


The three pieces are independent.

```text
   Inner + Outer      your struct carries its own id, and a link
   Mbox               moves structs between threads
   Pool + your hooks  keeps used structs, by your rules
```

**The mailbox and the pool know nothing about each other.**

- Neither one needs the other.
- Use both, or one, or neither.

Inner and outer alone are already worth something.

- `Queue` chains your structs and allocates nothing.
    - The link is already in them.
- A `std.SinglyLinkedList` takes them too, one at a time.
- Any container of yours carries a pointer to your struct instead.
    - The container allocates for its own node.
    - Your struct is still never copied.
- Either way, the type comes back checked.

Use the part that solves your actual problem.


---

# Matryoshka

---


Now the model gets its name.

An **outer** contains an **inner**, the way a Russian doll contains a smaller doll.

Why the name:

- **The first reason: you can use any doll you want.**
    - Any struct of yours can be an outer.
- **But the main reason: it is funny.**

The names, and what each one is for:

- **Inner** — the small part inside your struct.
    - It keeps the link and the id.
    - So the mailbox and the pool never need to know your struct.
- **Outer** — your struct.
    - Your data, plus one `Inner`.
- **Helper** — one per outer type.
    - It creates, destroys and checks the type for you.
- **Slot** — one address, or none.
    - It shows whether a struct is still yours.
    - It makes cleanup simple.
- **Mbox** — moves outers between threads.
    - Without copying.
    - Without allocating.
- **Pool** — keeps used outers so they can be used again.
- **Hooks** — your code that the pool calls.
    - You decide what reuse means for your structs.

One module:

```zig
const matryoshka = @import("matryoshka");
```

That is the whole public surface. There is nothing else to import.

Inside it are five namespaces, one per file:

- `matryoshka.inner` — the inner, the slot, the id
- `matryoshka.queue` — a chain of outers
- `matryoshka.helper` — one helper per type, and the borders out
- `matryoshka.mbox` — the mailbox
- `matryoshka.pool` — the pool

`Mbox` and `Pool` are also there flat, because your process keeps one of each
for its whole life.

**There is no one list of faults.** Zig declares an error set per call, so
`send` can only fail with `error.Closed`, and `sendLimited` with that or
`error.Limit`. The two calls that wait add `Io.Cancelable`, because a wait can
be cancelled. Each call's own set is in its documentation.


---

## What this toolkit does not do

---


It is not a process framework.

- No networking.
- No file I/O.
- No event loop.
- No scheduler.
- No fibers or cooperative tasks.
- No thread creation.
- No `Io` of its own. It uses yours.

Your process decides:

- how its threads are created
- what each one does
- which `std.Io` implementation runs them

The toolkit provides the transfer and reuse pieces between them.

Use it together with whatever your process already uses for those jobs.


---

## Examples

---


`examples/` is the show cases module.

Each show case:

- is small
- shows exactly one idiom, pattern or use case
- says up front what it shows, and the steps it takes
- works, and the tests call it
- uses no testing functions

The show cases are grouped by subject, and each group is its own build step:

```sh
zig build examples-layer1
zig build examples-bridge
```


---

## How to start

---


You are about to build a background process in Zig.

If this kind of process is new to you, do not start with the whole toolkit.

Go step by step.

1. **One thread, one struct.**
    - Put an `Inner` in your struct.
    - Create and destroy it through its helper.
    - Chain a few in a `Queue`.
    - Take them out again.
    - `examples/layer1/021-define_type.zig` is the first one.
2. **Add a thread.**
    - Send your outers over `std.Io.Queue(AnyOuter)`.
    - Before the push, `moveFromSlot` moves the outer from its slot into an
      `AnyOuter`.
    - After the pop, `moveToSlot` moves it back into a slot.
    - `fromAny` tells the receiver whether it is its own type.
    - An `AnyOuter` is moved, never copied. Two copies are two owners.
    - `examples/bridge/104-server_handler_and_workers.zig` shows the whole
      crossing, both ways.
3. **Add a pool.**
    - Do it when repeated allocation becomes a problem.
    - Write the three hooks.
    - Decide what to clear and what to keep.
4. **Replace the channel with a mailbox.**
    - Do it when the channel stops being enough.

### What the mailbox adds to a channel

- **No allocation on transfer.**
    - The channel copies into a buffer it grows.
- **`close` gives back what was queued.**
    - The channel's `close` leaves it in the queue.
- And more:
    - timeouts
    - `wakeUpAll`
    - sending to the front
    - a per-type limit
    - batches
    - every outer type in one queue

If your channel already does what you need, keep it.


---

## When to stop

---



At any step you can stop and say:

**enough, I have what my system needs.**

That is completely fine.

Every step stands on its own.

You do not need to solve every problem on the first day.


---

## The Matryoshka family

---


This doll is not the only one.

- **Odin — [matryoshka-otk](https://github.com/g41797/matryoshka-otk)**
    - The first.
    - It started as a port of a Zig project, [mailbox](https://github.com/g41797/mailbox), to Odin.
    - It did not stay a port for long.
- **C3 — [matryoshka-3tk](https://github.com/g41797/matryoshka-3tk)**
    - A redesign of the Zig version.
- **Zig — this one**
    - Rewritten against the C3 design, on `std.Io`.

Different languages.

The same ideas:

- The link lives inside your struct.
- The type is erased on the way in, and checked on the way back.
- Infrastructure stays out of your application logic.
- Small enough to read.
- Made for boring systems.

Odin, Zig, C3.

Three languages, each trying to be a **better C**.

All three are mature enough to run a real background process today.

The dolls are on the shelf.

**The next move is yours.**
