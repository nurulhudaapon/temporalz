const std = @import("std");
const Temporal = @import("temporalz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // --- Instant --- //
    const instant = try Temporal.Instant.init(1_704_067_200_000_000_000); // 2024-01-01 00:00:00 UTC
    defer instant.deinit();
    std.debug.print(
        \\Instant
        \\ - milliseconds: {}
        \\ - nanoseconds: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ instant.epochMilliseconds(), instant.epochNanoseconds(), try instant.toString(allocator, .{}) });

    // --- Duration --- //
    const dur = try Temporal.Duration.from("P1Y2M3DT4H5M6S");
    defer dur.deinit();
    std.debug.print(
        \\Duration
        \\ - nanoseconds: {}
        \\ - milliseconds: {}
        \\ - seconds: {}
        \\ - minutes: {}
        \\ - hours: {}
        \\ - days: {}
        \\ - weeks: {}
        \\ - months: {}
        \\ - years: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ dur.nanoseconds(), dur.milliseconds(), dur.seconds(), dur.minutes(), dur.hours(), dur.days(), dur.weeks(), dur.months(), dur.years(), try dur.toString(allocator, .{}) });

    // --- Now --- //
    const now_instant = try Temporal.Now.instant();
    defer now_instant.deinit();
    const now_date = try Temporal.Now.plainDateISO();
    defer now_date.deinit();
    const now_datetime = try Temporal.Now.plainDateTimeISO();
    const now_time = try Temporal.Now.plainTimeISO();
    std.debug.print(
        \\Now
        \\ - instant: {s}
        \\ - date: {s}
        \\ - datetime: {s}
        \\ - time: {s}
        \\
        \\
    , .{ try now_instant.toString(allocator, .{}), try now_date.toString(allocator, .{}), try now_datetime.toString(allocator, .{}), try now_time.toString(allocator) });

    // --- PlainDate --- //
    const date = try Temporal.PlainDate.init(2024, 2, 2);
    defer date.deinit();
    std.debug.print(
        \\PlainDate
        \\ - year: {}
        \\ - month: {}
        \\ - day: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ date.year(), date.month(), date.day(), try date.toString(allocator, .{}) });

    // --- PlainDateTime --- //
    const dt = try Temporal.PlainDateTime.init(2024, 2, 2, 13, 45, 30, 123, 456, 789);
    std.debug.print(
        \\PlainDateTime
        \\ - year: {}
        \\ - month: {}
        \\ - day: {}
        \\ - hour: {}
        \\ - minute: {}
        \\ - second: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ dt.year(), dt.month(), dt.day(), dt.hour(), dt.minute(), dt.second(), try dt.toString(allocator, .{}) });

    // --- PlainMonthDay --- //
    const md = try Temporal.PlainMonthDay.init(2, 2, null);
    std.debug.print(
        \\PlainMonthDay
        \\ - monthCode: {s}
        \\ - day: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ try md.monthCode(allocator), md.day(), try md.toString(allocator) });

    // --- PlainTime --- //
    const tm = try Temporal.PlainTime.init(13, 45, 30, 123, 456, 789);
    std.debug.print(
        \\PlainTime
        \\ - hour: {}
        \\ - minute: {}
        \\ - second: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ tm.hour(), tm.minute(), tm.second(), try tm.toString(allocator) });

    // --- PlainYearMonth --- //
    const ym = try Temporal.PlainYearMonth.init(2024, 2, null);
    std.debug.print(
        \\PlainYearMonth
        \\ - year: {}
        \\ - month: {}
        \\ - toString(): {s}
        \\
        \\
    , .{ ym.year(), ym.month(), try ym.toString(allocator) });

    // --- ZonedDateTime --- //
    const tz = try Temporal.ZonedDateTime.TimeZone.init("UTC");
    // Example: 2024-02-02T13:45:30.123456789Z in nanoseconds since epoch
    const zdt_epoch_ns: i128 = 1706881530123456789;
    const zdt = try Temporal.ZonedDateTime.fromEpochNanoseconds(zdt_epoch_ns, tz);
    defer zdt.deinit();
    std.debug.print(
        \\ZonedDateTime
        \\ - year: {}
        \\ - month: {}
        \\ - day: {}
        \\ - hour: {}
        \\ - minute: {}
        \\ - second: {}
        \\ - timeZone: {s}
        \\ - toString(): {s}
        \\
        \\
    , .{ zdt.year(), zdt.month(), zdt.day(), zdt.hour(), zdt.minute(), zdt.second(), try zdt.timeZoneId(allocator), try zdt.toString(allocator, .{}) });
}
