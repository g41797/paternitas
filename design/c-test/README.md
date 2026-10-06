# C callback context test

The unit-test scenario from design 014, "C code: findings". A record, not
advice: the README and the comments say nothing about C.

- `c_context_test.zig`: Zig only, no libc. A `callconv(.c)` callback takes
  a `?*anyopaque` context, called through a function pointer.
  - A `*Anchor` round trip: `parentFromAnchor` gives the Parent; another
    type, or no `setTypeId`, gives null.
  - A `*Any` round trip for a struct with no TypedNode: `fromAny` gives it
    back; another type gives null.
- It lives under `design/`, not `tests/`. It is not in `build.zig` and not
  one of the six gates. Owner's ruling, 2026-10-06.

Run it from the repo root:

```text
bash kitchen/test_c_context.sh
```

Four modes, LLVM and Zig's own backend. The output goes to
`zig-out/c_context.log`.
