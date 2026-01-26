const std = @import("std");
const abi = @import("abi.zig");
const temporal = @import("temporal.zig");

const Duration = @import("Duration.zig");
const Instant = @This();

_inner: *abi.c.Instant,
epoch_milliseconds: i64,
epoch_nanoseconds: i128,

pub const Unit = temporal.Unit;
pub const RoundingMode = temporal.RoundingMode;
pub const Sign = temporal.Sign;

/// Construct from epoch nanoseconds (Temporal.Instant.fromEpochNanoseconds).
pub fn init(epoch_ns: i128) !Instant {
    return fromEpochNanoseconds(epoch_ns);
}

/// Construct from epoch milliseconds.
pub fn fromEpochMilliseconds(epoch_ms: i64) !Instant {
    return wrapInstant(abi.c.temporal_rs_Instant_from_epoch_milliseconds(epoch_ms));
}

/// Construct from epoch nanoseconds (Temporal.Instant.fromEpochNanoseconds).
pub fn fromEpochNanoseconds(epoch_ns: i128) !Instant {
    const parts = abi.toI128Nanoseconds(epoch_ns);
    return wrapInstant(abi.c.temporal_rs_Instant_try_new(parts));
}

/// Parse an ISO 8601 string (Temporal.Instant.from).
pub fn from(text: []const u8) !Instant {
    const view = abi.toDiplomatStringView(text);
    return wrapInstant(abi.c.temporal_rs_Instant_from_utf8(view));
}

/// Parse an ISO 8601 UTF-16 string (Temporal.Instant.from).
fn fromUtf16(text: []const u16) !Instant {
    const view = abi.toDiplomatString16View(text);
    return wrapInstant(abi.c.temporal_rs_Instant_from_utf16(view));
}

/// Add a Duration to this instant (Temporal.Instant.prototype.add).
pub fn add(self: Instant, duration: *Duration) !Instant {
    return wrapInstant(abi.c.temporal_rs_Instant_add(self._inner, duration._inner));
}

/// Subtract a Duration from this instant (Temporal.Instant.prototype.subtract).
pub fn subtract(self: Instant, duration: *Duration) !Instant {
    return wrapInstant(abi.c.temporal_rs_Instant_subtract(self._inner, duration._inner));
}

/// Difference until another instant (Temporal.Instant.prototype.until).
pub fn until(self: Instant, other: Instant, settings: abi.c.DifferenceSettings) !DurationHandle {
    return wrapDuration(abi.c.temporal_rs_Instant_until(self._inner, other._inner, settings));
}

/// Difference since another instant (Temporal.Instant.prototype.since).
pub fn since(self: Instant, other: Instant, settings: abi.c.DifferenceSettings) !DurationHandle {
    return wrapDuration(abi.c.temporal_rs_Instant_since(self._inner, other._inner, settings));
}

/// Round this instant (Temporal.Instant.prototype.round).
pub fn round(self: Instant, options: abi.c.RoundingOptions) !Instant {
    return wrapInstant(abi.c.temporal_rs_Instant_round(self._inner, options));
}

/// Compare two instants (Temporal.Instant.compare).
pub fn compare(a: Instant, b: Instant) i8 {
    return abi.c.temporal_rs_Instant_compare(a._inner, b._inner);
}

/// Equality check (Temporal.Instant.prototype.equals).
pub fn equals(a: Instant, b: Instant) bool {
    return abi.c.temporal_rs_Instant_equals(a._inner, b._inner);
}

/// Convert to string using compiled TZ data; caller owns returned slice.
pub fn toString(self: Instant, allocator: std.mem.Allocator, opts: ToStringOptions) ![]u8 {
    const zone_opt = abi.toTimeZoneOption(opts.time_zone);
    const rounding = optsToRounding(opts);

    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = abi.c.temporal_rs_Instant_to_ixdtf_string_with_compiled_data(self._inner, zone_opt, rounding, &write.inner);
    try handleVoidResult(res);

    return try write.toOwnedSlice();
}

/// Convert to string using an explicit provider.
fn toStringWithProvider(self: Instant, allocator: std.mem.Allocator, provider: *const abi.c.Provider, opts: ToStringOptions) ![]u8 {
    const zone_opt = abi.toTimeZoneOption(opts.time_zone);
    const rounding = optsToRounding(opts);

    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = abi.c.temporal_rs_Instant_to_ixdtf_string_with_provider(self._inner, zone_opt, rounding, provider, &write.inner);
    try handleVoidResult(res);

    return try write.toOwnedSlice();
}

