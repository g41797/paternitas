const std = @import("std");

// The build of paternitas. It knows about src/, tests/ and examples/.
//
// What the next/ztk build.zig has and this one does not: the negative step.
// It arrives with the first stage where paternitas refuses something.
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
}
