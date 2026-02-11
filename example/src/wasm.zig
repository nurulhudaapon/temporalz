const std = @import("std");
const program = @import("root.zig");

export fn _start() void {
    const allocator = std.heap.wasm_allocator;
    program.run(allocator, null) catch {};
}

extern fn console(ptr: [*]u8, len: u32) void;

fn logFn(comptime _: anytype, comptime _: anytype, comptime format: []const u8, args: anytype) void {
    const formatted = std.fmt.allocPrint(std.heap.wasm_allocator, format, args) catch return;
    console(formatted.ptr, formatted.len);
}

pub const std_options: std.Options = .{ .logFn = logFn };
