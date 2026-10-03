const std = @import("std");

// The build of the rewritten toolkit. It knows about src/, tests/ and, since
// the EXAMPLES stage, examples/.
//
// What the old tree's build.zig has and this one does not: the stories module
// and the core_surface step. Stories are obsolete for now. The examples module
// entered after the layers were tested, so no layer test depends on it.
pub fn build(b: *std.Build) void {
    const target: std.Build.ResolvedTarget = b.standardTargetOptions(.{});
    const optimize: std.builtin.OptimizeMode = b.standardOptimizeOption(.{});

    const use_lld = target.result.os.tag != .macos and
        target.result.os.tag != .freebsd and
        target.result.os.tag != .openbsd and
        target.result.os.tag != .netbsd;

    const mod: *std.Build.Module = b.addModule("matryoshka", .{
        .root_source_file = b.path("src/matryoshka.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = false,
    });

    const paternitas = b.dependency("paternitas", .{
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("paternitas", paternitas.module("paternitas"));

    const lib: *std.Build.Step.Compile = b.addLibrary(.{
        .name = "matryoshka",
        .linkage = .static,
        .root_module = mod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    b.installArtifact(lib);

    const tmod: *std.Build.Module = b.createModule(.{
        .root_source_file = b.path("tests/matryoshka_tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const emod: *std.Build.Module = b.addModule("examples", .{
        .root_source_file = b.path("examples/examples.zig"),
        .target = target,
        .optimize = optimize,
    });

    emod.addImport("matryoshka", mod);

    tmod.addImport("matryoshka", mod);
    tmod.addImport("examples", emod);

    const unit_tests: *std.Build.Step.Compile = b.addTest(.{
        .root_module = tmod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    const run_unit_tests: *std.Build.Step.Run = b.addRunArtifact(unit_tests);

    const test_step: *std.Build.Step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // One step per group of examples, so a group can be built and run alone.
    const example_groups = [_][]const u8{ "layer1", "layer2", "layer3", "layer4a", "layer4b", "layer4c", "bridge" };

    for (example_groups) |group| {
        const gmod: *std.Build.Module = b.createModule(.{
            .root_source_file = b.path(b.fmt("tests/examples_{s}.zig", .{group})),
            .target = target,
            .optimize = optimize,
        });

        gmod.addImport("matryoshka", mod);
        gmod.addImport("examples", emod);

        const gtests: *std.Build.Step.Compile = b.addTest(.{
            .root_module = gmod,
            .use_llvm = true,
            .use_lld = use_lld,
        });

        const run_gtests: *std.Build.Step.Run = b.addRunArtifact(gtests);
        const gstep: *std.Build.Step = b.step(b.fmt("examples-{s}", .{group}), "Run one group of examples");
        gstep.dependOn(&run_gtests.step);
    }

    // Documentation generation step.
    const docs_step: *std.Build.Step = b.step("docs", "Generate API documentation");

    const apidocs_lib: *std.Build.Step.Compile = b.addObject(.{
        .name = "matryoshka",
        .root_module = mod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    const install_apidocs: *std.Build.Step.InstallDir = b.addInstallDirectory(.{
        .source_dir = apidocs_lib.getEmittedDocs(),
        .install_dir = .{ .custom = "../kitchen/docs" },
        .install_subdir = "apidocs",
    });

    docs_step.dependOn(&install_apidocs.step);

    // What the toolkit refuses. A Zig test cannot assert that a panic
    // happened, and a compile error cannot be reached from inside a test at
    // all, so these are programs rather than tests.
    const negative_step: *std.Build.Step = b.step("negative", "Run what the toolkit refuses");

    // Each of these must fail to compile, with that message.
    const refused_at_compile_time = [_]struct { file: []const u8, says: []const u8 }{
        .{ .file = "negative/compile/306_no_inner.zig", .says = "no TypedNode, so it cannot be a Paternitas Parent" },
        .{ .file = "negative/compile/307_two_inners.zig", .says = "more than one TypedNode, and exactly one is allowed" },
        .{ .file = "negative/compile/314_bare_node.zig", .says = "no TypedNode, so it cannot be a Paternitas Parent" },
        .{ .file = "negative/compile/308_no_init.zig", .says = "a parent the helper creates declares `pub fn init(self: *308_no_init.NoInit, alloc: std.mem.Allocator, io: std.Io) !void` — an empty body is fine" },
        .{ .file = "negative/compile/309_no_finish.zig", .says = "a parent the helper releases declares `pub fn finish(self: *309_no_finish.NoFinish, alloc: std.mem.Allocator, io: std.Io) void` — an empty body is fine" },
    };

    for (refused_at_compile_time) |case| {
        const cmod: *std.Build.Module = b.createModule(.{
            .root_source_file = b.path(case.file),
            .target = target,
            .optimize = optimize,
        });

        cmod.addImport("matryoshka", mod);

        const obj: *std.Build.Step.Compile = b.addObject(.{
            .name = std.fs.path.stem(case.file),
            .root_module = cmod,
        });

        obj.expect_errors = .{ .contains = case.says };
        negative_step.dependOn(&obj.step);
    }

    // Each of these must die when it runs. `safe_only` marks a case that
    // rests on `check`, which is compiled out where runtime safety is off —
    // there the program is correct to survive, so it is not built at all.
    const refused_at_run_time = [_]struct { file: []const u8, safe_only: bool = true }{
        .{ .file = "negative/panic/300_no_type_append.zig" },
        .{ .file = "negative/panic/301_wrong_type_must.zig", .safe_only = false },
        .{ .file = "negative/panic/302_create_into_full_slot.zig" },
        .{ .file = "negative/panic/303_overwrite_slot.zig" },
        .{ .file = "negative/panic/304_append_linked.zig" },
        .{ .file = "negative/panic/305_append_twice.zig" },
        .{ .file = "negative/panic/310_destroy_open_mailbox.zig", .safe_only = false },
        .{ .file = "negative/panic/312_destroy_while_receiving.zig", .safe_only = false },
        .{ .file = "negative/panic/286_duplicate_identity.zig" },
        .{ .file = "negative/panic/286_empty_identities.zig" },
        .{ .file = "negative/panic/311_destroy_open_pool.zig", .safe_only = false },
        .{ .file = "negative/panic/313_destroy_during_hook.zig", .safe_only = false },
        .{ .file = "negative/panic/321_take_no_type.zig" },
        .{ .file = "negative/panic/322_take_linked.zig" },
    };

    const safety_is_on = optimize == .Debug or optimize == .ReleaseSafe;

    for (refused_at_run_time) |case| {
        if (case.safe_only and !safety_is_on) continue;

        const pmod: *std.Build.Module = b.createModule(.{
            .root_source_file = b.path(case.file),
            .target = target,
            .optimize = optimize,
        });

        pmod.addImport("matryoshka", mod);

        const prog: *std.Build.Step.Compile = b.addExecutable(.{
            .name = std.fs.path.stem(case.file),
            .root_module = pmod,
            .use_llvm = true,
            .use_lld = use_lld,
        });

        const run: *std.Build.Step.Run = b.addRunArtifact(prog);

        // A panic aborts. An orderly exit means the contract was not refused.
        run.addCheck(.{ .expect_term = .{ .signal = .ABRT } });
        negative_step.dependOn(&run.step);
    }
}
