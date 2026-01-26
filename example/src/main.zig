const std = @import("std");
const Temporal = @import("temporalz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try Temporal.Instant.init(1_704_067_200_000_000_000); // 2024-01-01 00:00:00 UTC
    defer result.deinit();

    std.debug.print("Instant.epoch_milliseconds: {}\n", .{result.epoch_milliseconds});
    std.debug.print("Instant.epoch_nanoseconds: {}\n", .{result.epoch_nanoseconds});
    const instant_str = try result.toString(allocator, .{});
    std.debug.print("Instant.toString(): {s}\n", .{instant_str});

    const dur = try Temporal.Duration.from("P1Y2M3DT4H5M6S");
    defer dur.deinit();
}
