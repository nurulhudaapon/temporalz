const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("temporalz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });
    mod.addObjectFile(b.path(getTemporalRsPath(target)));

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
            .x86_64 => "vendor/temporal/target/x86_64-pc-windows-msvc/release/libtemporal.lib",
            .aarch64 => "vendor/temporal/target/aarch64-pc-windows-msvc/release/libtemporal.lib",
            else => @panic("unsupported Windows architecture"),
        },
        else => @panic("unsupported OS"),
    };
}
