const std = @import("std");
const Temporal = @import("temporalz");

pub fn main() !void {
    const result = try Temporal.Instant.init(1704067200000); // 2024-01-01 00:00:00 UTC
    defer result.deinit();

    std.debug.print("Instant with Epoch: {}ms\n", .{result.epoch});

    const cloned = result.clone();
    std.debug.print("Is Instant Equal: {}\n", .{cloned.equals(result)});

    const instant_str = try cloned.toString(std.heap.page_allocator, .{});
    std.debug.print("Cloned Instant String: {s}\n", .{instant_str});
}
