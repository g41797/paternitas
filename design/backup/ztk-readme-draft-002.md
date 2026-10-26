![](kitchen/docs/assets/matryoshka-ztk-logo.png)

# Toolkit for Building Background Processes

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/matryoshka-ztk/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/linux.yml)
[![Windows](https://github.com/g41797/matryoshka-ztk/actions/workflows/windows.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/windows.yml)
[![macOS](https://github.com/g41797/matryoshka-ztk/actions/workflows/mac.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/mac.yml)
[![Deploy Documentation](https://github.com/g41797/matryoshka-ztk/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/matryoshka-ztk/actions/workflows/docs.yml)

Software has two worlds.

- The first moves data.
- The second processes data.

Matryoshka-Ztk is a _toolkit_ for the second world.

The whole toolkit is about 800 lines of Zig. A script counts them.

## What you get

- **A mailbox.** Your threads send work to each other through it.
  - Nothing is allocated when a message is sent.
  - One mailbox carries any mix of your structs.
  - Many senders, many receivers, with timeouts.
  - `close` gives back whatever is still queued.
- **A pool.** Used structs come back and go out again.
  - Your hooks decide what reuse means.
- **A queue.** A first in, first out chain of your structs.
  - It allocates nothing and locks nothing.
- **A helper.** One line per struct type.
  - It creates your struct, checks its type and releases it.

Take only what you need. The mailbox works without the pool.

## A pipeline

Three threads, two mailboxes.

```text
 producer ──Event──► transformer_mbx ──► transformer
                                             │ Event → Sensor
                                             ▼
 consumer ◄──Sensor── consumer_mbx ◄── transformer

 ShutdownCommand goes down the same way and stops each thread.
```

The transformer, the middle thread:

```zig
fn transformerFn(ctx: *TransformerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer parents.destroySlot(&slot, ctx.alloc, ctx.io);
        ctx.in_mbx.receive(&slot, null) catch return;
        const anchor: *Anchor = slot.?;

        if (parents.Event.EventHelper.fromAnchor(anchor)) |ev| {
            const value: f64 = @floatFromInt(ev.code);
            parents.destroySlot(&slot, ctx.alloc, ctx.io);
            parents.Sensor.SensorHelper.create(ctx.alloc, ctx.io, &slot) catch continue;
            parents.Sensor.SensorHelper.mustFromSlot(&slot).value = value;
            ctx.out_mbx.send(&slot) catch {};
            std.log.info("transformer: Event→Sensor value={d}", .{value});
        } else if (parents.ShutdownCommand.ShutdownCommandHelper.fromAnchor(anchor)) |_| {
            ctx.out_mbx.send(&slot) catch {};
            std.log.info("transformer: forwarded ShutdownCommand, done", .{});
            return;
        }
    }
}
```

What to look at:

- A `Slot` is where a struct sits while it is yours. Empty means it is not.
- `receive` fills the Slot. `send` empties it.
- An Anchor is the part of your struct the mailbox sees.
- `fromAnchor` tells you which struct arrived. One mailbox, three types.
- `defer` releases whatever is left in the Slot. Nothing leaks.

The whole file:
[020-pipeline_masters.zig](https://github.com/g41797/matryoshka-ztk/blob/main/examples/layer4/020-pipeline_masters.zig).

## Install

To come.

## Built on Paternitas

Under the toolkit sits Paternitas, a small library of its own.

- It puts the Anchor into your struct, and finds your struct again from it.
- These pages and the site cover all you need. You need not read it.
- If you are curious: [Paternitas](https://g41797.github.io/paternitas/).

## Learn more

The site has the tools, the patterns and the examples:
[Matryoshka-Ztk](https://g41797.github.io/matryoshka-ztk/).
