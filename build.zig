const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const is_wasm_freestanding = target.result.cpu.arch.isWasm() and target.result.os.tag == .freestanding;

    // --- Rust C ABI & Pre-built via temporal-rs subpackage --- //
    const temporal = b.dependency("temporal", .{
        .target = target,
        .optimize = optimize,
    });

    // --- Zig Module: temporalz --- //
    const mod = b.addModule("temporalz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("temporal_rs", temporal.module("temporal_rs"));

    // --- Zig Executable: temporalz --- //
    const exe = b.addExecutable(.{
        .name = "temporalz",
        .root_module = b.createModule(.{
            .root_source_file = if (is_wasm_freestanding)
                b.path("example/src/wasm.zig")
            else
                b.path("example/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "temporalz", .module = mod },
            },
        }),
    });
    exe.root_module.link_libc = !is_wasm_freestanding;
    exe.rdynamic = is_wasm_freestanding;
    b.installArtifact(exe);

    // --- Steps: Run --- //
    {
        const run_step = b.step("run", "Run the app");
        switch (target.result.os.tag) {
            .freestanding => {
                const run_cmd = b.addSystemCommand(&.{ "node", "example/src/main.mjs" });
                run_cmd.step.dependOn(b.getInstallStep());
                run_step.dependOn(&run_cmd.step);
            },
            .wasi => {
                const run_cmd = b.addSystemCommand(&.{"wasmtime"});
                run_cmd.addFileArg(exe.getEmittedBin());
                run_cmd.step.dependOn(b.getInstallStep());
                run_step.dependOn(&run_cmd.step);
            },
            else => {
                const run_cmd = b.addRunArtifact(exe);
                run_cmd.step.dependOn(b.getInstallStep());
                if (b.args) |args| run_cmd.addArgs(args);
                run_step.dependOn(&run_cmd.step);
            },
        }
    }

    // --- Steps: Docs --- //
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

    // --- Steps: Test --- //
    {
        const test_step = b.step("test", "Run tests");
        const mod_tests = b.addTest(.{
            .root_module = mod,
            .test_runner = .{
                .path = b.path("test/runner.zig"),
                .mode = .simple,
            },
        });
        mod_tests.root_module.link_libc = !is_wasm_freestanding;
        test_step.dependOn(&b.addRunArtifact(mod_tests).step);
        if (!is_wasm_freestanding) {
            const exe_tests = b.addTest(.{ .root_module = exe.root_module });
            test_step.dependOn(&b.addRunArtifact(exe_tests).step);
        }
    }

    // --- Steps: test-262 --- //
    {
        const test262_step = b.step("test262", "Run test-262 tests");
        const run_cmd = b.addSystemCommand(&.{ "node", "test/test262/runner.mjs" });
        if (b.args) |args| run_cmd.addArgs(args);
        run_cmd.step.dependOn(b.getInstallStep());
        test262_step.dependOn(&run_cmd.step);
    }
}
