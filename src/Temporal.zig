const std = @import("std");
const abi = @import("abi.zig");

/// The `Temporal` namespace contains date and time related objects and functions, providing a modern alternative to the existing `Date` object in JavaScript.
const Temporal = @This();

/// The `Temporal.Duration` object represents a difference between two time points, which can be used in date/time arithmetic.
/// It is fundamentally represented as a combination of years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, and nanoseconds values.
///
/// See: [Temporal.Duration](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration)
pub const Duration = @import("Duration.zig");

/// The `Temporal.Instant` object represents a unique point in time, with nanosecond precision.
/// It is fundamentally represented as the number of nanoseconds since the Unix epoch (midnight at the beginning of January 1, 1970, UTC), without any time zone or calendar system.
///
/// See: [Temporal.Instant](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Instant)
pub const Instant = @import("Instant.zig");

/// The `Temporal.Now` namespace object contains static methods for getting the current time in various formats.
/// All properties and methods are static.
///
/// See: [Temporal.Now](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Now)
pub const Now = @import("Now.zig");

/// The `Temporal.PlainDate` object represents a calendar date (year, month, day) with no time or time zone.
///
/// See: [Temporal.PlainDate](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDate)
pub const PlainDate = @import("PlainDate.zig");

/// The `Temporal.PlainDateTime` object represents a calendar date and wall-clock time, but no time zone or offset.
///
/// See: [Temporal.PlainDateTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDateTime)
pub const PlainDateTime = @import("PlainDateTime.zig");

/// The `Temporal.PlainMonthDay` object represents a month and day in a calendar, with no year or time.
///
/// See: [Temporal.PlainMonthDay](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainMonthDay)
pub const PlainMonthDay = @import("PlainMonthDay.zig");

/// The `Temporal.PlainTime` object represents a wall-clock time, with no date or time zone.
///
/// See: [Temporal.PlainTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime)
pub const PlainTime = @import("PlainTime.zig");

/// The `Temporal.PlainYearMonth` object represents a particular month in a specific year, with no day or time.
///
/// See: [Temporal.PlainYearMonth](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainYearMonth)
pub const PlainYearMonth = @import("PlainYearMonth.zig");

/// The `Temporal.ZonedDateTime` object represents an exact time, including a time zone and calendar.
///
/// See: [Temporal.ZonedDateTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime)
pub const ZonedDateTime = @import("ZonedDateTime.zig");

/// Time unit for Temporal operations (e.g., nanosecond, second, day, year).
pub const Unit = enum {
    auto,
    nanosecond,
    microsecond,
    millisecond,
    second,
    minute,
    hour,
    day,
    week,
    month,
    year,
};

/// ## RoundingMode
/// Rounding mode for Temporal operations.
/// See: https://tc39.es/ecma402/#table-sanctioned-single-unit-identifiers
pub const RoundingMode = enum {
    /// Round toward positive infinity
    ceil,
    /// Round toward negative infinity
    floor,
    /// Round away from zero
    expand,
    /// Round toward zero (truncate)
    trunc,
    /// Round half toward positive infinity
    half_ceil,
    /// Round half toward negative infinity
    half_floor,
    /// Round half away from zero
    half_expand,
    /// Round half toward zero
    half_trunc,
    /// Round half to even (banker's rounding)
    half_even,
};

/// ## Sign
/// Sign of a duration or time value.
pub const Sign = enum {
    positive,
    zero,
    negative,
};

/// ## RoundingOptions
/// Options for rounding operations (e.g., Instant.round, Duration.round).
///
/// - [MDN: Duration.round](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/round)
pub const RoundingOptions = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,
};

/// ## DifferenceSettings
/// Options for computing differences between instants.
///
/// - [MDN: Instant.until](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Instant/until)
pub const DifferenceSettings = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,
};

/// ## ToStringRoundingOptions
/// Options for Duration.toString() formatting.
///
/// - [MDN: Duration.toString](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toString)
pub const ToStringRoundingOptions = struct {
    fractional_second_digits: ?u8 = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
};

