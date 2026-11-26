const std = @import("std");
const wasi = std.os.wasi;
const Alignment = std.mem.Alignment;

const gpa = std.heap.wasm_allocator;

export var errno: c_int = 0;

fn setErrno(e: wasi.errno_t) void {
    errno = @backingInt(e);
}

export fn abort() noreturn {
    @trap();
}

const min_align: Alignment = .@"16";

const Header = extern struct {
    raw_len: usize,
    align_bytes: usize,
    size: usize,
};

comptime {
    std.debug.assert(@sizeOf(Header) <= min_align.toByteUnits());
}

fn header(ptr: [*]u8) *Header {
    return @ptrCast(@alignCast(ptr - @sizeOf(Header)));
}

fn allocAligned(size: usize, alignment: Alignment) ?[*]u8 {
    const a = alignment.max(min_align);
    const a_bytes = a.toByteUnits();
    const raw_len = std.math.add(usize, size, a_bytes) catch return null;
    const raw = gpa.rawAlloc(raw_len, a, @returnAddress()) orelse return null;
    const ptr = raw + a_bytes;
    header(ptr).* = .{ .raw_len = raw_len, .align_bytes = a_bytes, .size = size };
    return ptr;
}

fn freePtr(ptr: [*]u8) void {
    const h = header(ptr).*;
    const raw = ptr - h.align_bytes;
    gpa.rawFree(raw[0..h.raw_len], .fromByteUnits(h.align_bytes), @returnAddress());
}

export fn malloc(size: usize) ?*anyopaque {
    return allocAligned(size, min_align) orelse {
        setErrno(.NOMEM);
        return null;
    };
}

export fn calloc(count: usize, size: usize) ?*anyopaque {
    const total = std.math.mul(usize, count, size) catch {
        setErrno(.NOMEM);
        return null;
    };
    const ptr: [*]u8 = @ptrCast(malloc(total) orelse return null);
    @memset(ptr[0..total], 0);
    return ptr;
}

export fn free(ptr: ?*anyopaque) void {
    freePtr(@ptrCast(ptr orelse return));
}

export fn realloc(ptr: ?*anyopaque, size: usize) ?*anyopaque {
    const old: [*]u8 = @ptrCast(ptr orelse return malloc(size));
    const h = header(old).*;
    if (size <= h.size) {
        header(old).size = size;
        return old;
    }
    const new = allocAligned(size, .fromByteUnits(h.align_bytes)) orelse {
        setErrno(.NOMEM);
        return null;
    };
    @memcpy(new[0..h.size], old[0..h.size]);
    freePtr(old);
    return new;
}

export fn posix_memalign(memptr: *?*anyopaque, alignment: usize, size: usize) c_int {
    if (alignment == 0 or !std.math.isPowerOfTwo(alignment) or alignment % @sizeOf(usize) != 0)
        return @backingInt(wasi.errno_t.INVAL);
    memptr.* = allocAligned(size, .fromByteUnits(alignment)) orelse
        return @backingInt(wasi.errno_t.NOMEM);
    return 0;
}

// --- I/O --- //
export fn write(fd: c_int, buf: [*]const u8, count: usize) isize {
    const iov = [_]wasi.ciovec_t{.{ .base = buf, .len = count }};
    return writev(fd, &iov, iov.len);
}

/// `struct iovec` has the same layout as WASI's `ciovec_t`.
export fn writev(fd: c_int, iov: [*]const wasi.ciovec_t, iovcnt: c_int) isize {
    if (iovcnt < 0) {
        setErrno(.INVAL);
        return -1;
    }
    var written: usize = 0;
    switch (wasi.fd_write(fd, iov, @intCast(iovcnt), &written)) {
        .SUCCESS => return @intCast(written),
        else => |e| {
            setErrno(e);
            return -1;
        },
    }
}

// --- Environment --- //
var environ: ?[][*:0]u8 = null;

fn loadEnviron() ?[][*:0]u8 {
    if (environ) |env| return env;
    var count: usize = 0;
    var buf_size: usize = 0;
    if (wasi.environ_sizes_get(&count, &buf_size) != .SUCCESS) return null;
    const ptrs = gpa.alloc([*:0]u8, count) catch return null;
    const buf = gpa.alloc(u8, buf_size) catch {
        gpa.free(ptrs);
        return null;
    };
    if (wasi.environ_get(ptrs.ptr, buf.ptr) != .SUCCESS) {
        gpa.free(ptrs);
        gpa.free(buf);
        return null;
    }
    environ = ptrs;
    return ptrs;
}

export fn getenv(name: [*:0]const u8) ?[*:0]u8 {
    const key = std.mem.span(name);
    for (loadEnviron() orelse return null) |entry| {
        const pair = std.mem.span(entry);
        if (pair.len > key.len and pair[key.len] == '=' and std.mem.eql(u8, pair[0..key.len], key))
            return entry + key.len + 1;
    }
    return null;
}

/// WASI preview1 has no current working directory.
export fn getcwd(buf: ?[*]u8, size: usize) ?[*]u8 {
    _ = buf;
    _ = size;
    setErrno(.NOSYS);
    return null;
}
