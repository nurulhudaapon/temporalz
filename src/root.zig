const std = @import("std");
pub const Instant = @import("Instant.zig");

test "Instant.methods" {
    const instant = @import("Instant.zig");

    const checks = .{
        .{ .name = "add", .expect = true },
        .{ .name = "equals", .expect = true },
        .{ .name = "round", .expect = true },
        .{ .name = "since", .expect = true },
        .{ .name = "subtract", .expect = true },
        .{ .name = "toString", .expect = true },
        .{ .name = "toZonedDateTimeIso", .expect = true },
        .{ .name = "until", .expect = true },

        // Not yet implemented aliases from the Temporal JS API.
        .{ .name = "toJSON", .expect = false },
        .{ .name = "toLocaleString", .expect = false },
        .{ .name = "valueOf", .expect = false },
        .{ .name = "toZonedDateTimeISO", .expect = false }, // different casing
    };

    inline for (checks) |check| {
        const has = @hasDecl(instant, check.name);
        if (check.expect)
            try std.testing.expect(has)
        else
            try std.testing.expect(!has);
    }
}
