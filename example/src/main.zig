const std = @import("std");
const Temporal = @import("temporalz");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

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
    , .{
        instant.epochMilliseconds(),
        instant.epochNanoseconds(),
        try instant.toString(allocator, .{}),
    });

    // --- Duration --- //
    const dur = try Temporal.Duration.from("PT1H");
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
    , .{
        dur.nanoseconds(),
        dur.milliseconds(),
        dur.seconds(),
        dur.minutes(),
        dur.hours(),
        dur.days(),
        dur.weeks(),
        dur.months(),
        dur.years(),
        try dur.toString(allocator, .{}),
    });

    // --- Now --- //
    const now_instant = try Temporal.Now.instant(io);
    defer now_instant.deinit();
    const now_date = try Temporal.Now.plainDateISO(io);
    defer now_date.deinit();
    const now_datetime = try Temporal.Now.plainDateTimeISO(io);
    const now_time = try Temporal.Now.plainTimeISO(io);
    std.debug.print(
        \\Now
        \\ - instant: {s}
        \\ - date: {s}
        \\ - datetime: {s}
        \\ - time: {s}
        \\
        \\
    , .{
        try now_instant.toString(allocator, .{}),
        try now_date.toString(allocator, .{}),
        try now_datetime.toString(allocator, .{}),
        try now_time.toString(allocator),
    });

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
    , .{
        date.year(),
        date.month(),
        date.day(),
        try date.toString(allocator, .{}),
    });

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
    , .{
        dt.year(),
        dt.month(),
        dt.day(),
        dt.hour(),
        dt.minute(),
        dt.second(),
        try dt.toString(allocator, .{}),
    });

    // --- PlainMonthDay --- //
    const md = try Temporal.PlainMonthDay.init(2, 2, null);
    std.debug.print(
        \\PlainMonthDay
        \\ - monthCode: {s}
        \\ - day: {}
        \\ - toString(): {s}
        \\
        \\
    , .{
        try md.monthCode(allocator),
        md.day(),
        try md.toString(allocator),
    });

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
    , .{
        tm.hour(),
        tm.minute(),
        tm.second(),
        try tm.toString(allocator),
    });

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
    , .{
        zdt.year(),
        zdt.month(),
        zdt.day(),
        zdt.hour(),
        zdt.minute(),
        zdt.second(),
        try zdt.timeZoneId(allocator),
        try zdt.toString(allocator, .{}),
    });

    // ----
    // More complex Temporal API examples
    // ----

    // Duration arithmetic
    const dur1 = try Temporal.Duration.from("P1DT2H");
    const dur2 = try Temporal.Duration.from("PT30M");
    const dur_sum = try dur1.add(dur2);
    std.debug.print(
        \\Duration Arithmetic
        \\ - dur1: {s}
        \\ - dur2: {s}
        \\ - dur1 + dur2: {s}
        \\
        \\
    , .{
        try dur1.toString(allocator, .{}),
        try dur2.toString(allocator, .{}),
        try dur_sum.toString(allocator, .{}),
    });

    // Instant comparison and arithmetic
    const inst1 = try Temporal.Instant.init(1_704_067_200_000_000_000);
    const inst2 = try Temporal.Instant.init(1_704_153_600_000_000_000); // +1 day
    const inst_diff = try inst2.since(inst1, Temporal.Instant.DifferenceSettings{});
    std.debug.print(
        \\Instant Comparison
        \\ - inst1: {s}
        \\ - inst2: {s}
        \\ - inst2.since(inst1): {s}
        \\
        \\
    , .{
        try inst1.toString(allocator, .{}),
        try inst2.toString(allocator, .{}),
        try inst_diff.toString(allocator, .{}),
    });

    // PlainDate to PlainDateTime and back
    const pd = try Temporal.PlainDate.init(2024, 2, 2);
    const pdt = try pd.toPlainDateTime(try Temporal.PlainTime.init(12, 0, 0, 0, 0, 0));
    std.debug.print(
        \\PlainDate/PlainDateTime Conversion
        \\ - PlainDate: {s}
        \\ - toPlainDateTime(12:00): {s}
        \\ - toPlainDate(): {s}
        \\
        \\
    , .{
        try pd.toString(allocator, .{}),
        try pdt.toString(allocator, .{}),
        try (try pdt.toPlainDate()).toString(allocator, .{}),
    });

    // ZonedDateTime to Instant and back
    const zdt2 = try Temporal.ZonedDateTime.fromEpochNanoseconds(1706881530123456789, tz);
    const zdt2_inst = try zdt2.toInstant();
    const zdt2_from_inst = try Temporal.ZonedDateTime.fromEpochNanoseconds(zdt2_inst.epochNanoseconds(), tz);
    std.debug.print(
        \\ZonedDateTime/Instant Conversion
        \\ - ZonedDateTime: {s}
        \\ - toInstant(): {s}
        \\ - fromEpochNanoseconds(instant): {s}
        \\
        \\
    , .{
        try zdt2.toString(allocator, .{}),
        try zdt2_inst.toString(allocator, .{}),
        try zdt2_from_inst.toString(allocator, .{}),
    });

    // ----
    // Further more complex examples covering more methods
    // ----

    // Duration: abs, negated, round, subtract, total, valueOf
    const dur_neg = dur.negated();
    const dur_abs = dur_neg.abs();
    const dur_sub = try dur.subtract(dur2);
    const dur_rounded = try dur.round(.{ .smallest_unit = Temporal.Duration.Unit.hour });
    const dur_total_hours = try dur.total(.{ .unit = Temporal.Duration.Unit.hour });
    std.debug.print(
        \\Duration Advanced
        \\ - negated: {s}
        \\ - abs: {s}
        \\ - subtract dur2: {s}
        \\ - round to hour: {s}
        \\ - total hours: {d}
        \\
        \\
    , .{
        try dur_neg.toString(allocator, .{}),
        try dur_abs.toString(allocator, .{}),
        try dur_sub.toString(allocator, .{}),
        try dur_rounded.toString(allocator, .{}),
        dur_total_hours,
    });

    // Instant: add, subtract, round, equals, valueOf
    const inst_add = try inst1.add(@constCast(&dur));
    const inst_sub = try inst2.subtract(@constCast(&dur));
    const inst_rounded = try inst1.round(.{ .smallest_unit = Temporal.Instant.Unit.second });
    const inst_eq = Temporal.Instant.compare(inst1, inst1) == 0;
    std.debug.print(
        \\Instant Advanced
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - round to second: {s}
        \\ - inst1 equals inst1: {}
        \\
        \\
    , .{
        try inst_add.toString(allocator, .{}),
        try inst_sub.toString(allocator, .{}),
        try inst_rounded.toString(allocator, .{}),
        inst_eq,
    });

    // PlainDate: add, subtract, with, equals, since, until, withCalendar
    const date_added = try date.add(dur);
    const date_sub = try date.subtract(dur);
    // const date_with = try date.with(.{ .year = 2025 });
    const date_eq = date.equals(date);
    const date_since = try date.since(date, Temporal.PlainDate.DifferenceSettings{});
    const date_until = try date.until(date, Temporal.PlainDate.DifferenceSettings{});
    const date_with_cal = try date.withCalendar("iso8601");
    std.debug.print(
        \\PlainDate Advanced
        \\ - equals self: {}
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - since self: {s}
        \\ - until self: {s}
        \\ - withCalendar: {s}
        \\ - with year=2025: {{s}}
        \\
        \\
    ,
        .{
            date_eq,
            try date_added.toString(allocator, .{}),
            try date_sub.toString(allocator, .{}),
            try date_since.toString(allocator, .{}),
            try date_until.toString(allocator, .{}),
            try date_with_cal.toString(allocator, .{}),
            // try date_with.toString(allocator, .{}),
        },
    );

    // PlainDateTime: add, subtract, round, with, equals, since, until, withCalendar, withPlainTime
    const dt_added = try dt.add(dur);
    const dt_sub = try dt.subtract(dur);
    const dt_rounded = try dt.round(.{ .smallest_unit = Temporal.PlainDateTime.Unit.minute });
    const dt_with = try dt.with(.{ .year = 2025 });
    const dt_eq = dt.equals(dt);
    const dt_since = try dt.since(dt, Temporal.PlainDateTime.DifferenceSettings{});
    const dt_until = try dt.until(dt, Temporal.PlainDateTime.DifferenceSettings{});
    const dt_with_cal = try dt.withCalendar("iso8601");
    const dt_with_time = try dt.withPlainTime(try Temporal.PlainTime.init(1, 2, 3, 4, 5, 6));
    std.debug.print(
        \\PlainDateTime Advanced
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - round to minute: {s}
        \\ - with year=2025: {s}
        \\ - equals self: {}
        \\ - since self: {s}
        \\ - until self: {s}
        \\ - withCalendar: {s}
        \\ - withPlainTime: {s}
        \\
        \\
    , .{
        try dt_added.toString(allocator, .{}),
        try dt_sub.toString(allocator, .{}),
        try dt_rounded.toString(allocator, .{}),
        try dt_with.toString(allocator, .{}),
        dt_eq,
        try dt_since.toString(allocator, .{}),
        try dt_until.toString(allocator, .{}),
        try dt_with_cal.toString(allocator, .{}),
        try dt_with_time.toString(allocator, .{}),
    });

    // PlainTime: add, subtract, round, with, equals, since, until
    const tm_added = try tm.add(dur);
    const tm_sub = try tm.subtract(dur);
    const tm_rounded = try tm.round(.{ .smallest_unit = Temporal.PlainTime.Unit.second });
    const tm_with = try tm.with(.{ .hour = 1 });
    const tm_eq = tm.equals(tm);
    const tm_since = try tm.since(tm, Temporal.PlainTime.DifferenceSettings{});
    const tm_until = try tm.until(tm, Temporal.PlainTime.DifferenceSettings{});
    std.debug.print(
        \\PlainTime Advanced
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - round to second: {s}
        \\ - with hour=1: {s}
        \\ - equals self: {}
        \\ - since self: {s}
        \\ - until self: {s}
        \\
        \\
    , .{
        try tm_added.toString(allocator),
        try tm_sub.toString(allocator),
        try tm_rounded.toString(allocator),
        try tm_with.toString(allocator),
        tm_eq,
        try tm_since.toString(allocator, .{}),
        try tm_until.toString(allocator, .{}),
    });

    // PlainYearMonth: add, subtract, with, equals, since, until, withCalendar
    const ym_added = try ym.add(dur);
    const ym_sub = try ym.subtract(dur);
    const ym_with = try ym.with(.{ .year = 2025 });
    const ym_eq = ym.equals(ym);
    const ym_since = try ym.since(ym, Temporal.PlainYearMonth.DifferenceSettings{});
    const ym_until = try ym.until(ym, Temporal.PlainYearMonth.DifferenceSettings{});
    std.debug.print(
        \\PlainYearMonth Advanced
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - with year=2025: {s}
        \\ - equals self: {}
        \\ - since self: {s}
        \\ - until self: {s}
        \\
        \\
    , .{
        try ym_added.toString(allocator),
        try ym_sub.toString(allocator),
        try ym_with.toString(allocator),
        ym_eq,
        try ym_since.toString(allocator, .{}),
        try ym_until.toString(allocator, .{}),
    });

    // ZonedDateTime: add, subtract, round, with, equals, since, until, withCalendar, withPlainTime, withTimeZone
    const zdt_added = try zdt.add(dur);
    const zdt_sub = try zdt.subtract(dur);
    const zdt_rounded = try zdt.round(.{ .smallest_unit = Temporal.ZonedDateTime.Unit.hour });
    // const zdt_with = try zdt.with(allocator, .{ .year = 2025 });
    const zdt_eq = zdt.equals(zdt);
    const zdt_since = try zdt.since(zdt, Temporal.ZonedDateTime.DifferenceSettings{});
    const zdt_until = try zdt.until(zdt, Temporal.ZonedDateTime.DifferenceSettings{});
    const zdt_with_cal = try zdt.withCalendar("iso8601");
    const zdt_with_time = try zdt.withPlainTime(try Temporal.PlainTime.init(1, 2, 3, 4, 5, 6));
    const zdt_with_tz = try zdt.withTimeZone(tz);
    std.debug.print(
        \\ZonedDateTime Advanced
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - round to hour: {s}
        \\ - with year=2025: {{s}}
        \\ - equals self: {}
        \\ - since self: {s}
        \\ - until self: {s}
        \\ - withCalendar: {s}
        \\ - withPlainTime: {s}
        \\ - withTimeZone: {s}
        \\
        \\
    , .{
        try zdt_added.toString(allocator, .{}),
        try zdt_sub.toString(allocator, .{}),
        try zdt_rounded.toString(allocator, .{}),
        // try zdt_with.toString(allocator, .{}),
        zdt_eq,
        try zdt_since.toString(allocator, .{}),
        try zdt_until.toString(allocator, .{}),
        try zdt_with_cal.toString(allocator, .{}),
        try zdt_with_time.toString(allocator, .{}),
        try zdt_with_tz.toString(allocator, .{}),
    });
}
