const std = @import("std");

// The build of paternitas. It knows about src/, tests/, examples/ and
// negative/.
pub fn build(b: *std.Build) void {
    const target: std.Build.ResolvedTarget = b.standardTargetOptions(.{});
    const optimize: std.builtin.OptimizeMode = b.standardOptimizeOption(.{});

    const use_lld = target.result.os.tag != .macos and
        target.result.os.tag != .freebsd and
        target.result.os.tag != .openbsd and
        target.result.os.tag != .netbsd;

    const mod: *std.Build.Module = b.addModule("paternitas", .{
        .root_source_file = b.path("src/paternitas.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = false,
    });

    const lib: *std.Build.Step.Compile = b.addLibrary(.{
        .name = "paternitas",
        .linkage = .static,
        .root_module = mod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    b.installArtifact(lib);

    const emod: *std.Build.Module = b.addModule("examples", .{
        .root_source_file = b.path("examples/examples.zig"),
        .target = target,
        .optimize = optimize,
    });

    emod.addImport("paternitas", mod);

    // Two modules, each with a root file msg.zig and a type Msg. Both type
    // names are msg.Msg. The tests check they get two TypeIds.
    const msg_one: *std.Build.Module = b.createModule(.{
        .root_source_file = b.path("tests/same_name/one/msg.zig"),
        .target = target,
        .optimize = optimize,
    });

    msg_one.addImport("paternitas", mod);

    const msg_two: *std.Build.Module = b.createModule(.{
        .root_source_file = b.path("tests/same_name/two/msg.zig"),
        .target = target,
        .optimize = optimize,
    });

    msg_two.addImport("paternitas", mod);

    // The tests of src/, and the wrappers that run the examples. The test
    // step runs both; the examples step runs the wrappers alone.
    const test_roots = [_][]const u8{ "tests/paternitas_tests.zig", "tests/examples_tests.zig" };

    const test_step: *std.Build.Step = b.step("test", "Run unit tests");
    const examples_step: *std.Build.Step = b.step("examples", "Run the examples");

    for (test_roots) |root| {
        const tmod: *std.Build.Module = b.createModule(.{
            .root_source_file = b.path(root),
            .target = target,
            .optimize = optimize,
        });

        tmod.addImport("paternitas", mod);
        tmod.addImport("examples", emod);
        tmod.addImport("msg_one", msg_one);
        tmod.addImport("msg_two", msg_two);

        const tests: *std.Build.Step.Compile = b.addTest(.{
            .root_module = tmod,
            .use_llvm = true,
            .use_lld = use_lld,
        });

        const run_tests: *std.Build.Step.Run = b.addRunArtifact(tests);
        test_step.dependOn(&run_tests.step);

        if (std.mem.eql(u8, root, "tests/examples_tests.zig")) {
            examples_step.dependOn(&run_tests.step);
        }
    }

    // Documentation generation step.
    const docs_step: *std.Build.Step = b.step("docs", "Generate API documentation");

    const apidocs_lib: *std.Build.Step.Compile = b.addObject(.{
        .name = "paternitas",
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

    addNegative(b, target, optimize, mod, use_lld);
}

// What paternitas refuses. A test cannot reach a compile error or check a
// panic, so these are programs. The panic programs run on the host only.
fn addNegative(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    mod: *std.Build.Module,
    use_lld: bool,
) void {
    const negative_step: *std.Build.Step = b.step("negative", "Run what paternitas refuses");

    // Each of these must fail to compile, with that message.
    const refused_at_compile_time = [_]struct { file: []const u8, says: []const u8 }{
        .{ .file = "negative/compile/not_struct.zig", .says = "not a struct, so it cannot be a Paternitas Parent" },
        .{ .file = "negative/compile/bare_node.zig", .says = "no TypedNode, so it cannot be a Paternitas Parent" },
        .{ .file = "negative/compile/two_typed_nodes.zig", .says = "more than one TypedNode, and exactly one is allowed" },
        .{ .file = "negative/compile/wrong_node.zig", .says = "found '*DoublyLinkedList.Node'" },
        .{ .file = "negative/compile/typed_node_other_node.zig", .says = "TypedNode(typed_node_other_node.OtherNode): not a std Node, so it cannot be a Paternitas TypedNode" },
    };

    for (refused_at_compile_time) |case| {
        const cmod: *std.Build.Module = b.createModule(.{
            .root_source_file = b.path(case.file),
            .target = target,
            .optimize = optimize,
        });

        cmod.addImport("paternitas", mod);

        const obj: *std.Build.Step.Compile = b.addObject(.{
            .name = std.fs.path.stem(case.file),
            .root_module = cmod,
            .use_llvm = true,
            .use_lld = use_lld,
        });

        obj.expect_errors = .{ .contains = case.says };
        negative_step.dependOn(&obj.step);
    }

    // Each of these must abort, and say why on stderr. A case that is not
    // `every_mode` is a contract check: it aborts where runtime safety is
    // on, and exits 0 elsewhere.
    const refused_at_run_time = [_]struct { file: []const u8, says: []const u8, every_mode: bool = true }{
        .{ .file = "negative/panic/must_parent_from_anchor.zig", .says = "mustParentFromAnchor: asked for must_parent_from_anchor.Msg, found must_parent_from_anchor.Job" },
        .{ .file = "negative/panic/must_parent_from_node.zig", .says = "mustParentFromNode: asked for must_parent_from_node.Msg, found <no type>" },
        .{ .file = "negative/panic/wrong_node_kind.zig", .says = "TypeInfo.node: wrong_node_kind.Msg has another Node kind" },
        .{ .file = "negative/panic/from_any_no_type.zig", .says = "fromAny: setTypeId was never called on the Parent", .every_mode = false },
        .{ .file = "negative/panic/from_any_to_any_no_type.zig", .says = "fromAny: setTypeId was never called on the Parent", .every_mode = false },
    };

    const safety_is_on: bool = optimize == .Debug or optimize == .ReleaseSafe;

    for (refused_at_run_time) |case| {
        const pmod: *std.Build.Module = b.createModule(.{
            .root_source_file = b.path(case.file),
            .target = target,
            .optimize = optimize,
        });

        pmod.addImport("paternitas", mod);

        const exe: *std.Build.Step.Compile = b.addExecutable(.{
            .name = std.fs.path.stem(case.file),
            .root_module = pmod,
            .use_llvm = true,
            .use_lld = use_lld,
        });

        const run: *std.Build.Step.Run = b.addRunArtifact(exe);

        if (case.every_mode or safety_is_on) {
            run.addCheck(.{ .expect_term = .{ .signal = .ABRT } });
            run.addCheck(.{ .expect_stderr_match = case.says });
        } else {
            run.addCheck(.{ .expect_term = .{ .exited = 0 } });
        }

        negative_step.dependOn(&run.step);
    }
}
