const std = @import("std");
const build_crab = @import("build_crab");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Rust Crate Build --- //
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

    const lib_name = if (target.result.os.tag == .windows and target.result.abi == .msvc)
        "temporal_capi.lib"
    else
        "libtemporal_capi.a";

    const lib_file = build_dir.path(b, lib_name);

    // --- Install Step (for publishing) --- //
    const arch_str = @tagName(target.result.cpu.arch);
    const os_str = @tagName(target.result.os.tag);
    const abi = target.result.abi;
    const target_triple = if (abi == .none)
        b.fmt("{s}-{s}", .{ arch_str, os_str })
    else
        b.fmt("{s}-{s}-{s}", .{ arch_str, os_str, @tagName(abi) });

    const install_lib = b.addInstallFile(lib_file, b.fmt("lib/{s}/{s}", .{ target_triple, lib_name }));
    b.getInstallStep().dependOn(&install_lib.step);

    // --- Zig Module --- //
    const mod = b.addModule("temporal_rs", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addObjectFile(lib_file);

    // --- Library Artifact (for explicit linking) --- //
    const lib_artifact = b.addLibrary(.{
        .name = "temporal_rs_lib",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    lib_artifact.root_module.addObjectFile(lib_file);
    b.installArtifact(lib_artifact);

    // --- Steps: Build all platforms --- //
    {
        const build_lib_step = b.step("lib", "Build libraries for all common platforms");

        inline for (platforms) |p| {
            const query = try std.Build.parseTargetQuery(.{ .arch_os_abi = p });
            const platform_target = b.resolveTargetQuery(query);

            const platform_build_dir = build_crab.addCargoBuild(
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

            const platform_lib_name = if (platform_target.result.os.tag == .windows and platform_target.result.abi == .msvc)
                "temporal_capi.lib"
            else
                "libtemporal_capi.a";

            const install_platform_lib = b.addInstallFile(
                platform_build_dir.path(b, platform_lib_name),
                b.fmt("lib/{s}/{s}", .{ p, platform_lib_name }),
            );
            build_lib_step.dependOn(&install_platform_lib.step);
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
    "wasm32-freestanding",
};
