const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const is_wasm_freestanding = target.result.cpu.arch.isWasm() and target.result.os.tag == .freestanding;

    // --- Zig Module: temporalz --- //
    const mod = b.addModule("temporalz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addIncludePath(b.path("src/stubs/c_headers"));

    // --- Rust C ABI: temporal_capi --- //
    const temporal_rs_git = b.dependency("temporal_rs", .{
        .target = target,
        .optimize = optimize,
    });
    mod.addIncludePath(temporal_rs_git.path("temporal_capi/bindings/c"));

    // --- Rust C ABI: Library --- //
    {
        // Determine target triple string for pre-built library lookup
        const arch_str = @tagName(target.result.cpu.arch);
        const os_str = @tagName(target.result.os.tag);
        const abi = target.result.abi;
        const target_triple = if (abi == .none)
            b.fmt("{s}-{s}", .{ arch_str, os_str })
        else
            b.fmt("{s}-{s}-{s}", .{ arch_str, os_str, @tagName(abi) });
        const lib_name = if (target.result.os.tag == .windows and abi == .msvc)
            "temporal_capi.lib"
        else
            "libtemporal_capi.a";

        // Check if pre-built library exists in lib/<target>/
        const prebuilt_lib_path = b.fmt("lib/{s}/{s}", .{ target_triple, lib_name });
        const prebuilt_lib_file = b.path(prebuilt_lib_path);

        // Try to use pre-built library if it exists by checking the path object
        const use_prebuilt = blk: {
            const lib_full_path = prebuilt_lib_file.getPath(b);
            const lib_check_file = std.Io.Dir.cwd().openFile(b.graph.io, lib_full_path, .{}) catch break :blk false;
            lib_check_file.close(b.graph.io);
            break :blk true;
        };

        if (use_prebuilt) {
            // Use pre-built library (no Rust compiler needed)
            mod.addObjectFile(prebuilt_lib_file);
        } else {
            // Build from source using the local temporal-rs package
            const temporal_rs_local = b.dependency("temporal_rs_local", .{
                .target = target,
                .optimize = optimize,
            });
            mod.linkLibrary(temporal_rs_local.artifact("temporal_rs_lib"));
        }

        // --- Rust Misc Deps --- //
        if (target.result.os.tag == .windows) mod.linkSystemLibrary("userenv", .{});
        const unwind_stubs = b.addLibrary(.{ .linkage = .static, .name = "unwind_stubs", .root_module = b.createModule(.{
            .root_source_file = b.path("src/stubs/unwind.zig"),
            .target = target,
            .optimize = optimize,
        }) });
        mod.linkLibrary(unwind_stubs);
    }

    // --- Zig Executable: temporalz --- //
    const exe_root = if (is_wasm_freestanding)
        b.path("example/src/wasm.zig")
    else
        b.path("example/src/main.zig");
    const exe = b.addExecutable(.{
        .name = "temporalz",
        .root_module = b.createModule(.{
            .root_source_file = exe_root,
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
