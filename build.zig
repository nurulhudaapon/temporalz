const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Rust C ABI & Pre-built via temporal-rs subpackage --- //
    const build_rust = b.option(bool, "build-rust", "Build Rust library from source") orelse false;
    const libtemporal = b.dependency("libtemporal", .{
        .target = target,
        .optimize = optimize,
        .@"build-rust" = build_rust,
    });

    // --- Module: temporalz --- //
    const mod = b.addModule("temporalz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("libtemporal", libtemporal.module("libtemporal"));

    // --- Step: run --- //
    {
        const run_step = b.step("run", "Run the test project");
        const run_cmd = b.addSystemCommand(&.{
            b.graph.zig_exe,
            "build",
            "run",
            b.fmt("-Dtarget={s}", .{try target.result.zigTriple(b.allocator)}),
        });
        run_cmd.setCwd(b.path("test"));
        run_cmd.addPassthruArgs();
        run_step.dependOn(&run_cmd.step);
    }

    // --- Step: docs --- //
    {
        const docs_step = b.step("docs", "Build the temporalz docs");
        const docs_obj = b.addObject(.{ .name = "temporalz", .root_module = mod });
        const docs = docs_obj.getEmittedDocs();

        docs_step.dependOn(&b.addInstallDirectory(.{
            .source_dir = docs,
            .install_dir = .prefix,
            .install_subdir = "docs",
        }).step);
    }

    // --- Step: test --- //
    {
        const test_step = b.step("test", "Run tests");
        const mod_tests = b.addTest(.{
            .root_module = mod,
            .test_runner = .{
                .path = b.path("test/runner.zig"),
                .mode = .simple,
            },
        });
        mod_tests.root_module.link_libc = target.result.os.tag == .freestanding;
        test_step.dependOn(&b.addRunArtifact(mod_tests).step);
    }
}
