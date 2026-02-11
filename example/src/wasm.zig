const std = @import("std");
const program = @import("root.zig");
const Temporal = @import("temporalz");

export fn _start() void {
    const allocator = std.heap.wasm_allocator;
    program.run(allocator, null) catch {};
}

const wasm_allocator = std.heap.wasm_allocator;
const PolyfillError = error{InvalidHandle};

var instants_init = false;
var durations_init = false;
var instants: std.ArrayList(?Temporal.Instant) = .empty;
var durations: std.ArrayList(?Temporal.Duration) = .empty;
var plain_dates_init = false;
var plain_dates: std.ArrayList(?Temporal.PlainDate) = .empty;

var last_error: ?[]u8 = null;

fn ensureInstants() void {
    if (!instants_init) {
        instants = .empty;
        instants_init = true;
    }
}

fn ensureDurations() void {
    if (!durations_init) {
        durations = .empty;
        durations_init = true;
    }
}

fn ensurePlainDates() void {
    if (!plain_dates_init) {
        plain_dates = .empty;
        plain_dates_init = true;
    }
}

fn addInstant(inst: Temporal.Instant) u32 {
    ensureInstants();
    instants.append(wasm_allocator, inst) catch return 0;
    return @intCast(instants.items.len);
}

fn getInstant(handle: u32) !Temporal.Instant {
    ensureInstants();
    if (handle == 0 or handle > instants.items.len) return PolyfillError.InvalidHandle;
    return instants.items[handle - 1] orelse PolyfillError.InvalidHandle;
}

fn removeInstant(handle: u32) void {
    if (!instants_init or handle == 0 or handle > instants.items.len) return;
    if (instants.items[handle - 1]) |inst| {
        inst.deinit();
        instants.items[handle - 1] = null;
    }
}

fn addDuration(dur: Temporal.Duration) u32 {
    ensureDurations();
    durations.append(wasm_allocator, dur) catch return 0;
    return @intCast(durations.items.len);
}

fn getDuration(handle: u32) !Temporal.Duration {
    ensureDurations();
    if (handle == 0 or handle > durations.items.len) return PolyfillError.InvalidHandle;
    return durations.items[handle - 1] orelse PolyfillError.InvalidHandle;
}

fn removeDuration(handle: u32) void {
    if (!durations_init or handle == 0 or handle > durations.items.len) return;
    if (durations.items[handle - 1]) |dur| {
        dur.deinit();
        durations.items[handle - 1] = null;
    }
}

fn addPlainDate(date: Temporal.PlainDate) u32 {
    ensurePlainDates();
    plain_dates.append(wasm_allocator, date) catch return 0;
    return @intCast(plain_dates.items.len);
}

fn getPlainDate(handle: u32) !Temporal.PlainDate {
    ensurePlainDates();
    if (handle == 0 or handle > plain_dates.items.len) return PolyfillError.InvalidHandle;
    return plain_dates.items[handle - 1] orelse PolyfillError.InvalidHandle;
}

fn removePlainDate(handle: u32) void {
    if (!plain_dates_init or handle == 0 or handle > plain_dates.items.len) return;
    if (plain_dates.items[handle - 1]) |date| {
        date.deinit();
        plain_dates.items[handle - 1] = null;
    }
}

fn clearLastError() void {
    if (last_error) |msg| {
        wasm_allocator.free(msg);
        last_error = null;
    }
}

fn setLastError(err: anyerror) void {
    clearLastError();
    const msg = std.fmt.allocPrint(wasm_allocator, "{s}", .{@errorName(err)}) catch return;
    last_error = msg;
}

fn setLastErrorMessage(msg: []const u8) void {
    clearLastError();
    const owned = wasm_allocator.alloc(u8, msg.len) catch return;
    std.mem.copyForwards(u8, owned, msg);
    last_error = owned;
}

fn packPtrLen(ptr: [*]u8, len: usize) u64 {
    const ptr_u32: u32 = @intCast(@intFromPtr(ptr));
    const len_u32: u32 = @intCast(len);
    return (@as(u64, ptr_u32) << 32) | @as(u64, len_u32);
}

