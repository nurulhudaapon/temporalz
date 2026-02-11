const std = @import("std");
const build_crab = @import("build_crab");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Zig Module: temporalz --- //
    const mod = b.addModule("temporalz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // --- Rust C ABI: temporal_capi --- //
    const temporal_rs = b.dependency("temporal_rs", .{
        .target = target,
        .optimize = optimize,
    });
    mod.addIncludePath(temporal_rs.path("temporal_capi/bindings/c"));

    // --- Rust Crate: temporal_rs --- //
    {
        // Determine target triple string for pre-built library lookup
        const arch_str = @tagName(target.result.cpu.arch);
        const os_str = @tagName(target.result.os.tag);
        const abi = target.result.abi;
        const abi_str = @tagName(abi);
        const target_triple = if (abi == .none)
            b.fmt("{s}-{s}", .{ arch_str, os_str })
        else
            b.fmt("{s}-{s}-{s}", .{ arch_str, os_str, abi_str });
        const lib_name = if (target.result.os.tag == .windows and abi == .msvc)
            "temporal_capi.lib"
        else
            "libtemporal_capi.a";

        // Check if pre-built library exists in lib/<target>/
        const prebuilt_lib_path = b.fmt("lib/{s}/{s}", .{ target_triple, lib_name });
        const prebuilt_lib_file = b.path(prebuilt_lib_path);

        // Try to use pre-built library if it exists by checking the path object
        const use_prebuilt = blk: {
            // Use the LazyPath to check if the library exists
            const lib_full_path = prebuilt_lib_file.getPath(b);
            const lib_check_file = std.Io.Dir.cwd().openFile(b.graph.io, lib_full_path, .{}) catch break :blk false;
            lib_check_file.close(b.graph.io);
            break :blk true;
        };

        if (use_prebuilt) {
            // Use pre-built library (no Rust compiler needed)
            // std.debug.print("Using pre-built temporal_capi library: {s}\n", .{prebuilt_lib_path});
            mod.addObjectFile(prebuilt_lib_file);
        } else {
            // Build from source using Cargo
            const build_dir = build_crab.addCargoBuild(
                b,
                .{
                    .manifest_path = b.path("Cargo.toml"),
                    .cargo_args = if (optimize == .Debug) &.{} else &.{"--release"},
                },
                .{
                    .target = target,
                    .optimize = .ReleaseSafe,
                },
            );

            // Install .a/.lib to lib/<target>/libtemporal_capi.a/temporal_capi.lib
            const install_lib = b.addInstallDirectory(.{
                .source_dir = build_dir,
                .install_dir = .{ .custom = "../lib" },
                .install_subdir = target_triple,
            });
            b.getInstallStep().dependOn(&install_lib.step);
            mod.addObjectFile(build_dir.path(b, lib_name));
        }

        // --- Rust Misc Deps --- //
        if (target.result.os.tag == .windows) mod.linkSystemLibrary("userenv", .{});
        const unwind_stubs = b.addLibrary(.{
            .linkage = .static,
            .name = "unwind_stubs",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/unwind_stubs.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        mod.linkLibrary(unwind_stubs);
    }

    // --- Zig Executable: temporalz --- //
    const exe = b.addExecutable(.{
        .name = "temporalz",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example/src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "temporalz", .module = mod },
            },
        }),
    });
    b.installArtifact(exe);

    // --- Steps: Run --- //
    {
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
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
        mod_tests.root_module.link_libc = true;
        test_step.dependOn(&b.addRunArtifact(mod_tests).step);
        const exe_tests = b.addTest(.{ .root_module = exe.root_module });
        test_step.dependOn(&b.addRunArtifact(exe_tests).step);
    }

    // --- Steps: test-262 --- //
    {
        const test262_step = b.step("test262", "Run test-262 tests");
        const test262_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("test/test262/root.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "temporalz", .module = mod },
                },
            }),
            .test_runner = .{
                .path = b.path("test/runner.zig"),
                .mode = .simple,
            },
        });
        test262_tests.root_module.link_libc = true;
        test262_step.dependOn(&b.addRunArtifact(test262_tests).step);
    }

    // --- Steps: Build all platforms --- //
    {
        const build_lib_step = b.step("lib", "Build libraries for all common platforms");

        inline for (platforms) |p| {
            const query = try std.Build.parseTargetQuery(.{ .arch_os_abi = p });
            const platform_target = b.resolveTargetQuery(query);

            const build_dir = build_crab.addCargoBuild(
                b,
                .{
                    .manifest_path = b.path("Cargo.toml"),
                    .cargo_args = &.{"--release"},
                },
                .{
                    .target = platform_target,
                    .optimize = .ReleaseSafe,
                },
            );

            const install_lib = b.addInstallDirectory(.{
                .source_dir = build_dir,
                .install_dir = .{ .custom = "../lib" },
                .install_subdir = p,
            });
            build_lib_step.dependOn(&install_lib.step);
        }
    }
}

const platforms = [_][]const u8{
    "aarch64-macos",
    "x86_64-macos",
    "aarch64-linux-gnu",
    "x86_64-linux-gnu",
    "x86_64-windows-gnu",
    "aarch64-windows-gnu",
};
