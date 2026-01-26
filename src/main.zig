const std = @import("std");
const Temporal = @import("temporalz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // --- Instant --- //
    const instant = try Temporal.Instant.init(1_704_067_200_000_000_000); // 2024-01-01 00:00:00 UTC
    defer instant.deinit();

    std.debug.print(
        \\Instant
        \\
        \\ - milliseconds: {}
        \\ - nanoseconds: {}
        \\ - toString(): {s}
        \\
        \\
    , .{
        instant.epoch_milliseconds,
        instant.epoch_nanoseconds,
        try instant.toString(allocator, .{}),
    });

    // --- Duration --- //
    const dur = try Temporal.Duration.from("P1Y2M3DT4H5M6S");
    defer dur.deinit();

    std.debug.print(
        \\Duration
        \\
        \\ - nanoseconds: {}
        \\ - miliseconds: {}
        \\ - seconds: {}
        \\ - minutes: {}
        \\ - hours: {}
        \\ - days: {}
        \\ - weeks: {}
        \\ - months: {}
        \\ - years: {}
        \\ - toString(): {s}
        \\ - total(): {{}}
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
        // try dur.total(.{ .unit = .minute }),
    });
}