fn unpackI128Hi(value: i128) i64 {
    const bits: u128 = @bitCast(value);
    const hi_bits: u64 = @intCast(bits >> 64);
    return @bitCast(hi_bits);
}

fn unpackI128Lo(value: i128) u64 {
    const bits: u128 = @bitCast(value);
    return @intCast(bits & 0xFFFFFFFFFFFFFFFF);
}

fn joinI128(hi: i64, lo: u64) i128 {
    const hi_bits: u64 = @bitCast(hi);
    const value: u128 = (@as(u128, hi_bits) << 64) | @as(u128, lo);
    return @bitCast(value);
}

fn unitFromCode(code: u8) ?Temporal.Duration.Unit {
    return switch (code) {
        1 => .nanosecond,
        2 => .microsecond,
        3 => .millisecond,
        4 => .second,
        5 => .minute,
        6 => .hour,
        7 => .day,
        8 => .week,
        9 => .month,
        10 => .year,
        11 => .auto,
        else => null,
    };
}

fn roundingModeFromCode(code: u8) ?Temporal.Duration.RoundingMode {
    return switch (code) {
        1 => .ceil,
        2 => .floor,
        3 => .expand,
        4 => .trunc,
        5 => .half_ceil,
        6 => .half_floor,
        7 => .half_expand,
        8 => .half_trunc,
        9 => .half_even,
        else => null,
    };
}

export fn temporalz_last_error_ptr() usize {
    return if (last_error) |msg| @intFromPtr(msg.ptr) else 0;
}

export fn temporalz_last_error_len() usize {
    return if (last_error) |msg| msg.len else 0;
}

export fn temporalz_last_error_clear() void {
    clearLastError();
}

export fn temporalz_alloc(len: usize) usize {
    clearLastError();
    const buf = wasm_allocator.alloc(u8, len) catch |err| {
        setLastError(err);
        return 0;
    };
    return @intFromPtr(buf.ptr);
}

export fn temporalz_free(ptr: usize, len: usize) void {
    if (ptr == 0 or len == 0) return;
    const slice = @as([*]u8, @ptrFromInt(ptr))[0..len];
    wasm_allocator.free(slice);
}

export fn temporalz_string_free(ptr: usize, len: usize) void {
    temporalz_free(ptr, len);
}

export fn temporalz_instant_from_utf8(ptr: [*]const u8, len: usize) u32 {
    clearLastError();
    const text = ptr[0..len];
    const inst = Temporal.Instant.from(text) catch |err| {
        setLastError(err);
        return 0;
    };
    return addInstant(inst);
}

export fn temporalz_instant_from_epoch_milliseconds(epoch_ms: i64) u32 {
    clearLastError();
    const inst = Temporal.Instant.fromEpochMilliseconds(epoch_ms) catch |err| {
        setLastError(err);
        return 0;
    };
    return addInstant(inst);
}

export fn temporalz_instant_from_epoch_nanoseconds_parts(hi: i64, lo: u64) u32 {
    clearLastError();
    const epoch_ns = joinI128(hi, lo);
    const inst = Temporal.Instant.fromEpochNanoseconds(epoch_ns) catch |err| {
        setLastError(err);
        return 0;
    };
    return addInstant(inst);
}

export fn temporalz_instant_epoch_milliseconds(handle: u32) i64 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return inst.epochMilliseconds();
}

export fn temporalz_instant_epoch_nanoseconds_hi(handle: u32) i64 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return unpackI128Hi(inst.epochNanoseconds());
}

export fn temporalz_instant_epoch_nanoseconds_lo(handle: u32) u64 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return unpackI128Lo(inst.epochNanoseconds());
}

export fn temporalz_instant_to_string(handle: u32) u64 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const text = inst.toString(wasm_allocator, .{}) catch |err| {
        setLastError(err);
        return 0;
    };
    return packPtrLen(text.ptr, text.len);
}

