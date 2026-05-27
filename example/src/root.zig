const std = @import("std");
const builtin = @import("builtin");
const Temporal = @import("temporalz");

pub fn run(allocator: std.mem.Allocator, io_optional: ?std.Io) !void {
    // --- Instant --- //
    const instant = try Temporal.Instant.init(1_704_067_200_000_000_000); // 2024-01-01 00:00:00 UTC
    defer instant.deinit();
    std.log.info(
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
    std.log.info(
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
    if (io_optional) |io| {
        const now_instant = try Temporal.Now.instant(io);
        defer now_instant.deinit();
        const now_date = try Temporal.Now.plainDateISO(io);
        defer now_date.deinit();
        const now_datetime = try Temporal.Now.plainDateTimeISO(io);
        const now_time = try Temporal.Now.plainTimeISO(io);
        std.log.info(
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
    }

    // --- PlainDate --- //
    const date = try Temporal.PlainDate.init(2024, 2, 2);
    defer date.deinit();
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    std.log.info(
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
    const date_with = try date.with(.{ .year = 2025 });
    const date_eq = date.equals(date);
    const date_since = try date.since(date, Temporal.PlainDate.DifferenceSettings{});
    const date_until = try date.until(date, Temporal.PlainDate.DifferenceSettings{});
    const date_with_cal = try date.withCalendar("iso8601");
    std.log.info(
        \\PlainDate Advanced
        \\ - equals self: {}
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - since self: {s}
        \\ - until self: {s}
        \\ - withCalendar: {s}
        \\ - with year=2025: {s}
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
            try date_with.toString(allocator, .{}),
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
    std.log.info(
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
    std.log.info(
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

    // PlainYearMonth: add, subtract, with, equals, since, until
    const dur_ym = try Temporal.Duration.from("P1M");
    defer dur_ym.deinit();
    const ym_added = try ym.add(dur_ym);
    const ym_sub = try ym.subtract(dur_ym);
    const ym_with = try ym.with(.{ .year = 2025 });
    const ym_eq = ym.equals(ym);
    const ym_since = try ym.since(ym, Temporal.PlainYearMonth.DifferenceSettings{});
    const ym_until = try ym.until(ym, Temporal.PlainYearMonth.DifferenceSettings{});
    std.log.info(
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

    // ZonedDateTime: add, subtract, round, equals, since, until, withCalendar, withPlainTime, withTimeZone
    const zdt_added = try zdt.add(dur);
    const zdt_sub = try zdt.subtract(dur);
    const zdt_rounded = try zdt.round(.{ .smallest_unit = Temporal.ZonedDateTime.Unit.hour });
    const zdt_eq = zdt.equals(zdt);
    const zdt_since = try zdt.since(zdt, Temporal.ZonedDateTime.DifferenceSettings{});
    const zdt_until = try zdt.until(zdt, Temporal.ZonedDateTime.DifferenceSettings{});
    const zdt_with_cal = try zdt.withCalendar("iso8601");
    const zdt_with_time = try zdt.withPlainTime(try Temporal.PlainTime.init(1, 2, 3, 4, 5, 6));
    const zdt_with_tz = try zdt.withTimeZone(tz);
    std.log.info(
        \\ZonedDateTime Advanced
        \\ - add duration: {s}
        \\ - subtract duration: {s}
        \\ - round to hour: {s}
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
        zdt_eq,
        try zdt_since.toString(allocator, .{}),
        try zdt_until.toString(allocator, .{}),
        try zdt_with_cal.toString(allocator, .{}),
        try zdt_with_time.toString(allocator, .{}),
        try zdt_with_tz.toString(allocator, .{}),
    });

    // ----
    // API coverage examples for the remaining public methods
    // ----

    const dur_init = try Temporal.Duration.init(0, 1, 0, 2, 3, 4, 5, 6, 7, 8);
    const dur_from_partial = try Temporal.Duration.from(Temporal.Duration.PartialDuration{ .minutes = 90 });
    const dur_compare = try dur.compare(dur2, .{});
    const dur_locale_supported = dur.toLocaleString(allocator) != error.TemporalNotImplemented;
    std.log.info(
        \\Duration Coverage
        \\ - init: {s}
        \\ - from partial: {s}
        \\ - compare(dur, dur2): {}
        \\ - sign: {s}
        \\ - blank: {}
        \\ - microseconds: {d}
        \\ - toJSON(): {s}
        \\ - toLocaleString implemented: {}
        \\
        \\
    , .{
        try dur_init.toString(allocator, .{}),
        try dur_from_partial.toString(allocator, .{}),
        dur_compare,
        @tagName(dur.sign()),
        dur.blank(),
        dur.microseconds(),
        try dur.toJSON(allocator),
        dur_locale_supported,
    });

    const instant_from_ms = try Temporal.Instant.fromEpochMilliseconds(1_704_067_200_000);
    const instant_from_ns = try Temporal.Instant.fromEpochNanoseconds(1_704_067_200_000_000_000);
    const instant_from_str = try Temporal.Instant.from("2024-01-01T00:00:00Z");
    const instant_until = try inst1.until(inst2, Temporal.Instant.DifferenceSettings{});
    const instant_zdt = try inst1.toZonedDateTimeISO(try Temporal.Instant.TimeZone.init("UTC"));
    defer instant_zdt.deinit();
    std.log.info(
        \\Instant Coverage
        \\ - fromEpochMilliseconds: {s}
        \\ - fromEpochNanoseconds: {s}
        \\ - from string: {s}
        \\ - equals(from ms, from ns): {}
        \\ - until inst2: {s}
        \\ - toJSON(): {s}
        \\ - toLocaleString(): {s}
        \\ - toZonedDateTimeISO(): {s}
        \\
        \\
    , .{
        try instant_from_ms.toString(allocator, .{}),
        try instant_from_ns.toString(allocator, .{}),
        try instant_from_str.toString(allocator, .{}),
        Temporal.Instant.equals(instant_from_ms, instant_from_ns),
        try instant_until.toString(allocator, .{}),
        try inst1.toJSON(allocator),
        try inst1.toLocaleString(allocator),
        try instant_zdt.toString(allocator, .{}),
    });

    const now_zdt_supported = Temporal.Now.zonedDateTimeISO() != error.TemporalNotImplemented;
    std.log.info(
        \\Now Coverage
        \\ - timeZoneId(): {s}
        \\ - zonedDateTimeISO implemented: {}
        \\
        \\
    , .{
        Temporal.Now.timeZoneId(),
        now_zdt_supported,
    });

    const date_cal = try Temporal.PlainDate.calInit(2024, 2, 2, "iso8601");
    const date_from = try Temporal.PlainDate.from("2024-02-02");
    const date_md = try date.toPlainMonthDay();
    const date_ym = try date.toPlainYearMonth();
    const date_zdt = try date.toZonedDateTime(.{ .time_zone = "UTC", .plain_time = tm });
    const date_locale_supported = date.toLocaleString(allocator) != error.TemporalNotImplemented;
    const date_valueof_supported = date.valueOf() != error.TemporalValueOfNotSupported;
    const date_with_coverage = try date.with(.{ .year = 2025, .month = 3, .day = 4 });
    std.log.info(
        \\PlainDate Coverage
        \\ - calInit: {s}
        \\ - from string: {s}
        \\ - compare(date, from): {}
        \\ - calendarId: {s}
        \\ - dayOfWeek/dayOfYear: {}/{}
        \\ - daysInWeek/daysInMonth/daysInYear: {}/{}/{}
        \\ - monthCode/monthsInYear: {s}/{}
        \\ - inLeapYear: {}
        \\ - era/eraYear: {any}/{?}
        \\ - weekOfYear/yearOfWeek: {?}/{?}
        \\ - toPlainMonthDay: {s}
        \\ - toPlainYearMonth: {s}
        \\ - toZonedDateTime: {s}
        \\ - toJSON(): {s}
        \\ - toLocaleString implemented: {}
        \\ - valueOf supported: {}
        \\ - with year/month/day: {s}
        \\
        \\
    , .{
        try date_cal.toString(allocator, .{}),
        try date_from.toString(allocator, .{}),
        Temporal.PlainDate.compare(date, date_from),
        try date.calendarId(allocator),
        date.dayOfWeek(),
        date.dayOfYear(),
        date.daysInWeek(),
        date.daysInMonth(),
        date.daysInYear(),
        try date.monthCode(allocator),
        date.monthsInYear(),
        date.inLeapYear(),
        try date.era(allocator),
        date.eraYear(),
        date.weekOfYear(),
        date.yearOfWeek(),
        try date_md.toString(allocator),
        try date_ym.toString(allocator),
        try date_zdt.toString(allocator, .{}),
        try date.toJSON(allocator),
        date_locale_supported,
        date_valueof_supported,
        try date_with_coverage.toString(allocator, .{}),
    });

    const dt_cal = try Temporal.PlainDateTime.calInit(2024, 2, 2, 13, 45, 30, 123, 456, 789, "iso8601");
    const dt_from = try Temporal.PlainDateTime.from("2024-02-02T13:45:30.123456789", .{});
    const dt_plain_time = try dt.toPlainTime();
    const dt_zdt = try dt.toZonedDateTime(.{ .timeZone = "UTC" });
    const dt_valueof_supported = dt.valueOf() != error.ComparisonNotSupported;
    std.log.info(
        \\PlainDateTime Coverage
        \\ - calInit: {s}
        \\ - from string: {s}
        \\ - compare(dt, from): {}
        \\ - calendarId: {s}
        \\ - dayOfWeek/dayOfYear: {}/{}
        \\ - daysInWeek/daysInMonth/daysInYear: {}/{}/{}
        \\ - monthCode/monthsInYear: {s}/{}
        \\ - inLeapYear: {}
        \\ - era/eraYear: {any}/{?}
        \\ - weekOfYear/yearOfWeek: {?}/{?}
        \\ - millisecond/microsecond/nanosecond: {}/{}/{}
        \\ - toPlainTime: {s}
        \\ - toZonedDateTime: {s}
        \\ - toJSON(): {s}
        \\ - toLocaleString(): {s}
        \\ - valueOf supported: {}
        \\
        \\
    , .{
        try dt_cal.toString(allocator, .{}),
        try dt_from.toString(allocator, .{}),
        Temporal.PlainDateTime.compare(dt, dt_from),
        try dt.calendarId(allocator),
        dt.dayOfWeek(),
        dt.dayOfYear(),
        dt.daysInWeek(),
        dt.daysInMonth(),
        dt.daysInYear(),
        try dt.monthCode(allocator),
        dt.monthsInYear(),
        dt.inLeapYear(),
        try dt.era(allocator),
        try dt.eraYear(),
        try dt.weekOfYear(),
        try dt.yearOfWeek(),
        dt.millisecond(),
        dt.microsecond(),
        dt.nanosecond(),
        try dt_plain_time.toString(allocator),
        try dt_zdt.toString(allocator, .{}),
        try dt.toJSON(allocator),
        dt.toLocaleString(allocator),
        dt_valueof_supported,
    });

    const md_from = try Temporal.PlainMonthDay.from("02-02");
    const md_with = try md.with(.{ .day = 3 });
    const md_date = try md.toPlainDate(2024);
    const md_valueof_supported = md.valueOf() != error.ValueError;
    std.log.info(
        \\PlainMonthDay Coverage
        \\ - from string: {s}
        \\ - equals(from): {}
        \\ - calendarId: {s}
        \\ - with day=3: {s}
        \\ - toPlainDate(2024): {s}
        \\ - toJSON(): {s}
        \\ - toLocaleString(): {s}
        \\ - valueOf supported: {}
        \\
        \\
    , .{
        try md_from.toString(allocator),
        md.equals(md_from),
        try md.calendarId(allocator),
        try md_with.toString(allocator),
        try md_date.toString(allocator, .{}),
        try md.toJSON(allocator),
        try md.toLocaleString(allocator),
        md_valueof_supported,
    });

    const tm_from = try Temporal.PlainTime.from("13:45:30.123456789");
    const tm_valueof_supported = tm.valueOf() != error.ValueError;
    std.log.info(
        \\PlainTime Coverage
        \\ - from string: {s}
        \\ - compare(tm, from): {}
        \\ - millisecond/microsecond/nanosecond: {}/{}/{}
        \\ - toJSON(): {s}
        \\ - toLocaleString(): {s}
        \\ - valueOf supported: {}
        \\
        \\
    , .{
        try tm_from.toString(allocator),
        Temporal.PlainTime.compare(tm, tm_from),
        tm.millisecond(),
        tm.microsecond(),
        tm.nanosecond(),
        try tm.toJSON(allocator),
        try tm.toLocaleString(allocator),
        tm_valueof_supported,
    });

    const ym_from = try Temporal.PlainYearMonth.from("2024-02");
    const ym_date = try ym.toPlainDate(2);
    const ym_valueof_supported = ym.valueOf() != error.ValueError;
    std.log.info(
        \\PlainYearMonth Coverage
        \\ - from string: {s}
        \\ - compare(ym, from): {}
        \\ - calendarId: {s}
        \\ - monthCode: {s}
        \\ - daysInMonth/daysInYear/monthsInYear: {}/{}/{}
        \\ - inLeapYear: {}
        \\ - era/eraYear: {any}/{?}
        \\ - toPlainDate(2): {s}
        \\ - toJSON(): {s}
        \\ - toLocaleString(): {s}
        \\ - valueOf supported: {}
        \\
        \\
    , .{
        try ym_from.toString(allocator),
        Temporal.PlainYearMonth.compare(ym, ym_from),
        try ym.calendarId(allocator),
        try ym.monthCode(allocator),
        ym.daysInMonth(),
        ym.daysInYear(),
        ym.monthsInYear(),
        ym.inLeapYear(),
        try ym.era(allocator),
        ym.eraYear(),
        try ym_date.toString(allocator, .{}),
        try ym.toJSON(allocator),
        try ym.toLocaleString(allocator),
        ym_valueof_supported,
    });

    const zdt_init = try Temporal.ZonedDateTime.init(zdt_epoch_ns, tz);
    const zdt_from_ms = try Temporal.ZonedDateTime.fromEpochMilliseconds(1_706_881_530_123, tz);
    const zdt_from = try Temporal.ZonedDateTime.from("2024-02-02T13:45:30.123456789+00:00[UTC]", null, .compatible, .reject);
    const zdt_transition_next = try zdt.getTimeZoneTransition(.next);
    const zdt_transition_previous = try zdt.getTimeZoneTransition(.previous);
    const zdt_day_start = try zdt.startOfDay();
    const zdt_plain_date = try zdt.toPlainDate();
    const zdt_plain_datetime = try zdt.toPlainDateTime();
    const zdt_plain_time = try zdt.toPlainTime();
    const zdt_valueof_supported = zdt.valueOf() != error.ValueOfNotSupported;
    const zdt_with_supported = zdt.with(allocator, .{ .year = 2025 }) != error.TemporalNoteImplemented;
    std.log.info(
        \\ZonedDateTime Coverage
        \\ - init: {s}
        \\ - fromEpochMilliseconds: {s}
        \\ - from string: {s}
        \\ - compare(zdt, from): {}
        \\ - next/previous transition exists: {}/{}
        \\ - startOfDay: {s}
        \\ - toJSON(): {s}
        \\ - toLocaleString(): {s}
        \\ - toPlainDate: {s}
        \\ - toPlainDateTime: {s}
        \\ - toPlainTime: {s}
        \\ - calendarId: {s}
        \\ - dayOfWeek/dayOfYear: {}/{}
        \\ - daysInWeek/daysInMonth/daysInYear: {}/{}/{}
        \\ - epochMilliseconds/epochNanoseconds: {}/{}
        \\
    , .{
        try zdt_init.toString(allocator, .{}),
        try zdt_from_ms.toString(allocator, .{}),
        try zdt_from.toString(allocator, .{}),
        Temporal.ZonedDateTime.compare(zdt, zdt_from),
        zdt_transition_next != null,
        zdt_transition_previous != null,
        try zdt_day_start.toString(allocator, .{}),
        try zdt.toJSON(allocator),
        try zdt.toLocaleString(allocator),
        try zdt_plain_date.toString(allocator, .{}),
        try zdt_plain_datetime.toString(allocator, .{}),
        try zdt_plain_time.toString(allocator),
        try zdt.calendarId(allocator),
        zdt.dayOfWeek(),
        zdt.dayOfYear(),
        zdt.daysInWeek(),
        zdt.daysInMonth(),
        zdt.daysInYear(),
        zdt.epochMilliseconds(),
        zdt.epochNanoseconds(),
    });
    std.log.info(
        \\ZonedDateTime Coverage Continued
        \\ - era/eraYear: {any}/{?}
        \\ - hoursInDay/inLeapYear: {d}/{}
        \\ - millisecond/microsecond/nanosecond: {}/{}/{}
        \\ - monthCode/monthsInYear: {s}/{}
        \\ - offset/offsetNanoseconds: {s}/{}
        \\ - weekOfYear/yearOfWeek: {?}/{?}
        \\ - valueOf supported: {}
        \\ - with implemented: {}
        \\
        \\
    , .{
        try zdt.era(allocator),
        zdt.eraYear(),
        try zdt.hoursInDay(),
        zdt.inLeapYear(),
        zdt.millisecond(),
        zdt.microsecond(),
        zdt.nanosecond(),
        try zdt.monthCode(allocator),
        zdt.monthsInYear(),
        try zdt.offset(allocator),
        zdt.offsetNanoseconds(),
        zdt.weekOfYear(),
        zdt.yearOfWeek(),
        zdt_valueof_supported,
        zdt_with_supported,
    });
}

extern fn consoleLog(ptr: [*]u8, len: u32) void;
pub fn logFn(comptime message_level: std.log.Level, comptime scope: @TypeOf(.enum_literal), comptime format: []const u8, args: anytype) void {
    if (builtin.os.tag == .freestanding) {
        const prefix = if (scope == .default) "" else "(" ++ @tagName(scope) ++ ") ";
        const formatted = std.fmt.allocPrint(std.heap.wasm_allocator, prefix ++ format, args) catch return;
        consoleLog(formatted.ptr, formatted.len);
    }

    std.log.defaultLog(message_level, scope, format, args);
}

pub const std_options: std.Options = .{
    .logFn = logFn,
};
