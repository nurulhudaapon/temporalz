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

test Temporal {
    const std = @import("std");
    _ = @import("abi.zig");

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

test Duration {
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
        // "with",

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

        // Public types
        "ToStringOptions",
        "PartialDuration",
        "RelativeTo",
        "Unit",
        "RoundingMode",
        "RoundingOptions",
        "ToStringRoundingOptions",
        "Sign",
        "TotalOptions",
        "CompareOptions",
    };

    try assertDecls(Duration, checks);
}

test Instant {
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
        "toZonedDateTimeISO",
        "until",
        "valueOf",

        // Properties
        "epochMilliseconds",
        "epochNanoseconds",

        // Public types
        "ToStringOptions",
        "TimeZone",
        "Unit",
        "RoundingMode",
        "Sign",
        "RoundingOptions",
        "DifferenceSettings",
    };

    try assertDecls(Instant, checks);
}

test Now {
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

test PlainDate {
    const checks = .{
        // Constructor
        "init",
        "calInit",

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

        // Properties (now as methods)
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

        // Public types
        "ToStringOptions",
        "CalendarDisplay",
        "ToZonedDateTimeOptions",
        "Unit",
        "RoundingMode",
        "Sign",
        "DifferenceSettings",
    };

    try assertDecls(PlainDate, checks);
}

test PlainDateTime {
    const checks = .{
        // Constructor
        "init", // Temporal.PlainDateTime()
        "calInit",

        // Static methods
        "compare",
        "from",
        // "fromUtf8",
        // "fromUtf16",

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

        // Public types
        "Unit",
        "RoundingMode",
        "Sign",
        "CalendarDisplay",
        "DifferenceSettings",
        "RoundOptions",
        "ToStringOptions",
        "ToZonedDateTimeOptions",
        "WithOptions",
    };

    try assertDecls(PlainDateTime, checks);
}

test PlainMonthDay {
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

        // Public types
        "CalendarDisplay",
        "ToStringOptions",
        "WithOptions",
    };

    try assertDecls(PlainMonthDay, checks);
}

test PlainTime {
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

        // Public types
        "Unit",
        "RoundingMode",
        "DifferenceSettings",
        "RoundOptions",
        "WithOptions",
    };

    try assertDecls(PlainTime, checks);
}

test PlainYearMonth {
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

        // Public types
        "Unit",
        "RoundingMode",
        "CalendarDisplay",
        "DifferenceSettings",
        "RoundOptions",
        "ToStringOptions",
        "WithOptions",
    };

    try assertDecls(PlainYearMonth, checks);
}

test ZonedDateTime {
    const checks = .{
        // Constructor
        "init", // Temporal.ZonedDateTime()

        // Static methods
        "compare",
        "from",
        "fromEpochMilliseconds",
        "fromEpochNanoseconds",

        // Instance methods
        "add",
        "clone",
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

        // Public types
        "Unit",
        "RoundingMode",
        "Sign",
        "DifferenceSettings",
        "RoundOptions",
        "TimeZone",
        "Disambiguation",
        "OffsetDisambiguation",
        "CalendarDisplay",
        "DisplayOffset",
        "DisplayTimeZone",
        "ToStringOptions",
    };

    try assertDecls(ZonedDateTime, checks);
}

fn assertDecls(comptime T: type, checks: anytype) !void {
    @setEvalBranchQuota(5000); // Increase branch quota for large check lists
    const std = @import("std");
    const typeInfo = @typeInfo(T);

    // Check: all items in checks exist (either as decls or as fields)
    inline for (checks) |check| {
        const should_ignore =
            std.mem.eql(u8, check, "deinit") or
            std.mem.eql(u8, check, "valueOf");

        if (!should_ignore) {
            const hasDecl = @hasDecl(T, check);

            // Also check if it's a field (property)
            var hasField = false;
            if (typeInfo == .@"struct") {
                const struct_info = typeInfo.@"struct";
                inline for (struct_info.fields) |field| {
                    // Check both camelCase and snake_case
                    if (std.mem.eql(u8, field.name, check) or
                        std.mem.eql(u8, field.name, camelToSnakeCase(check)))
                    {
                        hasField = true;
                        break;
                    }
                }
            }

            const has = hasDecl or hasField;
            if (!has) std.log.err("Missing {s} decl or field: {s}", .{ @typeName(T), check });
            try std.testing.expect(has);
        }
    }

    // Check: no extraneous declarations or fields beyond checks
    if (typeInfo == .@"struct") {
        const struct_info = typeInfo.@"struct";

        // Check declarations
        inline for (struct_info.decls) |decl| {
            // Allow deinit as extraneous
            if (comptime std.mem.eql(u8, decl.name, "deinit")) continue;

            var found = false;
            inline for (checks) |check| {
                if (std.mem.eql(u8, decl.name, check)) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                std.log.err("Extraneous {s} decl: {s}", .{ @typeName(T), decl.name });
                try std.testing.expect(false);
            }
        }

        // Check fields (properties)
        inline for (struct_info.fields) |field| {
            // Allow internal fields (starting with underscore)
            if (comptime std.mem.startsWith(u8, field.name, "_")) continue;

            var found = false;
            inline for (checks) |check| {
                if (std.mem.eql(u8, field.name, camelToSnakeCase(check))) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                std.log.err("Extraneous {s} field: {s}", .{ @typeName(T), field.name });
                try std.testing.expect(false);
            }
        }
    }
}

fn camelToSnakeCase(comptime input: []const u8) []const u8 {
    comptime var len: usize = undefined;
    comptime {
        var llen: usize = input.len;
        for (input, 0..) |c, i| {
            if (c >= 'A' and c <= 'Z' and i != 0) {
                llen += 1;
            }
        }
        len = llen;
    }

    comptime var result: [len]u8 = undefined;
    comptime var write_index: usize = 0;

    comptime {
        for (input, 0..) |c, i| {
            if (c >= 'A' and c <= 'Z') {
                if (i != 0) {
                    result[write_index] = '_';
                    write_index += 1;
                }
                result[write_index] = c + 32; // Convert to lowercase
            } else {
                result[write_index] = c;
            }
            write_index += 1;
        }
    }

    const final = result;
    return &final;
}