export fn temporalz_instant_add(handle: u32, duration_handle: u32) u32 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    var dur = getDuration(duration_handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const res = inst.add(&dur) catch |err| {
        setLastError(err);
        return 0;
    };
    return addInstant(res);
}

export fn temporalz_instant_subtract(handle: u32, duration_handle: u32) u32 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    var dur = getDuration(duration_handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const res = inst.subtract(&dur) catch |err| {
        setLastError(err);
        return 0;
    };
    return addInstant(res);
}

export fn temporalz_instant_compare(handle_a: u32, handle_b: u32) i32 {
    clearLastError();
    const a = getInstant(handle_a) catch |err| {
        setLastError(err);
        return 0;
    };
    const b = getInstant(handle_b) catch |err| {
        setLastError(err);
        return 0;
    };
    return @intCast(Temporal.Instant.compare(a, b));
}

export fn temporalz_instant_equals(handle_a: u32, handle_b: u32) u8 {
    clearLastError();
    const a = getInstant(handle_a) catch |err| {
        setLastError(err);
        return 0;
    };
    const b = getInstant(handle_b) catch |err| {
        setLastError(err);
        return 0;
    };
    return if (Temporal.Instant.equals(a, b)) 1 else 0;
}

export fn temporalz_instant_round(
    handle: u32,
    smallest_unit: u8,
    rounding_mode: u8,
    rounding_increment: u32,
) u32 {
    clearLastError();
    const inst = getInstant(handle) catch |err| {
        setLastError(err);
        return 0;
    };

    var opts = Temporal.Instant.RoundingOptions{};
    if (smallest_unit != 255) {
        opts.smallest_unit = unitFromCode(smallest_unit) orelse {
            setLastErrorMessage("Invalid smallestUnit");
            return 0;
        };
    }
    if (rounding_mode != 255) {
        opts.rounding_mode = roundingModeFromCode(rounding_mode) orelse {
            setLastErrorMessage("Invalid roundingMode");
            return 0;
        };
    }
    if (rounding_increment != 0) {
        opts.rounding_increment = rounding_increment;
    }

    const res = inst.round(opts) catch |err| {
        setLastError(err);
        return 0;
    };
    return addInstant(res);
}

export fn temporalz_instant_destroy(handle: u32) void {
    removeInstant(handle);
}

export fn temporalz_duration_from_utf8(ptr: [*]const u8, len: usize) u32 {
    clearLastError();
    const text = ptr[0..len];
    const dur = Temporal.Duration.from(text) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(dur);
}

export fn temporalz_duration_from_parts(
    mask: u32,
    years: i64,
    months: i64,
    weeks: i64,
    days: i64,
    hours: i64,
    minutes: i64,
    seconds: i64,
    milliseconds: i64,
    microseconds: f64,
    nanoseconds: f64,
) u32 {
    clearLastError();
    var partial = Temporal.Duration.PartialDuration{};
    if ((mask & 0x1) != 0) partial.years = years;
    if ((mask & 0x2) != 0) partial.months = months;
    if ((mask & 0x4) != 0) partial.weeks = weeks;
    if ((mask & 0x8) != 0) partial.days = days;
    if ((mask & 0x10) != 0) partial.hours = hours;
    if ((mask & 0x20) != 0) partial.minutes = minutes;
    if ((mask & 0x40) != 0) partial.seconds = seconds;
    if ((mask & 0x80) != 0) partial.milliseconds = milliseconds;
    if ((mask & 0x100) != 0) partial.microseconds = microseconds;
    if ((mask & 0x200) != 0) partial.nanoseconds = nanoseconds;

    const dur = Temporal.Duration.from(partial) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(dur);
}

export fn temporalz_duration_init(
    years: i64,
    months: i64,
    weeks: i64,
    days: i64,
    hours: i64,
    minutes: i64,
    seconds: i64,
    milliseconds: i64,
    microseconds: f64,
    nanoseconds: f64,
) u32 {
    clearLastError();
    const dur = Temporal.Duration.init(
        years,
        months,
        weeks,
        days,
        hours,
        minutes,
        seconds,
        milliseconds,
        microseconds,
        nanoseconds,
    ) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(dur);
}

