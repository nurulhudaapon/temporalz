const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const is_wasm_freestanding = target.result.cpu.arch.isWasm() and target.result.os.tag == .freestanding;

    const temporalz = b.dependency("temporalz", .{
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "temporalz",
        .root_module = b.createModule(.{
            .root_source_file = b.path(if (is_wasm_freestanding) "src/wasm.zig" else "src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{},
        }),
    });
    exe.root_module.addImport("temporalz", temporalz.module("temporalz"));
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    switch (target.result.os.tag) {
        .freestanding => {
            const run_cmd = b.addSystemCommand(&.{ "node", "src/main.mjs" });
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
