const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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

    const prebuilt_lib_path = b.fmt("{s}/{s}", .{ target_triple, lib_name });

    // --- Pre-built resolution --- //
    const libtemporal_prebuilt = b.lazyDependency("libtemporal_prebuilt", .{});
    var prebuilt_lib_file: ?std.Build.LazyPath = null;

    if (libtemporal_prebuilt) |dep| {
        const lib_file_candidate = dep.path(prebuilt_lib_path);
        const lib_full_path = lib_file_candidate.getPath(b);
        if (std.Io.Dir.cwd().openFile(b.graph.io, lib_full_path, .{})) |lib_check_file| {
            lib_check_file.close(b.graph.io);
            prebuilt_lib_file = lib_file_candidate;
        } else |_| {}
    }

    var selected_lib_file: std.Build.LazyPath = undefined;
    if (prebuilt_lib_file) |lib_file| {
        // std.debug.print("Using pre-built temporal_capi library from downloaded artifact at: {s}\n", .{prebuilt_lib_path});
        selected_lib_file = lib_file;
    } else {
        // std.debug.print("building from source: {s}\n", .{prebuilt_lib_path});
        const build_crab = @import("build_crab");
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
        selected_lib_file = build_dir.path(b, lib_name);

        // --- Install Step (for publishing) --- //
        const install_lib = b.addInstallFile(selected_lib_file, b.fmt("lib/{s}/{s}", .{ target_triple, lib_name }));
        b.getInstallStep().dependOn(&install_lib.step);
    }

    // --- Zig Module --- //
    const mod = b.addModule("temporal_rs", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add Headers
    const temporal_rs_git = b.dependency("temporal_rs", .{
        .target = target,
        .optimize = optimize,
    });
    mod.addIncludePath(temporal_rs_git.path("temporal_capi/bindings/c"));
    mod.addIncludePath(b.path("src/stubs/c_headers"));

    // Add Object/Library
    mod.addObjectFile(selected_lib_file);

    // --- Rust Misc Deps --- //
    if (target.result.os.tag == .windows) mod.linkSystemLibrary("userenv", .{});
    const unwind_stubs = b.addLibrary(.{ .linkage = .static, .name = "unwind_stubs", .root_module = b.createModule(.{
        .root_source_file = b.path("src/stubs/unwind.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    mod.linkLibrary(unwind_stubs);
}
