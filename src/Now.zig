const std = @import("std");
const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");

const Now = @This();

pub fn instant() !Instant {
    const ns: i128 = std.time.nanoTimestamp();
    return Instant.fromEpochNanoseconds(ns);
}

pub fn plainDateISO() !PlainDate {
    const now = currentParts();
    return PlainDate.init(now.year, now.month, now.day);
}

pub fn plainDateTimeISO() !PlainDateTime {
    const now = currentParts();
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

pub fn plainTimeISO() !PlainTime {
    const now = currentParts();
    return PlainTime.init(
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond,
        now.nanosecond,
    );
}

pub fn timeZoneId() []const u8 {
    return "UTC";
}

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

fn currentParts() CurrentParts {
    const ns: i128 = std.time.nanoTimestamp();
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
    const inst = try instant();
    defer inst.deinit();
    try std.testing.expect(inst.epochNanoseconds() > 0);
}

test plainDateISO {
    const date = try plainDateISO();
    try std.testing.expect(date.year() >= 1970);
    try std.testing.expect(date.month() >= 1 and date.month() <= 12);
    try std.testing.expect(date.day() >= 1 and date.day() <= 31);
}
test plainDateTimeISO {
    const dt = try plainDateTimeISO();
    try std.testing.expect(dt.year() >= 1970);
    try std.testing.expect(dt.month() >= 1 and dt.month() <= 12);
    try std.testing.expect(dt.day() >= 1 and dt.day() <= 31);
    try std.testing.expect(dt.hour() < 24);
    try std.testing.expect(dt.minute() < 60);
}
test plainTimeISO {
    const t = try plainTimeISO();
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
