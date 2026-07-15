const builtin = @import("builtin");
const std = @import("std");

const ZonedDateTime = @import("ZonedDateTime.zig");

const zoneinfo_marker = "zoneinfo/";

/// Returns the host environment's current time zone identifier.
///
/// Resolution order:
/// 1. `TZ` environment variable (when set and non-empty)
/// 2. Unix: `/etc/localtime` symlink target under `zoneinfo/`
/// 3. `"UTC"`
///
/// The caller owns the returned slice.
pub fn identifier(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    if (tzFromEnv(allocator)) |tz| return tz;

    if (detectFromPlatform(allocator, io)) |tz| return tz;

    return try allocator.dupe(u8, "UTC");
}

/// Returns a `TimeZone` for the host environment's current time zone.
pub fn timeZone(allocator: std.mem.Allocator, io: std.Io) !ZonedDateTime.TimeZone {
    const id = try identifier(allocator, io);
    defer allocator.free(id);
    return ZonedDateTime.TimeZone.init(id);
}

fn tzFromEnv(allocator: std.mem.Allocator) ?[]const u8 {
    if (!builtin.link_libc) return null;

    const value = std.c.getenv("TZ") orelse return null;
    const tz = std.mem.span(value);
    if (tz.len == 0) return null;

    return allocator.dupe(u8, tz) catch null;
}

fn detectFromPlatform(allocator: std.mem.Allocator, io: std.Io) ?[]const u8 {
    return switch (builtin.os.tag) {
        .linux, .macos, .freebsd, .openbsd, .netbsd, .dragonfly => detectFromEtcLocaltime(allocator, io) catch null,
        else => null,
    };
}

fn detectFromEtcLocaltime(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    var target_buf: [std.fs.max_path_bytes]u8 = undefined;
    const len = std.Io.Dir.readLinkAbsolute(io, "/etc/localtime", &target_buf) catch return error.NotFound;
    const target = target_buf[0..len];

    const idx = std.mem.lastIndexOf(u8, target, zoneinfo_marker) orelse return error.NotFound;
    return try allocator.dupe(u8, target[idx + zoneinfo_marker.len ..]);
}

test identifier {
    const io = std.testing.io;
    const tz = try identifier(std.testing.allocator, io);
    defer std.testing.allocator.free(tz);
    try std.testing.expect(tz.len > 0);
    _ = try ZonedDateTime.TimeZone.init(tz);
}

test timeZone {
    const io = std.testing.io;
    _ = try timeZone(std.testing.allocator, io);
}
