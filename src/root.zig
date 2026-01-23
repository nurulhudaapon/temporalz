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

test "Duration.methods" {
    if (true) return error.Todo;
    const std = @import("std");

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

    inline for (checks) |check| {
        const has = @hasDecl(Duration, check);
        if (!has) std.log.err("Missing Duration method: {s}", .{check});
        try std.testing.expect(has);
    }
}

test "Instant.methods" {
    const std = @import("std");

    const checks = .{
        // Constructor
        "init", // Temporal.Instant()

        // Instance methods
        "add",
        "equals",
        "round",
        "since",
        "subtract",
        "toString",
        "toZonedDateTimeIso", // Temporal.Instant.toZonedDateTimeISO
        "until",

        // Not yet implemented aliases from the Temporal JS API.
        // "toJSON",
        // "toLocaleString",
        // "valueOf",
    };

    inline for (checks) |check| {
        const has = @hasDecl(Instant, check);
        if (!has) std.log.err("Missing Instant method: {s}", .{check});
        try std.testing.expect(has);
    }
}

test "Temporal.scopes" {
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