pub fn toJSON(self: Instant, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

pub fn toLocaleString(self: Instant, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

/// Convert to ZonedDateTime using built-in provider (Temporal.Instant.prototype.toZonedDateTimeISO).
pub fn toZonedDateTimeISO(self: Instant, zone: abi.c.TimeZone) !ZonedDateTimeHandle {
    return wrapZonedDateTime(abi.c.temporal_rs_Instant_to_zoned_date_time_iso(self._inner, zone));
}

/// Convert to ZonedDateTime using an explicit provider.
fn toZonedDateTimeIsoWithProvider(self: Instant, zone: abi.c.TimeZone, provider: *const abi.c.Provider) !ZonedDateTimeHandle {
    return wrapZonedDateTime(abi.c.temporal_rs_Instant_to_zoned_date_time_iso_with_provider(self._inner, zone, provider));
}

/// Clone the underlying instant.
fn clone(self: Instant) Instant {
    const ptr = abi.c.temporal_rs_Instant_clone(self._inner) orelse unreachable;
    return .{ ._inner = ptr, .epoch_milliseconds = abi.c.temporal_rs_Instant_epoch_milliseconds(ptr), .epoch_nanoseconds = abi.fromI128Nanoseconds(abi.c.temporal_rs_Instant_epoch_nanoseconds(ptr)) };
}

pub fn deinit(self: Instant) void {
    abi.c.temporal_rs_Instant_destroy(self._inner);
}

// --- Helpers -----------------------------------------------------------------

fn wrapInstant(res: anytype) !Instant {
    const ptr = (abi.success(res) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{
        ._inner = ptr,
        .epoch_milliseconds = abi.c.temporal_rs_Instant_epoch_milliseconds(ptr),
        .epoch_nanoseconds = abi.fromI128Nanoseconds(abi.c.temporal_rs_Instant_epoch_nanoseconds(ptr)),
    };
}

fn wrapDuration(res: anytype) !DurationHandle {
    const ptr = (abi.success(res) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ .ptr = ptr };
}

fn wrapZonedDateTime(res: anytype) !ZonedDateTimeHandle {
    const ptr = (abi.success(res) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ .ptr = ptr };
}

fn handleVoidResult(res: anytype) !void {
    _ = abi.success(res) orelse return error.TemporalError;
}

fn defaultPrecision() abi.c.Precision {
    return .{ .is_minute = false, .precision = abi.toOption(abi.c.OptionU8, null) };
}

fn defaultToStringRoundingOptions() abi.c.ToStringRoundingOptions {
    return abi.to_string_rounding_options_auto;
}

/// Convert ToStringOptions to ToStringRoundingOptions for the C API
fn optsToRounding(opts: ToStringOptions) abi.c.ToStringRoundingOptions {
    // If smallest_unit is specified, use it; otherwise use fractional_second_digits for precision
    const precision = if (opts.fractional_second_digits) |digits|
        abi.c.Precision{ .is_minute = false, .precision = abi.toOption(abi.c.OptionU8, digits) }
    else
        defaultPrecision();

    const smallest_unit = if (opts.smallest_unit) |unit| unit.toCApi() else null;
    const rounding_mode = if (opts.rounding_mode) |mode| mode.toCApi() else null;

    return .{
        .precision = precision,
        .smallest_unit = abi.toUnitOption(smallest_unit),
        .rounding_mode = abi.toRoundingModeOption(rounding_mode),
    };
}

fn parseDuration(text: []const u8) !DurationHandle {
    const view = abi.toDiplomatStringView(text);
    return wrapDuration(abi.c.temporal_rs_Duration_from_utf8(view));
}

// --- Public helper types -----------------------------------------------------

/// Options for Instant.toString()
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Instant/toString
pub const ToStringOptions = struct {
    /// Either an integer from 0 to 9, or null for "auto".
    /// If null (auto), trailing zeros are removed from the fractional seconds.
    /// Otherwise, the fractional part contains this many digits, padded with zeros or rounded as necessary.
    fractional_second_digits: ?u8 = null,

    /// Specifies how to round off fractional second digits beyond fractionalSecondDigits.
    /// Defaults to "trunc" (truncate).
    rounding_mode: ?RoundingMode = null,

    /// Specifies the smallest unit to include in the output.
    /// Possible values: "minute", "second", "millisecond", "microsecond", "nanosecond".
    /// If specified, fractional_second_digits is ignored.
    smallest_unit: ?Unit = null,

    /// Time zone to use. Either a time zone identifier string or null for UTC.
    /// Note: In the Zig API, this must be pre-resolved to a TimeZone struct.
    time_zone: ?abi.c.TimeZone = null,
};

const DurationHandle = struct {
    ptr: *abi.c.Duration,

    pub fn deinit(self: DurationHandle) void {
        abi.c.temporal_rs_Duration_destroy(self.ptr);
    }
};

const ZonedDateTimeHandle = struct {
    ptr: *abi.c.ZonedDateTime,

    pub fn deinit(self: ZonedDateTimeHandle) void {
        abi.c.temporal_rs_ZonedDateTime_destroy(self.ptr);
    }
};

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

    var dur = try Duration.from("PT1H30M");
    defer dur.deinit();

    const added = try base.add(&dur);
    defer added.deinit();
    try std.testing.expectEqual(@as(i64, 5_400_000), added.epoch_milliseconds);

    const subbed = try added.subtract(&dur);
    defer subbed.deinit();
    try std.testing.expectEqual(@as(i64, 0), subbed.epoch_milliseconds);
}

test compare {
    const a = try Instant.fromEpochMilliseconds(0);
    defer a.deinit();
    const b = try Instant.fromEpochMilliseconds(0);
    defer b.deinit();
    const cc = try Instant.fromEpochMilliseconds(1_000);
    defer cc.deinit();

    try std.testing.expectEqual(@as(i8, 0), Instant.compare(a, b));
    try std.testing.expect(Instant.equals(a, b));
    try std.testing.expectEqual(@as(i8, -1), Instant.compare(a, cc));
    try std.testing.expectEqual(@as(i8, 1), Instant.compare(cc, a));
}

test equals {
    const a = try Instant.fromEpochMilliseconds(0);
    defer a.deinit();
    const b = try Instant.fromEpochMilliseconds(0);
    defer b.deinit();
    const cc = try Instant.fromEpochMilliseconds(1_000);
    defer cc.deinit();

    try std.testing.expectEqual(@as(i8, 0), Instant.compare(a, b));
    try std.testing.expect(Instant.equals(a, b));
    try std.testing.expectEqual(@as(i8, -1), Instant.compare(a, cc));
    try std.testing.expectEqual(@as(i8, 1), Instant.compare(cc, a));
}

test until {
    const earlier = try Instant.fromEpochMilliseconds(0);
    defer earlier.deinit();
    const later = try Instant.fromEpochMilliseconds(3_600_000);
    defer later.deinit();

    const settings = abi.c.DifferenceSettings{
        .largest_unit = abi.toUnitOption(Unit.hour.toCApi()),
        .smallest_unit = abi.toUnitOption(Unit.second.toCApi()),
        .rounding_mode = abi.toRoundingModeOption(RoundingMode.trunc.toCApi()),
        .increment = abi.toOption(abi.c.OptionU32, null),
    };

    var until_handle = try earlier.until(later, settings);
    defer until_handle.deinit();
    try std.testing.expectEqual(Sign.positive, Sign.fromCApi(abi.c.temporal_rs_Duration_sign(until_handle.ptr)));
    try std.testing.expectEqual(@as(i64, 1), abi.c.temporal_rs_Duration_hours(until_handle.ptr));

    var since_handle = try later.since(earlier, settings);
    defer since_handle.deinit();
    try std.testing.expectEqual(Sign.positive, Sign.fromCApi(abi.c.temporal_rs_Duration_sign(since_handle.ptr)));
    try std.testing.expectEqual(@as(i64, 1), abi.c.temporal_rs_Duration_hours(since_handle.ptr));
}

test since {
    const earlier = try Instant.fromEpochMilliseconds(0);
    defer earlier.deinit();
    const later = try Instant.fromEpochMilliseconds(3_600_000);
    defer later.deinit();

    const settings = abi.c.DifferenceSettings{
        .largest_unit = abi.toUnitOption(Unit.hour.toCApi()),
        .smallest_unit = abi.toUnitOption(Unit.second.toCApi()),
        .rounding_mode = abi.toRoundingModeOption(RoundingMode.trunc.toCApi()),
        .increment = abi.toOption(abi.c.OptionU32, null),
    };

    var until_handle = try earlier.until(later, settings);
    defer until_handle.deinit();
    try std.testing.expectEqual(Sign.positive, Sign.fromCApi(abi.c.temporal_rs_Duration_sign(until_handle.ptr)));
    try std.testing.expectEqual(@as(i64, 1), abi.c.temporal_rs_Duration_hours(until_handle.ptr));

    var since_handle = try later.since(earlier, settings);
    defer since_handle.deinit();
    try std.testing.expectEqual(Sign.positive, Sign.fromCApi(abi.c.temporal_rs_Duration_sign(since_handle.ptr)));
    try std.testing.expectEqual(@as(i64, 1), abi.c.temporal_rs_Duration_hours(since_handle.ptr));
}

test round {
    const inst = try Instant.fromEpochNanoseconds(1_609_459_245_123_456_789);
    defer inst.deinit();

    const opts = abi.c.RoundingOptions{
        .largest_unit = abi.toUnitOption(null),
        .smallest_unit = abi.toUnitOption(Unit.second.toCApi()),
        .rounding_mode = abi.toRoundingModeOption(RoundingMode.half_expand.toCApi()),
        .increment = abi.toOption(abi.c.OptionU32, null),
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

    // Default options
    const instant_str = try inst.toString(allocator, .{});
    defer allocator.free(instant_str);
    try std.testing.expectEqualStrings(instant_str, "2024-01-01T00:00:00Z");

    // With fractional_second_digits
    const with_precision = try inst.toString(allocator, .{ .fractional_second_digits = 3 });
    defer allocator.free(with_precision);
    // Output should include milliseconds precision

    // With smallest_unit
    const with_unit = try inst.toString(allocator, .{ .smallest_unit = .second });
    defer allocator.free(with_unit);
    // Output should truncate to seconds
}
