pub const Duration = @import("Duration.zig");
pub const Instant = @import("Instant.zig");
pub const Now = @import("Now.zig");
pub const PlainDate = @import("PlainDate.zig");
pub const PlainDateTime = @import("PlainDateTime.zig");
pub const PlainMonthDay = @import("PlainMonthDay.zig");
pub const PlainTime = @import("PlainTime.zig");
pub const PlainYearMonth = @import("PlainYearMonth.zig");
pub const ZonedDateTime = @import("ZonedDateTime.zig");

const Temporal = @This();

fn assertDecls(comptime T: type, checks: anytype) !void {
    const std = @import("std");
    inline for (checks) |check| {
        const has = @hasDecl(T, check);
        if (!std.mem.eql(u8, check, "valueOf")) {
            if (!has) std.log.err("Missing {s} method: {s}", .{ @typeName(T), check });
            try std.testing.expect(has);
        }
    }
}

test "Temporal.Duration" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.Duration()
        // Static methods
        "compare",
        "from",

        // Instance methods
        "abs",
        "add",
        "negated",
        "round",
        "subtract",
        "toJSON",
        "toLocaleString",
        "toString",
        "total",
        "valueOf",
        "with",

        // Properties
        "blank",
        "days",
        "hours",
        "microseconds",
        "milliseconds",
        "minutes",
        "months",
        "nanoseconds",
        "seconds",
        "sign",
        "weeks",
        "years",
    };

    try assertDecls(Duration, checks);
}

test "Temporal.Instant" {
    const checks = .{
        // Constructor
        "init", // Temporal.Instant()

        // Static methods
        "compare",
        "from",
        "fromEpochMilliseconds",
        "fromEpochNanoseconds",

        // Instance methods
        "add",
        "equals",
        "round",
        "since",
        "subtract",
        "toJSON",
        "toLocaleString",
        "toString",
        "toZonedDateTimeISO", // Temporal.Instant.toZonedDateTimeISO
        "until",
        "valueOf",

        // Properties
        "epochMilliseconds",
        "epochNanoseconds",
    };

    try assertDecls(Instant, checks);
}

test "Temporal.Now" {
    if (true) return error.Todo;

    const checks = .{
        // Static methods
        "instant",
        "plainDateISO",
        "plainDateTimeISO",
        "plainTimeISO",
        "timeZoneId",
        "zonedDateTimeISO",
    };

    try assertDecls(Now, checks);
}

test "Temporal.PlainDate" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.PlainDate()

        // Static methods
        "compare",
        "from",

        // Instance methods
        "add",
        "equals",
        "since",
        "subtract",
        "toJSON",
        "toLocaleString",
        "toPlainDateTime",
        "toPlainMonthDay",
        "toPlainYearMonth",
        "toString",
        "toZonedDateTime",
        "until",
        "valueOf",
        "with",
        "withCalendar",

        // Properties
        "calendarId",
        "day",
        "dayOfWeek",
        "dayOfYear",
        "daysInMonth",
        "daysInWeek",
        "daysInYear",
        "era",
        "eraYear",
        "inLeapYear",
        "month",
        "monthCode",
        "monthsInYear",
        "weekOfYear",
        "year",
        "yearOfWeek",
    };

    try assertDecls(PlainDate, checks);
}

test "Temporal.PlainDateTime" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.PlainDateTime()

        // Static methods
        "compare",
        "from",

        // Instance methods
        "add",
        "equals",
        "round",
        "since",
        "subtract",
        "toJSON",
        "toLocaleString",
        "toPlainDate",
        "toPlainTime",
        "toString",
        "toZonedDateTime",
        "until",
        "valueOf",
        "with",
        "withCalendar",
        "withPlainTime",

        // Properties
        "calendarId",
        "day",
        "dayOfWeek",
        "dayOfYear",
        "daysInMonth",
        "daysInWeek",
        "daysInYear",
        "era",
        "eraYear",
        "hour",
        "inLeapYear",
        "microsecond",
        "millisecond",
        "minute",
        "month",
        "monthCode",
        "monthsInYear",
        "nanosecond",
        "second",
        "weekOfYear",
        "year",
        "yearOfWeek",
    };

    try assertDecls(PlainDateTime, checks);
}

test "Temporal.PlainMonthDay" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.PlainMonthDay()

        // Static methods
        "from",

        // Instance methods
        "equals",
        "toJSON",
        "toLocaleString",
        "toPlainDate",
        "toString",
        "valueOf",
        "with",

        // Properties
        "calendarId",
        "day",
        "monthCode",
    };

    try assertDecls(PlainMonthDay, checks);
}

test "Temporal.PlainTime" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.PlainTime()

        // Static methods
        "compare",
        "from",

        // Instance methods
        "add",
        "equals",
        "round",
        "since",
        "subtract",
        "toJSON",
        "toLocaleString",
        "toString",
        "until",
        "valueOf",
        "with",

        // Properties
        "hour",
        "microsecond",
        "millisecond",
        "minute",
        "nanosecond",
        "second",
    };

    try assertDecls(PlainTime, checks);
}

test "Temporal.PlainYearMonth" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.PlainYearMonth()

        // Static methods
        "compare",
        "from",

        // Instance methods
        "add",
        "equals",
        "since",
        "subtract",
        "toJSON",
        "toLocaleString",
        "toPlainDate",
        "toString",
        "until",
        "valueOf",
        "with",

        // Properties
        "calendarId",
        "daysInMonth",
        "daysInYear",
        "era",
        "eraYear",
        "inLeapYear",
        "month",
        "monthCode",
        "monthsInYear",
        "year",
    };

    try assertDecls(PlainYearMonth, checks);
}

test "Temporal.ZonedDateTime" {
    if (true) return error.Todo;

    const checks = .{
        // Constructor
        "init", // Temporal.ZonedDateTime()

        // Static methods
        "compare",
        "from",

        // Instance methods
        "add",
        "equals",
        "getTimeZoneTransition",
        "round",
        "since",
        "startOfDay",
        "subtract",
        "toInstant",
        "toJSON",
        "toLocaleString",
        "toPlainDate",
        "toPlainDateTime",
        "toPlainTime",
        "toString",
        "until",
        "valueOf",
        "with",
        "withCalendar",
        "withPlainTime",
        "withTimeZone",

        // Properties
        "calendarId",
        "day",
        "dayOfWeek",
        "dayOfYear",
        "daysInMonth",
        "daysInWeek",
        "daysInYear",
        "epochMilliseconds",
        "epochNanoseconds",
        "era",
        "eraYear",
        "hour",
        "hoursInDay",
        "inLeapYear",
        "microsecond",
        "millisecond",
        "minute",
        "month",
        "monthCode",
        "monthsInYear",
        "nanosecond",
        "offset",
        "offsetNanoseconds",
        "second",
        "timeZoneId",
        "weekOfYear",
        "year",
        "yearOfWeek",
    };

    try assertDecls(ZonedDateTime, checks);
}

test "Temporal" {
    const std = @import("std");

    const expected_scopes = .{
        "Duration",
        "Instant",
        "Now",
        "PlainDate",
        "PlainDateTime",
        "PlainMonthDay",
        "PlainTime",
        "PlainYearMonth",
        "ZonedDateTime",
    };

    inline for (expected_scopes) |scope| {
        const has = @hasDecl(Temporal, scope);
        if (!has) std.log.err("Missing Temporal scope: {s}", .{scope});
        try std.testing.expect(has);
    }
}