/// ## TimeZone
/// Time zone identifier for Temporal operations.
pub const TimeZone = struct {
    _inner: abi.c.TimeZone,

    /// Initialize a TimeZone from an identifier string (IANA or offset).
    pub fn init(id: []const u8) !TimeZone {
        const view = abi.toDiplomatStringView(id);
        const result = abi.c.temporal_rs_TimeZone_try_from_str(view);
        const time_zone = try abi.extractResult(result);
        return .{ ._inner = time_zone };
    }

    /// Initialize a TimeZone from an IANA identifier string.
    pub fn fromIdentifier(id: []const u8) !TimeZone {
        const view = abi.toDiplomatStringView(id);
        const result = abi.c.temporal_rs_TimeZone_try_from_identifier_str(view);
        const time_zone = try abi.extractResult(result);
        return .{ ._inner = time_zone };
    }

    /// Initialize a TimeZone from a UTC offset string (e.g. "+05:00").
    pub fn fromOffset(offset: []const u8) !TimeZone {
        const view = abi.toDiplomatStringView(offset);
        const result = abi.c.temporal_rs_TimeZone_try_from_offset_str(view);
        const time_zone = try abi.extractResult(result);
        return .{ ._inner = time_zone };
    }

    /// Returns the UTC time zone.
    pub fn utc() TimeZone {
        return .{ ._inner = abi.c.temporal_rs_TimeZone_utc() };
    }

    /// Returns the zero-offset (+00:00) time zone.
    pub fn zero() TimeZone {
        return .{ ._inner = abi.c.temporal_rs_TimeZone_zero() };
    }

    /// Returns the primary identifier for this time zone (e.g. links resolve to canonical IANA ids).
    pub fn primaryIdentifier(self: TimeZone) !TimeZone {
        const result = abi.c.temporal_rs_TimeZone_primary_identifier(self._inner);
        const time_zone = try abi.extractResult(result);
        return .{ ._inner = time_zone };
    }

    /// Returns the string identifier for this time zone.
    pub fn identifier(self: TimeZone, allocator: std.mem.Allocator) ![]u8 {
        var write = abi.DiplomatWrite.init(allocator);
        defer write.deinit();
        abi.c.temporal_rs_TimeZone_identifier(self._inner, &write.inner);
        return try write.toOwnedSlice();
    }
};

test Temporal {
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
        "fromEpochMilliseconds",
        "fromEpochNanoseconds",

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
        "WithOptions",
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
        "fromEpochMilliseconds",
        "fromEpochNanoseconds",
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
        "Disambiguation",
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
        "month",
        "monthCode",
        "referenceYear",

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
        "referenceDay",
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
        "WithOptions",
    };

    try assertDecls(ZonedDateTime, checks);
}

test TimeZone {
    const utc = TimeZone.utc();
    const zero = TimeZone.zero();
    const from_offset = try TimeZone.fromOffset("+05:00");
    const from_id = try TimeZone.fromIdentifier("UTC");
    const primary = try utc.primaryIdentifier();

    const utc_id = try utc.identifier(std.testing.allocator);
    defer std.testing.allocator.free(utc_id);
    const zero_id = try zero.identifier(std.testing.allocator);
    defer std.testing.allocator.free(zero_id);
    const offset_id = try from_offset.identifier(std.testing.allocator);
    defer std.testing.allocator.free(offset_id);
    const primary_id = try primary.identifier(std.testing.allocator);
    defer std.testing.allocator.free(primary_id);
    const from_id_str = try from_id.identifier(std.testing.allocator);
    defer std.testing.allocator.free(from_id_str);

    try std.testing.expect(utc_id.len > 0);
    try std.testing.expect(zero_id.len > 0);
    try std.testing.expect(offset_id.len > 0);
    try std.testing.expect(primary_id.len > 0);
    try std.testing.expect(from_id_str.len > 0);
}

fn assertDecls(comptime T: type, checks: anytype) !void {
    @setEvalBranchQuota(5000); // Increase branch quota for large check lists
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
                inline for (struct_info.field_names) |field_name| {
                    // Check both camelCase and snake_case
                    if (std.mem.eql(u8, field_name, check) or
                        std.mem.eql(u8, field_name, camelToSnakeCase(check)))
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
        inline for (struct_info.decl_names) |decl_name| {
            // Allow deinit as extraneous
            if (comptime std.mem.eql(u8, decl_name, "deinit")) continue;

            var found = false;
            inline for (checks) |check| {
                if (std.mem.eql(u8, decl_name, check)) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                std.log.err("Extraneous {s} decl: {s}", .{ @typeName(T), decl_name });
                try std.testing.expect(false);
            }
        }

        // Check fields (properties)
        inline for (struct_info.field_names) |field_name| {
            // Allow internal fields (starting with underscore)
            if (comptime std.mem.startsWith(u8, field_name, "_")) continue;

            var found = false;
            inline for (checks) |check| {
                if (std.mem.eql(u8, field_name, camelToSnakeCase(check))) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                std.log.err("Extraneous {s} field: {s}", .{ @typeName(T), field_name });
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
