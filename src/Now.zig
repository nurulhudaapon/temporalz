const std = @import("std");
const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const SystemTimeZone = @import("SystemTimeZone.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");
const abi = @import("abi.zig");

/// # Temporal.Now
///
/// The `Temporal.Now` namespace object contains static methods for getting the current time in various formats.
///
/// See: [Temporal.Now](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now)
///
/// ## Description
///
/// Unlike most global objects, `Temporal.Now` is not a constructor. All properties and methods are static.
///
/// ## Example
///
/// ```js
/// Temporal.Now.instant();
/// Temporal.Now.plainDateISO();
/// Temporal.Now.plainDateTimeISO();
/// Temporal.Now.plainTimeISO();
/// Temporal.Now.timeZoneId();
/// Temporal.Now.zonedDateTimeISO();
/// ```
const Now = @This();

/// Returns the current time as a [`Temporal.Instant`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Instant) object.
///
/// See: [Temporal.Now.instant](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/instant)
pub fn instant(io: std.Io) !Instant {
    const ns = std.Io.Timestamp.now(io, .real).nanoseconds;
    return Instant.fromEpochNanoseconds(ns);
}

/// Returns the current date as a [`Temporal.PlainDate`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDate) object, in the ISO 8601 calendar and the specified time zone.
///
/// When `time_zone_like` is null, the system time zone is used.
///
/// See: [Temporal.Now.plainDateISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/plainDateISO)
pub fn plainDateISO(allocator: std.mem.Allocator, io: std.Io, time_zone_like: ?[]const u8) !PlainDate {
    const time_zone = try resolveTimeZone(allocator, io, time_zone_like);
    const now = try instant(io);
    defer now.deinit();

    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_from_epoch_nanoseconds(
        abi.toI128Nanoseconds(now.epochNanoseconds()),
        abi.to.toTimeZone(time_zone),
    ))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns the current date and time as a [`Temporal.PlainDateTime`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDateTime) object, in the ISO 8601 calendar and the specified time zone.
///
/// When `time_zone_like` is null, the system time zone is used.
///
/// See: [Temporal.Now.plainDateTimeISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/plainDateTimeISO)
pub fn plainDateTimeISO(allocator: std.mem.Allocator, io: std.Io, time_zone_like: ?[]const u8) !PlainDateTime {
    const time_zone = try resolveTimeZone(allocator, io, time_zone_like);
    const now = try instant(io);
    defer now.deinit();

    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDateTime_from_epoch_nanoseconds(
        abi.toI128Nanoseconds(now.epochNanoseconds()),
        abi.to.toTimeZone(time_zone),
    ))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns the current time as a [`Temporal.PlainTime`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime) object, in the specified time zone.
///
/// When `time_zone_like` is null, the system time zone is used.
///
/// See: [Temporal.Now.plainTimeISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/plainTimeISO)
pub fn plainTimeISO(allocator: std.mem.Allocator, io: std.Io, time_zone_like: ?[]const u8) !PlainTime {
    const time_zone = try resolveTimeZone(allocator, io, time_zone_like);
    const now = try instant(io);
    defer now.deinit();

    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainTime_from_epoch_nanoseconds(
        abi.toI128Nanoseconds(now.epochNanoseconds()),
        abi.to.toTimeZone(time_zone),
    ))) orelse return abi.TemporalError.Generic;
    return PlainTime{ ._inner = ptr };
}

/// Returns a time zone identifier representing the system's current time zone.
///
/// The caller owns the returned slice and must free it with `allocator`.
///
/// See: [Temporal.Now.timeZoneId](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/timeZoneId)
pub fn timeZoneId(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    const time_zone = try SystemTimeZone.timeZone(allocator, io);
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_TimeZone_identifier(time_zone._inner, &write.inner);
    return try write.toOwnedSlice();
}

/// Returns the current date and time as a [`Temporal.ZonedDateTime`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime) object, in the ISO 8601 calendar and the specified time zone.
///
/// When `time_zone_like` is null, the system time zone is used.
///
/// See: [Temporal.Now.zonedDateTimeISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/zonedDateTimeISO)
pub fn zonedDateTimeISO(allocator: std.mem.Allocator, io: std.Io, time_zone_like: ?[]const u8) !ZonedDateTime {
    const now = try instant(io);
    defer now.deinit();
    const time_zone = try resolveTimeZone(allocator, io, time_zone_like);
    return ZonedDateTime.fromEpochNanoseconds(now.epochNanoseconds(), time_zone);
}

fn resolveTimeZone(allocator: std.mem.Allocator, io: std.Io, time_zone_like: ?[]const u8) !ZonedDateTime.TimeZone {
    if (time_zone_like) |id| return ZonedDateTime.TimeZone.init(id);
    return SystemTimeZone.timeZone(allocator, io);
}

test instant {
    const io = std.testing.io;
    const inst = try instant(io);
    defer inst.deinit();
    try std.testing.expect(inst.epochNanoseconds() > 0);
}

test plainDateISO {
    const io = std.testing.io;
    const date = try plainDateISO(std.testing.allocator, io, null);
    defer date.deinit();
    try std.testing.expect(date.year() >= 1970);
    try std.testing.expect(date.month() >= 1 and date.month() <= 12);
    try std.testing.expect(date.day() >= 1 and date.day() <= 31);
}

test plainDateTimeISO {
    const io = std.testing.io;
    var dt = try plainDateTimeISO(std.testing.allocator, io, null);
    defer dt.deinit();
    try std.testing.expect(dt.year() >= 1970);
    try std.testing.expect(dt.month() >= 1 and dt.month() <= 12);
    try std.testing.expect(dt.day() >= 1 and dt.day() <= 31);
    try std.testing.expect(dt.hour() < 24);
    try std.testing.expect(dt.minute() < 60);
}

test plainTimeISO {
    const io = std.testing.io;
    const t = try plainTimeISO(std.testing.allocator, io, null);
    try std.testing.expect(t.hour() < 24);
    try std.testing.expect(t.minute() < 60);
    try std.testing.expect(t.second() < 60);
}

test timeZoneId {
    const io = std.testing.io;
    const tz = try timeZoneId(std.testing.allocator, io);
    defer std.testing.allocator.free(tz);
    try std.testing.expect(tz.len > 0);
    _ = try ZonedDateTime.TimeZone.init(tz);
}

test zonedDateTimeISO {
    const io = std.testing.io;
    const zdt = try zonedDateTimeISO(std.testing.allocator, io, null);
    defer zdt.deinit();

    try std.testing.expect(zdt.epochNanoseconds() > 0);
    const tz = try zdt.timeZoneId(std.testing.allocator);
    defer std.testing.allocator.free(tz);
    const expected_tz = try timeZoneId(std.testing.allocator, io);
    defer std.testing.allocator.free(expected_tz);
    try std.testing.expectEqualStrings(expected_tz, tz);
}

test "plainDateISO with explicit time zone" {
    const io = std.testing.io;
    const date = try plainDateISO(std.testing.allocator, io, "UTC");
    defer date.deinit();

    const zdt = try zonedDateTimeISO(std.testing.allocator, io, "UTC");
    defer zdt.deinit();
    const plain = try zdt.toPlainDate();
    defer plain.deinit();

    try std.testing.expect(date.equals(plain));
}
