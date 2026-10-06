# Install

Copy, paste, build.

The lines below are shell and `build.zig` lines for your project. They are written text, not working code from this repo.

---

## Fetch the package

It writes the dependency into your `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/g41797/paternitas
```

---

## Add it to `build.zig`

Put these lines after your `exe`:

```zig
const paternitas = b.dependency("paternitas", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("paternitas", paternitas.module("paternitas"));
```

---

## Import it

```zig
const paternitas = @import("paternitas");
```

---

## Requirements

- Zig 0.16.0.
- `std` only. No other dependency.
