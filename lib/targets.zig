const std = @import("std");
const builtin = @import("builtin");

pub const config = @import("targets.zon");
const manifest = @import("build.zig.zon");

/// Zig `-Dtarget` triple for the host platform's prebuilt dependency name.
pub fn depName() []const u8 {
    const triple = targetTripleFromBuiltin();
    if (!isDeclared(triple)) {
        @compileError(std.fmt.comptimePrint(
            "no prebuilt libtemporal for host {s}",
            .{triple},
        ));
    }
    return triple;
}

pub fn prebuiltName(b: *std.Build, target: std.Build.ResolvedTarget) []const u8 {
    const arch = @tagName(target.result.cpu.arch);
    const os = target.result.os.tag;
    const abi = target.result.abi;

    if (os == .wasi and (abi == .musl or abi == .none))
        return b.fmt("{s}-wasi", .{arch});

    if (abi == .none)
        return b.fmt("{s}-{s}", .{ arch, @tagName(os) });
    return b.fmt("{s}-{s}-{s}", .{ arch, @tagName(os), abiName(target.result.cpu.arch, abi) });
}

/// Zig 0.18 folded the 32-bit ARM float ABIs into `.gnu`/`.gnusf`/`.musl`/`.muslsf`
/// (e.g. `arm-linux-gnueabihf` now parses as `arm-linux-gnu`). Keep the old names
/// so prebuilt dependency keys and release asset names stay stable.
fn abiName(arch: std.Target.Cpu.Arch, abi: std.Target.Abi) []const u8 {
    if (arch.isArm()) switch (abi) {
        .gnu => return "gnueabihf",
        .gnusf => return "gnueabi",
        .musl => return "musleabihf",
        .muslsf => return "musleabi",
        .sf => return "eabi",
        else => {},
    };
    return @tagName(abi);
}

pub fn isDeclared(target_triple: []const u8) bool {
    inline for (config.targets) |supported| {
        if (std.mem.eql(u8, supported, target_triple)) {
            return comptime @hasField(@TypeOf(manifest.dependencies), supported);
        }
    }
    return false;
}

pub fn releaseUrl(b: *std.Build, target_triple: []const u8) []const u8 {
    return b.fmt(
        "https://github.com/nurulhudaapon/temporalz/releases/download/v{s}/{s}.tar.gz",
        .{ config.version, target_triple },
    );
}

fn targetTripleFromBuiltin() []const u8 {
    if (builtin.os.tag == .wasi and (builtin.abi == .musl or builtin.abi == .none))
        return std.fmt.comptimePrint("{s}-wasi", .{@tagName(builtin.cpu.arch)});

    const abi = builtin.abi;
    return if (abi == .none)
        std.fmt.comptimePrint("{s}-{s}", .{ @tagName(builtin.cpu.arch), @tagName(builtin.os.tag) })
    else
        std.fmt.comptimePrint("{s}-{s}-{s}", .{ @tagName(builtin.cpu.arch), @tagName(builtin.os.tag), comptime abiName(builtin.cpu.arch, abi) });
}