export fn temporalz_duration_to_string(handle: u32) u64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const text = dur.toString(wasm_allocator, .{}) catch |err| {
        setLastError(err);
        return 0;
    };
    return packPtrLen(text.ptr, text.len);
}

export fn temporalz_duration_years(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.years();
}

export fn temporalz_duration_months(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.months();
}

export fn temporalz_duration_weeks(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.weeks();
}

export fn temporalz_duration_days(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.days();
}

export fn temporalz_duration_hours(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.hours();
}

export fn temporalz_duration_minutes(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.minutes();
}

export fn temporalz_duration_seconds(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.seconds();
}

export fn temporalz_duration_milliseconds(handle: u32) i64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.milliseconds();
}

export fn temporalz_duration_microseconds(handle: u32) f64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.microseconds();
}

export fn temporalz_duration_nanoseconds(handle: u32) f64 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.nanoseconds();
}

export fn temporalz_duration_sign(handle: u32) i32 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return switch (dur.sign()) {
        .positive => 1,
        .zero => 0,
        .negative => -1,
    };
}

export fn temporalz_duration_blank(handle: u32) u8 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return if (dur.blank()) 1 else 0;
}

export fn temporalz_duration_abs(handle: u32) u32 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(dur.abs());
}

export fn temporalz_duration_negated(handle: u32) u32 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(dur.negated());
}

export fn temporalz_duration_add(handle_a: u32, handle_b: u32) u32 {
    clearLastError();
    const a = getDuration(handle_a) catch |err| {
        setLastError(err);
        return 0;
    };
    const b = getDuration(handle_b) catch |err| {
        setLastError(err);
        return 0;
    };
    const res = a.add(b) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(res);
}

export fn temporalz_duration_subtract(handle_a: u32, handle_b: u32) u32 {
    clearLastError();
    const a = getDuration(handle_a) catch |err| {
        setLastError(err);
        return 0;
    };
    const b = getDuration(handle_b) catch |err| {
        setLastError(err);
        return 0;
    };
    const res = a.subtract(b) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(res);
}

export fn temporalz_duration_compare(handle_a: u32, handle_b: u32) i32 {
    clearLastError();
    const a = getDuration(handle_a) catch |err| {
        setLastError(err);
        return 0;
    };
    const b = getDuration(handle_b) catch |err| {
        setLastError(err);
        return 0;
    };
    const res = a.compare(b, .{}) catch |err| {
        setLastError(err);
        return 0;
    };
    return @intCast(res);
}

export fn temporalz_duration_total(handle: u32, unit_code: u8) f64 {
    clearLastError();
    const unit = unitFromCode(unit_code) orelse {
        setLastErrorMessage("Invalid unit");
        return 0;
    };
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.total(.{ .unit = unit }) catch |err| {
        setLastError(err);
        return 0;
    };
}

export fn temporalz_duration_round(
    handle: u32,
    smallest_unit: u8,
    largest_unit: u8,
    rounding_mode: u8,
    rounding_increment: u32,
) u32 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };

    var opts = Temporal.Duration.RoundingOptions{};
    if (smallest_unit != 255) {
        opts.smallest_unit = unitFromCode(smallest_unit) orelse {
            setLastErrorMessage("Invalid smallestUnit");
            return 0;
        };
    }
    if (largest_unit != 255) {
        opts.largest_unit = unitFromCode(largest_unit) orelse {
            setLastErrorMessage("Invalid largestUnit");
            return 0;
        };
    }
    if (rounding_mode != 255) {
        opts.rounding_mode = roundingModeFromCode(rounding_mode) orelse {
            setLastErrorMessage("Invalid roundingMode");
            return 0;
        };
    }
    if (rounding_increment != 0) {
        opts.rounding_increment = rounding_increment;
    }

    const res = dur.round(opts) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(res);
}

