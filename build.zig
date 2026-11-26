const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Rust C ABI & Pre-built via temporal-rs subpackage --- //
    const build_rust = b.option(bool, "build-rust", "Build Rust library from source (default: true until prebuilts for temporal main are published)") orelse true;
    const libtemporal = b.dependency("libtemporal", .{
        .target = target,
        .optimize = optimize,
        .@"build-rust" = build_rust,
    });

    // --- Module: Temporal --- //
    const mod = b.addModule("Temporal", .{
        .root_source_file = b.path("src/Temporal.zig"),
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
            b.fmt("-Doptimize={t}", .{optimize}),
            b.fmt("-Dbuild-rust={}", .{build_rust}),
        });
        run_cmd.setCwd(b.path("test"));
        run_cmd.addPassthruArgs();
        run_step.dependOn(&run_cmd.step);
    }

    // --- Step: docs --- //
    {
        const docs_step = b.step("docs", "Build the Temporal docs");
        const docs_obj = b.addObject(.{ .name = "Temporal", .root_module = mod });
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
        mod_tests.root_module.link_libc = switch (target.result.os.tag) {
            .freestanding, .wasi => false,
            else => true,
        };
        test_step.dependOn(&b.addRunArtifact(mod_tests).step);
    }
}
