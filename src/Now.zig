const std = @import("std");
const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");

/// # Temporal.Now
///
/// The `Temporal.Now` namespace object contains static methods for getting the current time in various formats.
///
/// - [MDN Temporal.Now](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now)
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
/// See: [MDN Temporal.Now.instant](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/instant)
pub fn instant(io: std.Io) !Instant {
    const ns = std.Io.Timestamp.now(io, .real).nanoseconds;
    return Instant.fromEpochNanoseconds(ns);
}

/// Returns the current date as a [`Temporal.PlainDate`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDate) object, in the ISO 8601 calendar and the specified time zone.
///
/// See: [MDN Temporal.Now.plainDateISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/plainDateISO)
pub fn plainDateISO(io: std.Io) !PlainDate {
    const now = currentParts(io);
    return PlainDate.init(now.year, now.month, now.day);
}

/// Returns the current date and time as a [`Temporal.PlainDateTime`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDateTime) object, in the ISO 8601 calendar and the specified time zone.
///
/// See: [MDN Temporal.Now.plainDateTimeISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/plainDateTimeISO)
pub fn plainDateTimeISO(io: std.Io) !PlainDateTime {
    const now = currentParts(io);
    return PlainDateTime.init(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond,
        now.nanosecond,
    );
}

/// Returns the current time as a [`Temporal.PlainTime`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime) object, in the specified time zone.
///
/// See: [MDN Temporal.Now.plainTimeISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/plainTimeISO)
pub fn plainTimeISO(io: std.Io) !PlainTime {
    const now = currentParts(io);
    return PlainTime.init(
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond,
        now.nanosecond,
    );
}

/// Returns a time zone identifier representing the system's current time zone.
///
/// See: [MDN Temporal.Now.timeZoneId](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/timeZoneId)
pub fn timeZoneId() []const u8 {
    return "UTC";
}

/// Returns the current date and time as a [`Temporal.ZonedDateTime`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime) object, in the ISO 8601 calendar and the specified time zone.
///
/// See: [MDN Temporal.Now.zonedDateTimeISO](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now/zonedDateTimeISO)
pub fn zonedDateTimeISO() !ZonedDateTime {
    return error.TemporalNotImplemented;
}

const CurrentParts = struct {
    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
    millisecond: u16,
    microsecond: u16,
    nanosecond: u16,
};

fn currentParts(io: std.Io) CurrentParts {
    const ns = std.Io.Timestamp.now(io, .real).nanoseconds;
    const seconds: i64 = @intCast(@divTrunc(ns, 1_000_000_000));
    const subsec_nanos_u64: u64 = @intCast(@rem(ns, 1_000_000_000));

    const days_since_epoch: u64 = @intCast(@divTrunc(seconds, std.time.epoch.secs_per_day));
    const secs_of_day: u64 = @intCast(@mod(seconds, std.time.epoch.secs_per_day));

    const epoch_day = std.time.epoch.EpochDay{ .day = @intCast(days_since_epoch) };
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = std.time.epoch.DaySeconds{ .secs = @intCast(secs_of_day) };

    const millisecond: u16 = @intCast(subsec_nanos_u64 / 1_000_000);
    const microsecond: u16 = @intCast((subsec_nanos_u64 / 1_000) % 1_000);
    const nanosecond: u16 = @intCast(subsec_nanos_u64 % 1_000);

    return .{
        .year = @intCast(year_day.year),
        .month = @intCast(month_day.month.numeric()),
        .day = @intCast(month_day.day_index + 1),
        .hour = @intCast(day_seconds.getHoursIntoDay()),
        .minute = @intCast(day_seconds.getMinutesIntoHour()),
        .second = @intCast(day_seconds.getSecondsIntoMinute()),
        .millisecond = millisecond,
        .microsecond = microsecond,
        .nanosecond = nanosecond,
    };
}

// ---------- Tests ---------------------
test instant {
    const io = std.testing.io;
    const inst = try instant(io);
    defer inst.deinit();
    try std.testing.expect(inst.epochNanoseconds() > 0);
}

test plainDateISO {
    const io = std.testing.io;
    const date = try plainDateISO(io);
    try std.testing.expect(date.year() >= 1970);
    try std.testing.expect(date.month() >= 1 and date.month() <= 12);
    try std.testing.expect(date.day() >= 1 and date.day() <= 31);
}
test plainDateTimeISO {
    const io = std.testing.io;
    const dt = try plainDateTimeISO(io);
    try std.testing.expect(dt.year() >= 1970);
    try std.testing.expect(dt.month() >= 1 and dt.month() <= 12);
    try std.testing.expect(dt.day() >= 1 and dt.day() <= 31);
    try std.testing.expect(dt.hour() < 24);
    try std.testing.expect(dt.minute() < 60);
}
test plainTimeISO {
    const io = std.testing.io;
    const t = try plainTimeISO(io);
    try std.testing.expect(t.hour() < 24);
    try std.testing.expect(t.minute() < 60);
    try std.testing.expect(t.second() < 60);
}
test timeZoneId {
    const tz = timeZoneId();
    try std.testing.expectEqualStrings("UTC", tz);
}
test zonedDateTimeISO {
    try std.testing.expectError(error.TemporalNotImplemented, zonedDateTimeISO());
}
