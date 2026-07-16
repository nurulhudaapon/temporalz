const std = @import("std");
const program = @import("root.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    try program.run(allocator, io);
}
