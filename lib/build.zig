const std = @import("std");
const targets = @import("targets.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const force_build_rust = b.option(bool, "build-rust", "Always build Rust library from source") orelse false;

    const arch_str = @tagName(target.result.cpu.arch);
    const os_str = @tagName(target.result.os.tag);
    const abi = target.result.abi;
    const target_triple = if (abi == .none)
        b.fmt("{s}-{s}", .{ arch_str, os_str })
    else
        b.fmt("{s}-{s}-{s}", .{ arch_str, os_str, @tagName(abi) });
    const prebuilt_name = targets.prebuiltName(b, target);

    const lib_name = if (target.result.os.tag == .windows and abi == .msvc)
        "temporal_capi.lib"
    else
        "libtemporal_capi.a";

    // --- Module --- //
    const mod = b.addModule("libtemporal", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const temporal_rs = b.dependency("temporal_rs", .{
        .target = target,
        .optimize = optimize,
    });

    const translated = b.addTranslateC(.{
        .root_source_file = b.path("src/lib.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });
    translated.addIncludePath(temporal_rs.path("temporal_capi/bindings/c"));
    translated.addIncludePath(b.path("src/stubs/c_headers"));
    mod.addImport("lib", translated.createModule());

    // --- Rust Misc Deps --- //
    if (target.result.os.tag == .windows) mod.linkSystemLibrary("userenv", .{});
    const unwind_stubs = b.addLibrary(.{ .linkage = .static, .name = "unwind_stubs", .root_module = b.createModule(.{
        .root_source_file = b.path("src/stubs/unwind.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    mod.linkLibrary(unwind_stubs);

    // --- Steps: update prebuilt dependency hashes --- //
    {
        const update_step = b.step("update", "Fetch prebuilt packages and update build.zig.zon");
        addPrebuiltDependencyFetches(b, update_step);
    }

    // --- Static lib resolution (prebuilt or source) --- //
    var selected_lib_file: std.Build.LazyPath = undefined;

    if (!force_build_rust and targets.isDeclared(prebuilt_name)) {
        const prebuilt_dep = b.lazyDependency(prebuilt_name, .{}) orelse {
            return;
        };
        std.log.info("using prebuilt libtemporal for {s}", .{prebuilt_name});
        selected_lib_file = prebuilt_dep.path(lib_name);
    } else {
        std.log.info("building libtemporal from source for {s}, requires Rust toolchain", .{target_triple});
        const build_crab = @import("build_crab");

        var zig_target = target.result;
        if (zig_target.os.tag == .windows) zig_target.abi = .gnu;
        const rust_target_str: []const u8 = if (zig_target.cpu.arch == .arm and zig_target.os.tag == .linux)
            switch (zig_target.abi) {
                .gnueabihf, .eabihf => "armv7-unknown-linux-gnueabihf",
                .gnueabi, .eabi => "armv7-unknown-linux-gnueabi",
                .musleabihf => "armv7-unknown-linux-musleabihf",
                .musleabi => "armv7-unknown-linux-musleabi",
                else => "armv7-unknown-linux-gnueabihf",
            }
        else blk: {
            const rust_target = build_crab.rust.Target.fromZig(zig_target) catch
                @panic("unable to convert target triple to Rust");
            break :blk b.fmt("{f}", .{rust_target});
        };
        const build_dir = build_crab.addCargoBuild(
            b,
            .{
                .manifest_path = b.path("Cargo.toml"),
                .cargo_args = if (optimize == .Debug) &.{} else &.{"--release"},
                .rust_target = .{ .value = rust_target_str },
            },
            .{
                .optimize = .ReleaseSafe,
            },
        );
        selected_lib_file = build_dir.path(b, lib_name);
    }

    mod.addObjectFile(selected_lib_file);

    // --- Install Step (for publishing) --- //
    const install_lib = b.addInstallFile(selected_lib_file, b.fmt("lib/{s}/{s}", .{ prebuilt_name, lib_name }));
    b.getInstallStep().dependOn(&install_lib.step);
}

fn addPrebuiltDependencyFetches(b: *std.Build, parent: *std.Build.Step) void {
    var prev_save: ?*std.Build.Step = null;

    inline for (targets.config.targets) |target_triple| {
        const url = targets.releaseUrl(b, target_triple);

        const fetch = b.addSystemCommand(&.{ b.graph.zig_exe, "fetch", url });
        fetch.setName(b.fmt("fetch {s}", .{target_triple}));
        fetch.setCwd(b.path("."));
        fetch.has_side_effects = true;
        fetch.expectExitCode(0);
        _ = fetch.captureStdErr(.{});

        const save = b.addSystemCommand(&.{
            b.graph.zig_exe,
            "fetch",
            b.fmt("--save={s}", .{target_triple}),
            url,
        });
        save.setName(b.fmt("save {s}", .{target_triple}));
        save.setCwd(b.path("."));
        save.has_side_effects = true;
        save.expectExitCode(0);
        _ = save.captureStdErr(.{});

        save.step.dependOn(&fetch.step);

        if (prev_save) |prev| {
            save.step.dependOn(prev);
        }
        parent.dependOn(&save.step);
        prev_save = &save.step;
    }
}
