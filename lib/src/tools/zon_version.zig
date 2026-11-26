//! Adds a `.version` to a dependency in build.zig.zon and rewrites its hash
//! to the versioned form `<name>-<version>-<digest>`.
//!
//! `zig fetch --save` has no way to set a version, so it always writes the
//! unversioned `N-V-<digest>` hash. Zig, however, expects the hash of a package
//! without its own manifest to carry the `.version` declared for it.
//!
//! Usage: zon_version <build.zig.zon> <dep name> <version>

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 4) {
        std.log.err("usage: {s} <build.zig.zon> <dep name> <version>", .{args[0]});
        return error.InvalidArgs;
    }
    const zon_path = args[1];
    const name = args[2];
    const version = args[3];

    const cwd = std.Io.Dir.cwd();
    const src = try cwd.readFileAlloc(io, zon_path, arena, .limited(16 * 1024 * 1024));
    const out = try setVersion(arena, src, name, version);
    try cwd.writeFile(io, .{ .sub_path = zon_path, .data = out });
}

/// Length of the base64url-encoded digest at the end of a package hash.
const digest_len = 44;

fn setVersion(gpa: std.mem.Allocator, src: []const u8, name: []const u8, version: []const u8) ![]const u8 {
    // Locate the dependency's `.{ ... }` block.
    const key = try std.fmt.allocPrint(gpa, ".@\"{s}\" = .{{", .{name});
    const key_plain = try std.fmt.allocPrint(gpa, ".{s} = .{{", .{name});
    const key_start = std.mem.indexOf(u8, src, key) orelse
        std.mem.indexOf(u8, src, key_plain) orelse return error.DependencyNotFound;
    const block_start = std.mem.indexOfScalarPos(u8, src, key_start, '{').? + 1;
    const block_end = std.mem.indexOfPos(u8, src, block_start, "}") orelse return error.MalformedZon;
    const block = src[block_start..block_end];

    var out: std.ArrayList(u8) = .empty;
    try out.appendSlice(gpa, src[0..block_start]);

    // Rebuild the block line by line: drop any `.version`, rewrite `.hash`
    // and put `.version` right after it.
    var found_hash = false;
    var lines = std.mem.splitScalar(u8, block, '\n');
    var first = true;
    while (lines.next()) |line| {
        const trimmed = std.mem.trimStart(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, ".version = ")) continue;
        if (!first) try out.append(gpa, '\n');
        first = false;

        const hash_key = ".hash = \"";
        if (!std.mem.startsWith(u8, trimmed, hash_key)) {
            try out.appendSlice(gpa, line);
            continue;
        }
        found_hash = true;
        const indent = line[0 .. line.len - trimmed.len];
        const old_hash = trimmed[hash_key.len .. std.mem.indexOfScalarPos(u8, trimmed, hash_key.len, '"') orelse
            return error.MalformedZon];
        // The digest is a fixed-length base64url string (it may contain `-`).
        if (old_hash.len < digest_len) return error.MalformedHash;
        const digest = old_hash[old_hash.len - digest_len ..];
        try out.print(gpa, "{s}.hash = \"{s}-{s}-{s}\",\n{s}.version = \"{s}\",", .{
            indent, name, version, digest, indent, version,
        });
    }
    if (!found_hash) return error.HashNotFound;

    try out.appendSlice(gpa, src[block_end..]);
    return out.items;
}

test setVersion {
    const gpa = std.testing.allocator;
    var arena: std.heap.ArenaAllocator = .init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    const src =
        \\.{
        \\    .dependencies = .{
        \\        .@"x86_64-netbsd" = .{
        \\            .url = "https://example.com/x.tar.gz",
        \\            .version = "0.2.3",
        \\            .hash = "N-V-__8AAEKptADVBZFKw7ZKvLurwzp_WA-FD-OwZFgEMf4q",
        \\            .lazy = true,
        \\        },
        \\        .other = .{
        \\            .url = "https://example.com/y.tar.gz",
        \\            .hash = "N-V-__8AACjsTwB3jX1mva0svtTn39kCz5aabikQbczLJlp9",
        \\        },
        \\    },
        \\}
    ;
    const expected =
        \\.{
        \\    .dependencies = .{
        \\        .@"x86_64-netbsd" = .{
        \\            .url = "https://example.com/x.tar.gz",
        \\            .hash = "x86_64-netbsd-0.2.4-__8AAEKptADVBZFKw7ZKvLurwzp_WA-FD-OwZFgEMf4q",
        \\            .version = "0.2.4",
        \\            .lazy = true,
        \\        },
        \\        .other = .{
        \\            .url = "https://example.com/y.tar.gz",
        \\            .hash = "N-V-__8AACjsTwB3jX1mva0svtTn39kCz5aabikQbczLJlp9",
        \\        },
        \\    },
        \\}
    ;
    const once = try setVersion(a, src, "x86_64-netbsd", "0.2.4");
    try std.testing.expectEqualStrings(expected, once);
    // Idempotent.
    try std.testing.expectEqualStrings(expected, try setVersion(a, once, "x86_64-netbsd", "0.2.4"));
}