export fn temporalz_duration_compare_plain_date(handle_a: u32, handle_b: u32, date_handle: u32) i32 {
    clearLastError();
    const a = getDuration(handle_a) catch |err| {
        setLastError(err);
        return 0;
    };
    const b = getDuration(handle_b) catch |err| {
        setLastError(err);
        return 0;
    };
    const date = getPlainDate(date_handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const res = a.compare(b, .{ .relative_to = .{ .plain_date = date } }) catch |err| {
        setLastError(err);
        return 0;
    };
    return @intCast(res);
}

export fn temporalz_duration_total_plain_date(handle: u32, unit_code: u8, date_handle: u32) f64 {
    clearLastError();
    const unit = unitFromCode(unit_code) orelse {
        setLastErrorMessage("Invalid unit");
        return 0;
    };
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const date = getPlainDate(date_handle) catch |err| {
        setLastError(err);
        return 0;
    };
    return dur.total(.{ .unit = unit, .relative_to = .{ .plain_date = date } }) catch |err| {
        setLastError(err);
        return 0;
    };
}

export fn temporalz_duration_round_plain_date(
    handle: u32,
    smallest_unit: u8,
    largest_unit: u8,
    rounding_mode: u8,
    rounding_increment: u32,
    date_handle: u32,
) u32 {
    clearLastError();
    const dur = getDuration(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const date = getPlainDate(date_handle) catch |err| {
        setLastError(err);
        return 0;
    };

    var opts = Temporal.Duration.RoundingOptions{};
    if (smallest_unit != 255) {
        opts.smallest_unit = unitFromCode(smallest_unit) orelse {
            setLastErrorMessage("Invalid smallestUnit");
            return 0;
        };
    }
    if (largest_unit != 255) {
        opts.largest_unit = unitFromCode(largest_unit) orelse {
            setLastErrorMessage("Invalid largestUnit");
            return 0;
        };
    }
    if (rounding_mode != 255) {
        opts.rounding_mode = roundingModeFromCode(rounding_mode) orelse {
            setLastErrorMessage("Invalid roundingMode");
            return 0;
        };
    }
    if (rounding_increment != 0) {
        opts.rounding_increment = rounding_increment;
    }
    opts.relative_to = .{ .plain_date = date };

    const res = dur.round(opts) catch |err| {
        setLastError(err);
        return 0;
    };
    return addDuration(res);
}

export fn temporalz_plain_date_from_utf8(ptr: [*]const u8, len: usize) u32 {
    clearLastError();
    const text = ptr[0..len];
    const date = Temporal.PlainDate.from(text) catch |err| {
        setLastError(err);
        return 0;
    };
    return addPlainDate(date);
}

export fn temporalz_plain_date_init(year: i32, month: u8, day: u8) u32 {
    clearLastError();
    const date = Temporal.PlainDate.init(year, month, day) catch |err| {
        setLastError(err);
        return 0;
    };
    return addPlainDate(date);
}

export fn temporalz_plain_date_to_string(handle: u32) u64 {
    clearLastError();
    const date = getPlainDate(handle) catch |err| {
        setLastError(err);
        return 0;
    };
    const text = date.toString(wasm_allocator, .{}) catch |err| {
        setLastError(err);
        return 0;
    };
    return packPtrLen(text.ptr, text.len);
}

export fn temporalz_plain_date_destroy(handle: u32) void {
    removePlainDate(handle);
}

export fn temporalz_duration_destroy(handle: u32) void {
    removeDuration(handle);
}

extern fn console(ptr: [*]u8, len: u32) void;

fn logFn(comptime _: anytype, comptime _: anytype, comptime format: []const u8, args: anytype) void {
    const formatted = std.fmt.allocPrint(std.heap.wasm_allocator, format, args) catch return;
    console(formatted.ptr, formatted.len);
}

pub const std_options: std.Options = .{ .logFn = logFn };
