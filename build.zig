const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("temporalz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });
    mod.addObjectFile(b.path(getTemporalRsPath(target)));
    mod.link_libc = true;
    if (target.result.os.tag == .linux) mod.linkSystemLibrary("unwind", .{});
    if (target.result.os.tag == .windows) {
        mod.linkSystemLibrary("ws2_32", .{});
        mod.linkSystemLibrary("bcrypt", .{});
        mod.linkSystemLibrary("advapi32", .{});
        mod.linkSystemLibrary("userenv", .{});
        mod.linkSystemLibrary("msvcrt", .{});
    }
    const exe = b.addExecutable(.{
        .name = "temporalz",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "temporalz", .module = mod },
            },
        }),
    });
    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");

    // Tests
    {
        run_step.dependOn(&run_cmd.step);
        const test_step = b.step("test", "Run tests");
        const mod_tests = b.addTest(.{
            .root_module = mod,
            .test_runner = .{
                .path = b.path("test/runner.zig"),
                .mode = .simple,
            },
        });
        mod_tests.linkLibC();
        if (target.result.os.tag == .linux) mod_tests.linkSystemLibrary("unwind");
        if (target.result.os.tag == .windows) {
            mod_tests.linkSystemLibrary("ws2_32");
            mod_tests.linkSystemLibrary("bcrypt");
            mod_tests.linkSystemLibrary("advapi32");
        }
        test_step.dependOn(&b.addRunArtifact(mod_tests).step);
        const exe_tests = b.addTest(.{ .root_module = exe.root_module });
        test_step.dependOn(&b.addRunArtifact(exe_tests).step);
    }

    // Rust cross-compilation prebuild
    {
        const rust_prebuild_step = b.step("temporal-rs", "Build and vendor Rust staticlibs for supported targets");
        var rustup_args: [3 + rust_targets.len][]const u8 = undefined;
        rustup_args[0] = "rustup";
        rustup_args[1] = "target";
        rustup_args[2] = "add";
        for (rust_targets, 0..) |t, i| {
            rustup_args[3 + i] = t.triple;
        }
        const rustup_add = b.addSystemCommand(&rustup_args);
        rust_prebuild_step.dependOn(&rustup_add.step);

        for (rust_targets) |t| {
            const cargo_build = b.addSystemCommand(&.{
                "cargo",
                "build",
                "--release",
                "--manifest-path",
                "vendor/temporal/Cargo.toml",
                "--target",
                t.triple,
            });
            cargo_build.step.dependOn(&rustup_add.step);
            rust_prebuild_step.dependOn(&cargo_build.step);
        }
    }

    // Release builds for all platforms
    {
        const release_targets = [_]struct {
            name: []const u8,
            target: std.Target.Query,
        }{
            .{ .name = "linux-x64", .target = .{ .cpu_arch = .x86_64, .os_tag = .linux } },
            .{ .name = "linux-aarch64", .target = .{ .cpu_arch = .aarch64, .os_tag = .linux } },
            .{ .name = "macos-x64", .target = .{ .cpu_arch = .x86_64, .os_tag = .macos } },
            .{ .name = "macos-aarch64", .target = .{ .cpu_arch = .aarch64, .os_tag = .macos } },
            .{ .name = "windows-x64", .target = .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .msvc } },
            .{ .name = "windows-aarch64", .target = .{ .cpu_arch = .aarch64, .os_tag = .windows, .abi = .msvc } },
        };

        const release_step = b.step("release", "Build release binaries for all targets");

        for (release_targets) |release_target| {
            const resolved_target = b.resolveTargetQuery(release_target.target);

            const release_mod = b.addModule(b.fmt("temporalz-{s}", .{release_target.name}), .{
                .root_source_file = b.path("src/root.zig"),
                .target = resolved_target,
            });
            release_mod.addObjectFile(b.path(getTemporalRsPath(resolved_target)));
            release_mod.link_libc = true;
            if (resolved_target.result.os.tag == .linux) release_mod.linkSystemLibrary("unwind", .{});
            if (resolved_target.result.os.tag == .windows) {
                release_mod.linkSystemLibrary("ws2_32", .{});
                release_mod.linkSystemLibrary("bcrypt", .{});
                release_mod.linkSystemLibrary("advapi32", .{});
                release_mod.linkSystemLibrary("userenv", .{});
                release_mod.linkSystemLibrary("msvcrt", .{});
            }

            const release_exe = b.addExecutable(.{
                .name = "temporalz",
                .root_module = b.createModule(.{
                    .root_source_file = b.path("src/main.zig"),
                    .target = resolved_target,
                    .optimize = .ReleaseSmall,
                    .imports = &.{
                        .{ .name = "temporalz", .module = release_mod },
                    },
                }),
            });
            release_exe.linkLibC();
            if (resolved_target.result.os.tag == .windows) {
                release_exe.linkSystemLibrary("ws2_32");
                release_exe.linkSystemLibrary("bcrypt");
                release_exe.linkSystemLibrary("advapi32");
                release_exe.linkSystemLibrary("userenv");
                release_exe.linkSystemLibrary("msvcrt");
            }

            const exe_ext = if (resolved_target.result.os.tag == .windows) ".exe" else "";
            const install_release = b.addInstallArtifact(release_exe, .{
                .dest_sub_path = b.fmt("release/temporalz-{s}{s}", .{ release_target.name, exe_ext }),
            });

            const target_step = b.step(
                b.fmt("release-{s}", .{release_target.name}),
                b.fmt("Build release binary for {s}", .{release_target.name}),
            );
            target_step.dependOn(&install_release.step);
            release_step.dependOn(&install_release.step);
        }
    }
}

// Supported cross-compilation targets
const rust_targets = [_]struct { triple: []const u8 }{
    .{ .triple = "aarch64-apple-darwin" },
    .{ .triple = "x86_64-apple-darwin" },
    .{ .triple = "x86_64-unknown-linux-gnu" },
    .{ .triple = "aarch64-unknown-linux-gnu" },
    .{ .triple = "x86_64-pc-windows-msvc" },
    .{ .triple = "aarch64-pc-windows-msvc" },
};

// Platform-specific Rust library path resolution
fn getTemporalRsPath(target: std.Build.ResolvedTarget) []const u8 {
    const arch_tag = target.result.cpu.arch;
    return switch (target.result.os.tag) {
        .macos => switch (arch_tag) {
            .aarch64 => "vendor/temporal/target/aarch64-apple-darwin/release/libtemporal.a",
            .x86_64 => "vendor/temporal/target/x86_64-apple-darwin/release/libtemporal.a",
            else => @panic("unsupported macOS architecture"),
        },
        .linux => switch (arch_tag) {
            .x86_64 => "vendor/temporal/target/x86_64-unknown-linux-gnu/release/libtemporal.a",
            .aarch64 => "vendor/temporal/target/aarch64-unknown-linux-gnu/release/libtemporal.a",
            else => @panic("unsupported Linux architecture"),
        },
        .windows => switch (arch_tag) {
            .x86_64 => "vendor/temporal/target/x86_64-pc-windows-msvc/release/temporal.lib",
            .aarch64 => "vendor/temporal/target/aarch64-pc-windows-msvc/release/temporal.lib",
            else => @panic("unsupported Windows architecture"),
        },
        else => @panic("unsupported OS"),
    };
}
