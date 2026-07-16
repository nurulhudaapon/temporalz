const std = @import("std");
const builtin = @import("builtin");
const program = @import("root.zig");

const freestanding = builtin.os.tag == .freestanding;

pub fn main(init: Init) !void {
    const allocator = std.heap.page_allocator;
    const io = if (freestanding) null else init.io;

    try program.run(allocator, io);
}

// -- //
const Init = if (freestanding) std.process.Init.Minimal else std.process.Init;
pub const std_options: std.Options = .{
    .logFn = if (freestanding) logFn else std.log.defaultLog,
};

extern fn console(ptr: [*]u8, len: u32) void;
fn logFn(comptime _: anytype, comptime _: anytype, comptime format: []const u8, args: anytype) void {
    const formatted = std.fmt.allocPrint(std.heap.wasm_allocator, format, args) catch return;
    console(formatted.ptr, formatted.len);
}
