const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("paternitas", .{
        .root_source_file = b.path("src/paternitas.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{ .root_module = mod });
    const run = b.addRunArtifact(tests);
    b.step("test", "Run unit tests").dependOn(&run.step);

    // What Paternitas refuses. A compile error cannot be reached from a
    // test, and a test cannot assert a panic, so these are programs.
    const negative = b.step("negative", "Run what Paternitas refuses");

    const refused_at_compile_time = [_]struct { file: []const u8, says: []const u8 }{
        .{ .file = "negative/compile/not_struct.zig", .says = "not a struct, so it cannot be a Paternitas Parent" },
        .{ .file = "negative/compile/bare_node.zig", .says = "no Link, so it cannot be a Paternitas Parent" },
        .{ .file = "negative/compile/two_links.zig", .says = "more than one Link, and exactly one is allowed" },
        .{ .file = "negative/compile/wrong_node.zig", .says = "expected type '*SinglyLinkedList.Node', found '*DoublyLinkedList.Node'" },
    };

    for (refused_at_compile_time) |case| {
        const cmod = b.createModule(.{
            .root_source_file = b.path(case.file),
            .target = target,
            .optimize = optimize,
        });
        cmod.addImport("paternitas", mod);
        const obj = b.addObject(.{ .name = std.fs.path.stem(case.file), .root_module = cmod });
        obj.expect_errors = .{ .contains = case.says };
        negative.dependOn(&obj.step);
    }

    // Each must abort in every build mode, and say why.
    const refused_at_run_time = [_]struct { file: []const u8, says: []const u8 }{
        .{ .file = "negative/panic/must_from_anchor.zig", .says = "mustFromAnchor: asked for must_from_anchor.Msg, found must_from_anchor.Job" },
        .{ .file = "negative/panic/must_parent_from_node.zig", .says = "mustParentFromNode: asked for must_parent_from_node.Msg, found <unstamped>" },
        .{ .file = "negative/panic/wrong_node_kind.zig", .says = "TypeInfo.node: wrong_node_kind.Msg has another Node kind" },
    };

    for (refused_at_run_time) |case| {
        const pmod = b.createModule(.{
            .root_source_file = b.path(case.file),
            .target = target,
            .optimize = optimize,
        });
        pmod.addImport("paternitas", mod);
        const exe = b.addExecutable(.{ .name = std.fs.path.stem(case.file), .root_module = pmod });
        const r = b.addRunArtifact(exe);
        r.addCheck(.{ .expect_term = .{ .signal = .ABRT } });
        r.addCheck(.{ .expect_stderr_match = case.says });
        negative.dependOn(&r.step);
    }
}
