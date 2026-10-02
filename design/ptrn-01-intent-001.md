# paternitas — PTRN 01 intent (001)

The intent of PTRN 01, the code, and the owner's answers of 2026-10-02.
Opus 5.5.

- Rules: [rules-005.md](rules-005.md).
- Plan: [implementation-plan-009.md](implementation-plan-009.md).
- Design: [paternitas-design-007.md](paternitas-design-007.md).

---

## What changes, and where

The code.

- `src/paternitas.zig`, `src/container.zig`: the outside code, ported.
  - Rules Part 2. A13.
  - A1: a private `var tag: u8`. `TypeInfo._tag: *const u8`, first field.
  - A3: `Link(N)` is a compile error for any other `N`.
  - A11: `_type_id`, read through `Anchor.typeId()`.
  - T6: `is` takes `*const Node`.
  - A15: the address step is `container._nextFieldAt`.
  - Comments: banned words fixed only. The full pass is PTRN 02.

Tests.

- `tests/paternitas_tests.zig`: the 9 outside tests, the A5, A11 and A15
  tests, and a check of the helper `Chain`.
- `tests/same_name/one/msg.zig`, `tests/same_name/two/msg.zig`: the A1 test.
  - Both type names are `msg.Msg`. A scratch probe confirmed it.

Negatives.

- `negative/compile/`: 5 programs. `negative/panic/`: 4 programs.
- `build.zig`: the `negative` step.
- `kitchen/build_negative_all.sh`: gate 6, all four modes, the host.
- Gate 5 checks `negative` too.

The example.

- `print_version` is replaced by `stamp_and_recover`.

---

## The owner's answers

1. A15. The address step is `pub`, with a symbolic name:
   `@"---nextFieldAt---"`.
   - Changed after the gates: `_nextFieldAt`. The quoted name broke its
     autodoc link.
   - The name says: not for use.
   - The test in `tests/` calls it.
2. The version stays `0.0.1`. Intake D9 said `0.0.0`. The repo has `0.0.1`.
3. The placeholder example is replaced by a small real one. PTRN 02 keeps or
   rewrites it. `VERSION` leaves the API.
4. SPDX headers.
   - `src/`: yes.
   - `tests/`, `negative/`, `examples/`: no.
5. `negative` is not added to `build.zig.zon` paths. The local build runs it
   without.

## The owner's rulings after the gates

1. The address step is renamed `_nextFieldAt`.
2. Rules 005: "`STATUS.md` holds that" becomes "has that".
3. `const testing = std.testing;` moves before `std`. Rules 005 says so.
