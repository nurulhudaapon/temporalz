const std = @import("std");

const Instant = @This();

_inner: *CInstant,
epoch_milliseconds: i64,
epoch_nanoseconds: i128,

/// Construct from epoch nanoseconds (Temporal.Instant.fromEpochNanoseconds).
pub fn init(epoch_ns: i128) !Instant {
    return fromEpochNanoseconds(epoch_ns);
}

/// Construct from epoch milliseconds.
pub fn fromEpochMilliseconds(epoch_ms: i64) !Instant {
    return wrapInstant(temporal_rs_Instant_from_epoch_milliseconds(epoch_ms));
}

/// Construct from epoch nanoseconds (Temporal.Instant.fromEpochNanoseconds).
pub fn fromEpochNanoseconds(epoch_ns: i128) !Instant {
    const parts = i128ToParts(epoch_ns);
    return wrapInstant(temporal_rs_Instant_try_new(parts));
}

/// Parse an ISO 8601 string (Temporal.Instant.from).
pub fn from(text: []const u8) !Instant {
    const view = DiplomatStringView{ .data = text.ptr, .len = text.len };
    return wrapInstant(temporal_rs_Instant_from_utf8(view));
}

/// Parse an ISO 8601 UTF-16 string (Temporal.Instant.from).
fn fromUtf16(text: []const u16) !Instant {
    const view = DiplomatString16View{ .data = text.ptr, .len = text.len };
    return wrapInstant(temporal_rs_Instant_from_utf16(view));
}

/// Add a Duration to this instant (Temporal.Instant.prototype.add).
pub fn add(self: Instant, duration: *const Duration) !Instant {
    return wrapInstant(temporal_rs_Instant_add(self._inner, duration));
}

/// Subtract a Duration from this instant (Temporal.Instant.prototype.subtract).
pub fn subtract(self: Instant, duration: *const Duration) !Instant {
    return wrapInstant(temporal_rs_Instant_subtract(self._inner, duration));
}

/// Difference until another instant (Temporal.Instant.prototype.until).
pub fn until(self: Instant, other: Instant, settings: DifferenceSettings) !DurationHandle {
    return wrapDuration(temporal_rs_Instant_until(self._inner, other._inner, settings));
}

/// Difference since another instant (Temporal.Instant.prototype.since).
pub fn since(self: Instant, other: Instant, settings: DifferenceSettings) !DurationHandle {
    return wrapDuration(temporal_rs_Instant_since(self._inner, other._inner, settings));
}

/// Round this instant (Temporal.Instant.prototype.round).
pub fn round(self: Instant, options: RoundingOptions) !Instant {
    return wrapInstant(temporal_rs_Instant_round(self._inner, options));
}

/// Compare two instants (Temporal.Instant.compare).
pub fn compare(a: Instant, b: Instant) i8 {
    return temporal_rs_Instant_compare(a._inner, b._inner);
}

/// Equality check (Temporal.Instant.prototype.equals).
pub fn equals(a: Instant, b: Instant) bool {
    return temporal_rs_Instant_equals(a._inner, b._inner);
}

/// Convert to string using compiled TZ data; caller owns returned slice.
pub fn toString(self: Instant, allocator: std.mem.Allocator, opts: ToStringOptions) ![]u8 {
    const zone_opt = if (opts.time_zone) |z|
        TimeZone_option{ .ok = z, .is_ok = true }
    else
        TimeZone_option{ .ok = undefined, .is_ok = false };

    const rounding = opts.rounding orelse defaultToStringRoundingOptions();

    const writer = diplomat_buffer_write_create(128);
    defer diplomat_buffer_write_destroy(writer);

    const res = temporal_rs_Instant_to_ixdtf_string_with_compiled_data(self._inner, zone_opt, rounding, writer);
    try handleVoidResult(res);

    const len = diplomat_buffer_write_len(writer);
    const source = diplomat_buffer_write_get_bytes(writer)[0..len];

    const out = try allocator.alloc(u8, len);
    std.mem.copyForwards(u8, out, source);
    return out;
}

/// Convert to string using an explicit provider.
fn toStringWithProvider(self: Instant, allocator: std.mem.Allocator, provider: *const Provider, opts: ToStringOptions) ![]u8 {
    const zone_opt = if (opts.time_zone) |z|
        TimeZone_option{ .ok = z, .is_ok = true }
    else
        TimeZone_option{ .ok = undefined, .is_ok = false };

    const rounding = opts.rounding orelse defaultToStringRoundingOptions();

    const writer = diplomat_buffer_write_create(128);
    defer diplomat_buffer_write_destroy(writer);

    const res = temporal_rs_Instant_to_ixdtf_string_with_provider(self._inner, zone_opt, rounding, provider, writer);
    try handleVoidResult(res);

    const len = diplomat_buffer_write_len(writer);
    const source = diplomat_buffer_write_get_bytes(writer)[0..len];

    const out = try allocator.alloc(u8, len);
    std.mem.copyForwards(u8, out, source);
    return out;
}

pub fn toJSON(self: Instant, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

pub fn toLocaleString(self: Instant, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

/// Convert to ZonedDateTime using built-in provider (Temporal.Instant.prototype.toZonedDateTimeISO).
pub fn toZonedDateTimeISO(self: Instant, zone: TimeZone) !ZonedDateTimeHandle {
    return wrapZonedDateTime(temporal_rs_Instant_to_zoned_date_time_iso(self._inner, zone));
}

/// Convert to ZonedDateTime using an explicit provider.
fn toZonedDateTimeIsoWithProvider(self: Instant, zone: TimeZone, provider: *const Provider) !ZonedDateTimeHandle {
    return wrapZonedDateTime(temporal_rs_Instant_to_zoned_date_time_iso_with_provider(self._inner, zone, provider));
}

/// Clone the underlying instant.
fn clone(self: Instant) Instant {
    const ptr = temporal_rs_Instant_clone(self._inner);
    return .{ ._inner = ptr, .epoch_milliseconds = temporal_rs_Instant_epoch_milliseconds(ptr), .epoch_nanoseconds = partsToI128(temporal_rs_Instant_epoch_nanoseconds(ptr)) };
}

pub fn deinit(self: Instant) void {
    temporal_rs_Instant_destroy(self._inner);
}

// --- Helpers -----------------------------------------------------------------

fn wrapInstant(res: InstantResult) !Instant {
    if (!res.is_ok) return error.TemporalError;
    const ptr = res.result.ok orelse return error.TemporalError;
    return .{ ._inner = ptr, .epoch_milliseconds = temporal_rs_Instant_epoch_milliseconds(ptr), .epoch_nanoseconds = partsToI128(temporal_rs_Instant_epoch_nanoseconds(ptr)) };
}

fn wrapDuration(res: DurationResult) !DurationHandle {
    if (!res.is_ok) return error.TemporalError;
    const ptr = res.result.ok orelse return error.TemporalError;
    return .{ .ptr = ptr };
}

fn wrapZonedDateTime(res: ZonedDateTimeResult) !ZonedDateTimeHandle {
    if (!res.is_ok) return error.TemporalError;
    const ptr = res.result.ok orelse return error.TemporalError;
    return .{ .ptr = ptr };
}

fn handleVoidResult(res: VoidResult) !void {
    if (!res.is_ok) return error.TemporalError;
}

fn i128ToParts(value: i128) I128Nanoseconds {
    const is_neg = value < 0;
    const mag: u128 = if (is_neg) @intCast(@as(u128, @intCast(-value))) else @intCast(value);
    const mask: u64 = 1 << 63;
    var high: u64 = @intCast(mag >> 64);
    const low: u64 = @intCast(mag & 0xffff_ffff_ffff_ffff);
    if (is_neg) high |= mask;
    return .{ .high = high, .low = low };
}

fn partsToI128(value: I128Nanoseconds) i128 {
    const mask: u64 = 1 << 63;
    const is_neg = (value.high & mask) != 0;
    const mag: u128 = ((@as(u128, value.high & ~mask)) << 64) | value.low;
    if (is_neg) return -@as(i128, @intCast(mag));
    return @as(i128, @intCast(mag));
}

fn defaultPrecision() Precision {
    return .{ .is_minute = false, .precision = OptionU8{ .ok = 0, .is_ok = false } };
}

fn defaultToStringRoundingOptions() ToStringRoundingOptions {
    return .{
        .precision = defaultPrecision(),
        .smallest_unit = Unit_option{ .ok = .Unit_Auto, .is_ok = false },
        .rounding_mode = RoundingMode_option{ .ok = .RoundingMode_Trunc, .is_ok = false },
    };
}

fn parseDuration(text: []const u8) !DurationHandle {
    const view = DiplomatStringView{ .data = text.ptr, .len = text.len };
    const res = temporal_rs_Duration_from_utf8(view);
    if (!res.is_ok) return error.TemporalError;
    const ptr = res.result.ok orelse return error.TemporalError;
    return .{ .ptr = ptr };
}

// --- Public helper types -----------------------------------------------------

const ToStringOptions = struct {
    time_zone: ?TimeZone = null,
    rounding: ?ToStringRoundingOptions = null,
};

const DurationHandle = struct {
    ptr: *Duration,

    pub fn deinit(self: DurationHandle) void {
        temporal_rs_Duration_destroy(self.ptr);
    }
};

const ZonedDateTimeHandle = struct {
    ptr: *ZonedDateTime,

    pub fn deinit(self: ZonedDateTimeHandle) void {
        temporal_rs_ZonedDateTime_destroy(self.ptr);
    }
};

// --- Extern types ------------------------------------------------------------

const CInstant = opaque {};
const Duration = opaque {};
const ZonedDateTime = opaque {};
const Provider = opaque {};

const I128Nanoseconds = extern struct { high: u64, low: u64 };
const I128Nanoseconds_option = extern struct { ok: I128Nanoseconds, is_ok: bool };

const DiplomatStringView = extern struct { data: [*c]const u8, len: usize };
const DiplomatString16View = extern struct { data: [*c]const u16, len: usize };

const OptionStringView = extern struct { ok: DiplomatStringView, is_ok: bool };
const OptionU8 = extern struct { ok: u8, is_ok: bool };
const OptionU32 = extern struct { ok: u32, is_ok: bool };

const DiplomatWrite = extern struct {
    context: ?*anyopaque,
    buf: [*c]u8,
    len: usize,
    cap: usize,
    grow_failed: bool,
    flush: ?*const fn (*DiplomatWrite) void,
    grow: ?*const fn (*DiplomatWrite, usize) bool,
};

const TimeZone = extern struct {
    offset_minutes: i16,
    resolved_id: usize,
    normalized_id: usize,
    is_iana_id: bool,
};

const TimeZone_option = extern struct {
    ok: TimeZone,
    is_ok: bool,
};

const Precision = extern struct {
    is_minute: bool,
    precision: OptionU8,
};

const Unit = enum(c_int) {
    Unit_Auto = 0,
    Unit_Nanosecond = 1,
    Unit_Microsecond = 2,
    Unit_Millisecond = 3,
    Unit_Second = 4,
    Unit_Minute = 5,
    Unit_Hour = 6,
    Unit_Day = 7,
    Unit_Week = 8,
    Unit_Month = 9,
    Unit_Year = 10,
};

const Unit_option = extern struct { ok: Unit, is_ok: bool };

const RoundingMode = enum(c_int) {
    RoundingMode_Ceil = 0,
    RoundingMode_Floor = 1,
    RoundingMode_Expand = 2,
    RoundingMode_Trunc = 3,
    RoundingMode_HalfCeil = 4,
    RoundingMode_HalfFloor = 5,
    RoundingMode_HalfExpand = 6,
    RoundingMode_HalfTrunc = 7,
    RoundingMode_HalfEven = 8,
};

const RoundingMode_option = extern struct { ok: RoundingMode, is_ok: bool };

const DifferenceSettings = extern struct {
    largest_unit: Unit_option,
    smallest_unit: Unit_option,
    rounding_mode: RoundingMode_option,
    increment: OptionU32,
};

const RoundingOptions = extern struct {
    largest_unit: Unit_option,
    smallest_unit: Unit_option,
    rounding_mode: RoundingMode_option,
    increment: OptionU32,
};

const ToStringRoundingOptions = extern struct {
    precision: Precision,
    smallest_unit: Unit_option,
    rounding_mode: RoundingMode_option,
};

const ErrorKind = enum(c_int) {
    ErrorKind_Generic = 0,
    ErrorKind_Type = 1,
    ErrorKind_Range = 2,
    ErrorKind_Syntax = 3,
    ErrorKind_Assert = 4,
};

const TemporalError = extern struct {
    kind: ErrorKind,
    msg: OptionStringView,
};

const Sign = enum(c_int) {
    Sign_Positive = 1,
    Sign_Zero = 0,
    Sign_Negative = -1,
};

// --- Result wrappers ---------------------------------------------------------

const InstantResult = extern struct {
    result: extern union {
        ok: ?*CInstant,
        err: TemporalError,
    },
    is_ok: bool,
};

const DurationResult = extern struct {
    result: extern union {
        ok: ?*Duration,
        err: TemporalError,
    },
    is_ok: bool,
};

const DurationParseResult = extern struct {
    result: extern union {
        ok: ?*Duration,
        err: TemporalError,
    },
    is_ok: bool,
};

const ZonedDateTimeResult = extern struct {
    result: extern union {
        ok: ?*ZonedDateTime,
        err: TemporalError,
    },
    is_ok: bool,
};

const VoidResult = extern struct {
    result: extern union {
        err: TemporalError,
    },
    is_ok: bool,
};

// --- Extern functions -------------------------------------------------------

extern "c" fn temporal_rs_Instant_try_new(ns: I128Nanoseconds) InstantResult;
extern "c" fn temporal_rs_Instant_from_epoch_milliseconds(epoch_milliseconds: i64) InstantResult;
extern "c" fn temporal_rs_Instant_from_utf8(s: DiplomatStringView) InstantResult;
extern "c" fn temporal_rs_Instant_from_utf16(s: DiplomatString16View) InstantResult;
extern "c" fn temporal_rs_Instant_add(self: *const CInstant, duration: *const Duration) InstantResult;
extern "c" fn temporal_rs_Instant_subtract(self: *const CInstant, duration: *const Duration) InstantResult;
extern "c" fn temporal_rs_Instant_since(self: *const CInstant, other: *const CInstant, settings: DifferenceSettings) DurationResult;
extern "c" fn temporal_rs_Instant_until(self: *const CInstant, other: *const CInstant, settings: DifferenceSettings) DurationResult;
extern "c" fn temporal_rs_Instant_round(self: *const CInstant, options: RoundingOptions) InstantResult;
extern "c" fn temporal_rs_Instant_compare(self: *const CInstant, other: *const CInstant) i8;
extern "c" fn temporal_rs_Instant_equals(self: *const CInstant, other: *const CInstant) bool;
extern "c" fn temporal_rs_Instant_epoch_milliseconds(self: *const CInstant) i64;
extern "c" fn temporal_rs_Instant_epoch_nanoseconds(self: *const CInstant) I128Nanoseconds;
extern "c" fn temporal_rs_Instant_to_ixdtf_string_with_compiled_data(self: *const CInstant, zone: TimeZone_option, options: ToStringRoundingOptions, write: *DiplomatWrite) VoidResult;
extern "c" fn temporal_rs_Instant_to_ixdtf_string_with_provider(self: *const CInstant, zone: TimeZone_option, options: ToStringRoundingOptions, p: *const Provider, write: *DiplomatWrite) VoidResult;
extern "c" fn temporal_rs_Instant_to_zoned_date_time_iso(self: *const CInstant, zone: TimeZone) ZonedDateTimeResult;
extern "c" fn temporal_rs_Instant_to_zoned_date_time_iso_with_provider(self: *const CInstant, zone: TimeZone, p: *const Provider) ZonedDateTimeResult;
extern "c" fn temporal_rs_Instant_clone(self: *const CInstant) *CInstant;
extern "c" fn temporal_rs_Instant_destroy(self: *CInstant) void;

extern "c" fn temporal_rs_Duration_destroy(self: *Duration) void;
extern "c" fn temporal_rs_Duration_from_utf8(s: DiplomatStringView) DurationParseResult;
extern "c" fn temporal_rs_Duration_hours(self: *const Duration) i64;
extern "c" fn temporal_rs_Duration_minutes(self: *const Duration) i64;
extern "c" fn temporal_rs_Duration_seconds(self: *const Duration) i64;
extern "c" fn temporal_rs_Duration_milliseconds(self: *const Duration) i64;
extern "c" fn temporal_rs_Duration_microseconds(self: *const Duration) f64;
extern "c" fn temporal_rs_Duration_nanoseconds(self: *const Duration) f64;
extern "c" fn temporal_rs_Duration_sign(self: *const Duration) Sign;
extern "c" fn temporal_rs_ZonedDateTime_destroy(self: *ZonedDateTime) void;

extern "c" fn diplomat_buffer_write_create(cap: usize) *DiplomatWrite;
extern "c" fn diplomat_buffer_write_get_bytes(write: *DiplomatWrite) [*c]u8;
extern "c" fn diplomat_buffer_write_len(write: *DiplomatWrite) usize;
extern "c" fn diplomat_buffer_write_destroy(write: *DiplomatWrite) void;

// --- Tests -------------------------------------------------------------------

test init {
    const epoch_ns: i128 = 1_704_067_200_000_000_000; // 2024-01-01T00:00:00Z
    const inst = try Instant.init(epoch_ns);
    defer inst.deinit();

    try std.testing.expectEqual(epoch_ns, inst.epoch_nanoseconds);
}

test fromEpochNanoseconds {
    // The Rust implementation accepts values within the 100M-day window (inclusive).
    const max_ns: i128 = 8_640_000_000_000_000_000_000;
    const min_ns: i128 = -max_ns;

    const max_inst = try Instant.fromEpochNanoseconds(max_ns);
    defer max_inst.deinit();
    const min_inst = try Instant.fromEpochNanoseconds(min_ns);
    defer min_inst.deinit();

    try std.testing.expectEqual(max_ns, max_inst.epoch_nanoseconds);
    try std.testing.expectEqual(min_ns, min_inst.epoch_nanoseconds);

    try std.testing.expectError(error.TemporalError, Instant.fromEpochNanoseconds(max_ns + 1));
    try std.testing.expectError(error.TemporalError, Instant.fromEpochNanoseconds(min_ns - 1));
}

test from {
    const inst = try Instant.from("2024-03-15T14:30:45.123Z");
    defer inst.deinit();

    try std.testing.expectEqual(@as(i64, 1_710_513_045_123), inst.epoch_milliseconds);
}

test fromUtf16 {
    const utf8 = "2024-03-15T14:30:45.123Z";
    const allocator = std.testing.allocator;
    const utf16 = try std.unicode.utf8ToUtf16LeAlloc(allocator, utf8);
    defer allocator.free(utf16);

    const inst = try Instant.fromUtf16(utf16);
    defer inst.deinit();

    try std.testing.expectEqual(@as(i64, 1_710_513_045_123), inst.epoch_milliseconds);
}

test subtract {
    const base = try Instant.fromEpochMilliseconds(0);
    defer base.deinit();

    var dur = try parseDuration("PT1H30M");
    defer dur.deinit();

    const added = try base.add(dur.ptr);
    defer added.deinit();
    try std.testing.expectEqual(@as(i64, 5_400_000), added.epoch_milliseconds);

    const subbed = try added.subtract(dur.ptr);
    defer subbed.deinit();
    try std.testing.expectEqual(@as(i64, 0), subbed.epoch_milliseconds);
}

test compare {
    const a = try Instant.fromEpochMilliseconds(0);
    defer a.deinit();
    const b = try Instant.fromEpochMilliseconds(0);
    defer b.deinit();
    const c = try Instant.fromEpochMilliseconds(1_000);
    defer c.deinit();

    try std.testing.expectEqual(@as(i8, 0), Instant.compare(a, b));
    try std.testing.expect(Instant.equals(a, b));
    try std.testing.expectEqual(@as(i8, -1), Instant.compare(a, c));
    try std.testing.expectEqual(@as(i8, 1), Instant.compare(c, a));
}

test equals {
    const a = try Instant.fromEpochMilliseconds(0);
    defer a.deinit();
    const b = try Instant.fromEpochMilliseconds(0);
    defer b.deinit();
    const c = try Instant.fromEpochMilliseconds(1_000);
    defer c.deinit();

    try std.testing.expectEqual(@as(i8, 0), Instant.compare(a, b));
    try std.testing.expect(Instant.equals(a, b));
    try std.testing.expectEqual(@as(i8, -1), Instant.compare(a, c));
    try std.testing.expectEqual(@as(i8, 1), Instant.compare(c, a));
}

test until {
    const earlier = try Instant.fromEpochMilliseconds(0);
    defer earlier.deinit();
    const later = try Instant.fromEpochMilliseconds(3_600_000);
    defer later.deinit();

    const settings = DifferenceSettings{
        .largest_unit = Unit_option{ .ok = .Unit_Hour, .is_ok = true },
        .smallest_unit = Unit_option{ .ok = .Unit_Second, .is_ok = true },
        .rounding_mode = RoundingMode_option{ .ok = .RoundingMode_Trunc, .is_ok = true },
        .increment = OptionU32{ .ok = 0, .is_ok = false },
    };

    var until_handle = try earlier.until(later, settings);
    defer until_handle.deinit();
    try std.testing.expectEqual(Sign.Sign_Positive, temporal_rs_Duration_sign(until_handle.ptr));
    try std.testing.expectEqual(@as(i64, 1), temporal_rs_Duration_hours(until_handle.ptr));

    var since_handle = try later.since(earlier, settings);
    defer since_handle.deinit();
    try std.testing.expectEqual(Sign.Sign_Positive, temporal_rs_Duration_sign(since_handle.ptr));
    try std.testing.expectEqual(@as(i64, 1), temporal_rs_Duration_hours(since_handle.ptr));
}

test since {
    const earlier = try Instant.fromEpochMilliseconds(0);
    defer earlier.deinit();
    const later = try Instant.fromEpochMilliseconds(3_600_000);
    defer later.deinit();

    const settings = DifferenceSettings{
        .largest_unit = Unit_option{ .ok = .Unit_Hour, .is_ok = true },
        .smallest_unit = Unit_option{ .ok = .Unit_Second, .is_ok = true },
        .rounding_mode = RoundingMode_option{ .ok = .RoundingMode_Trunc, .is_ok = true },
        .increment = OptionU32{ .ok = 0, .is_ok = false },
    };

    var until_handle = try earlier.until(later, settings);
    defer until_handle.deinit();
    try std.testing.expectEqual(Sign.Sign_Positive, temporal_rs_Duration_sign(until_handle.ptr));
    try std.testing.expectEqual(@as(i64, 1), temporal_rs_Duration_hours(until_handle.ptr));

    var since_handle = try later.since(earlier, settings);
    defer since_handle.deinit();
    try std.testing.expectEqual(Sign.Sign_Positive, temporal_rs_Duration_sign(since_handle.ptr));
    try std.testing.expectEqual(@as(i64, 1), temporal_rs_Duration_hours(since_handle.ptr));
}

test round {
    const inst = try Instant.fromEpochNanoseconds(1_609_459_245_123_456_789);
    defer inst.deinit();

    const opts = RoundingOptions{
        .largest_unit = Unit_option{ .ok = .Unit_Auto, .is_ok = false },
        .smallest_unit = Unit_option{ .ok = .Unit_Second, .is_ok = true },
        .rounding_mode = RoundingMode_option{ .ok = .RoundingMode_HalfExpand, .is_ok = true },
        .increment = OptionU32{ .ok = 0, .is_ok = false },
    };

    const rounded = try inst.round(opts);
    defer rounded.deinit();

    const ns = rounded.epoch_nanoseconds;
    try std.testing.expectEqual(@as(i128, 1_609_459_245_000_000_000), ns);
}

test clone {
    const inst = try Instant.fromEpochMilliseconds(42);
    defer inst.deinit();

    const cloned = inst.clone();
    defer cloned.deinit();

    try std.testing.expectEqual(inst.epoch_milliseconds, cloned.epoch_milliseconds);
}

test toString {
    const epoch_ns: i128 = 1704067200000000000; // 2024-01-01 00:00:00 UTC
    const inst = try Instant.init(epoch_ns);
    defer inst.deinit();

    const allocator = std.testing.allocator;
    const instant_str = try inst.toString(allocator, .{});
    defer allocator.free(instant_str);
    try std.testing.expectEqualStrings(instant_str, "2024-01-01T00:00:00Z");
}
