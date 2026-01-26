const std = @import("std");
const abi = @import("abi.zig");
const temporal = @import("temporal.zig");

const Duration = @import("Duration.zig");

const Instant = @This();

pub const Unit = temporal.Unit;
pub const RoundingMode = temporal.RoundingMode;
pub const Sign = temporal.Sign;
pub const RoundingOptions = temporal.RoundingOptions;
pub const DifferenceSettings = temporal.DifferenceSettings;

/// Time zone identifier for Temporal operations
pub const TimeZone = struct {
    _inner: abi.c.TimeZone,

    pub fn init(id: []const u8) TimeZone {
        const view = abi.toDiplomatStringView(id);
        return .{ ._inner = .{ .id = view } };
    }

    fn toCApi(self: TimeZone) abi.c.TimeZone {
        return self._inner;
    }
};

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
    time_zone: ?TimeZone = null,
};

_inner: *abi.c.Instant,
epoch_milliseconds: i64,
epoch_nanoseconds: i128,

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

/// Parse an ISO 8601 string (Temporal.Instant.from) or from another Temporal.Instant.
pub fn from(info: anytype) !Instant {
    const T = @TypeOf(info);

    if (T == Instant) return info.clone();

    // Handle string types (both literals and slices)
    const type_info = @typeInfo(T);
    switch (type_info) {
        .pointer => {
            const ptr = type_info.pointer;
            const ChildType = switch (@typeInfo(ptr.child)) {
                .array => |arr| arr.child,
                else => ptr.child,
            };

            if (ChildType == u8) return fromUtf8(info);
            if (ChildType == u16) return fromUtf16(info);
        },
        else => @compileError("from() expects an Instant, []const u8, or []const u16"),
    }
}

/// Parse an ISO 8601 UTF-16 string (Temporal.Instant.from).
inline fn fromUtf16(text: []const u16) !Instant {
    const view = abi.toDiplomatString16View(text);
    return wrapInstant(abi.c.temporal_rs_Instant_from_utf16(view));
}

/// Parse an ISO 8601 UTF-16 string (Temporal.Instant.from).
inline fn fromUtf8(text: []const u8) !Instant {
    const view = abi.toDiplomatStringView(text);
    return wrapInstant(abi.c.temporal_rs_Instant_from_utf8(view));
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
pub fn until(self: Instant, other: Instant, settings: DifferenceSettings) !Duration {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_Instant_until(self._inner, other._inner, settings.toCApi()))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Difference since another instant (Temporal.Instant.prototype.since).
pub fn since(self: Instant, other: Instant, settings: DifferenceSettings) !Duration {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_Instant_since(self._inner, other._inner, settings.toCApi()))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Round this instant (Temporal.Instant.prototype.round).
pub fn round(self: Instant, options: RoundingOptions) !Instant {
    return wrapInstant(abi.c.temporal_rs_Instant_round(self._inner, options.toCApi()));
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
    const zone_opt = if (opts.time_zone) |tz| abi.toTimeZoneOption(tz._inner) else abi.toTimeZoneOption(null);
    const rounding = optsToRounding(opts);

    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = abi.c.temporal_rs_Instant_to_ixdtf_string_with_compiled_data(self._inner, zone_opt, rounding, &write.inner);
    try handleVoidResult(res);

    return try write.toOwnedSlice();
}

/// Convert to string using an explicit provider.
fn toStringWithProvider(self: Instant, allocator: std.mem.Allocator, provider: *const abi.c.Provider, opts: ToStringOptions) ![]u8 {
    const zone_opt = if (opts.time_zone) |tz| abi.toTimeZoneOption(tz._inner) else abi.toTimeZoneOption(null);
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

/// Convert to a locale string representation.
/// Per Temporal spec, toLocaleString returns a formatted string without taking locale/options parameters.
/// This uses auto precision for fractional seconds.
pub fn toLocaleString(self: Instant, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Convert to ZonedDateTime using built-in provider (Temporal.Instant.prototype.toZonedDateTimeISO).
pub fn toZonedDateTimeISO(self: Instant, zone: TimeZone) !ZonedDateTime {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_Instant_to_zoned_date_time_iso(self._inner, zone._inner))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Convert to ZonedDateTime using an explicit provider.
fn toZonedDateTimeIsoWithProvider(self: Instant, zone: TimeZone, provider: *const abi.c.Provider) !ZonedDateTime {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_Instant_to_zoned_date_time_iso_with_provider(self._inner, zone._inner, provider))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
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
    const ptr = (try abi.extractResult(res)) orelse return abi.TemporalError.Generic;
    return .{
        ._inner = ptr,
        .epoch_milliseconds = abi.c.temporal_rs_Instant_epoch_milliseconds(ptr),
        .epoch_nanoseconds = abi.fromI128Nanoseconds(abi.c.temporal_rs_Instant_epoch_nanoseconds(ptr)),
    };
}

fn handleVoidResult(res: anytype) !void {
    _ = try abi.extractResult(res);
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

// --- Forward declarations -----------------------------------------------------

const ZonedDateTime = struct {
    _inner: *abi.c.ZonedDateTime,

    pub fn deinit(self: ZonedDateTime) void {
        abi.c.temporal_rs_ZonedDateTime_destroy(self._inner);
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

    try std.testing.expectError(error.RangeError, Instant.fromEpochNanoseconds(max_ns + 1));
    try std.testing.expectError(error.RangeError, Instant.fromEpochNanoseconds(min_ns - 1));
}

test from {
    // Test parsing from UTF-8 string
    const inst = try Instant.from("2024-03-15T14:30:45.123Z");
    defer inst.deinit();
    try std.testing.expectEqual(@as(i64, 1_710_513_045_123), inst.epoch_milliseconds);

    // Test creating from another Instant
    const inst2 = try Instant.from(inst);
    defer inst2.deinit();
    try std.testing.expectEqual(inst.epoch_milliseconds, inst2.epoch_milliseconds);
    try std.testing.expectEqual(inst.epoch_nanoseconds, inst2.epoch_nanoseconds);
    try std.testing.expect(Instant.equals(inst, inst2));
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

    const settings = DifferenceSettings{
        .largest_unit = .hour,
        .smallest_unit = .second,
        .rounding_mode = .trunc,
        .rounding_increment = null,
    };

    const until_dur = try earlier.until(later, settings);
    defer until_dur.deinit();
    try std.testing.expectEqual(Sign.positive, until_dur.sign());
    try std.testing.expectEqual(@as(i64, 1), until_dur.hours());

    const since_dur = try later.since(earlier, settings);
    defer since_dur.deinit();
    try std.testing.expectEqual(Sign.positive, since_dur.sign());
    try std.testing.expectEqual(@as(i64, 1), since_dur.hours());
}

test since {
    const earlier = try Instant.fromEpochMilliseconds(0);
    defer earlier.deinit();
    const later = try Instant.fromEpochMilliseconds(3_600_000);
    defer later.deinit();

    const settings = DifferenceSettings{
        .largest_unit = .hour,
        .smallest_unit = .second,
        .rounding_mode = .trunc,
        .rounding_increment = null,
    };

    const until_dur = try earlier.until(later, settings);
    defer until_dur.deinit();
    try std.testing.expectEqual(Sign.positive, until_dur.sign());
    try std.testing.expectEqual(@as(i64, 1), until_dur.hours());

    const since_dur = try later.since(earlier, settings);
    defer since_dur.deinit();
    try std.testing.expectEqual(Sign.positive, since_dur.sign());
    try std.testing.expectEqual(@as(i64, 1), since_dur.hours());
}

test round {
    const inst = try Instant.fromEpochNanoseconds(1_609_459_245_123_456_789);
    defer inst.deinit();

    const opts = RoundingOptions{
        .largest_unit = null,
        .smallest_unit = .second,
        .rounding_mode = .half_expand,
        .rounding_increment = null,
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

test toLocaleString {
    const epoch_ns: i128 = 1704067200000000000; // 2024-01-01 00:00:00 UTC
    const inst = try Instant.init(epoch_ns);
    defer inst.deinit();

    const allocator = std.testing.allocator;

    // toLocaleString should return a formatted string (same as toString with defaults)
    const locale_str = try inst.toLocaleString(allocator);
    defer allocator.free(locale_str);
    try std.testing.expectEqualStrings(locale_str, "2024-01-01T00:00:00Z");

    // Test with a different instant with fractional seconds
    const inst2 = try Instant.fromEpochNanoseconds(1704067200123456789);
    defer inst2.deinit();

    const locale_str2 = try inst2.toLocaleString(allocator);
    defer allocator.free(locale_str2);
    // Auto precision should include fractional seconds
    try std.testing.expect(std.mem.containsAtLeast(u8, locale_str2, 1, "2024-01-01T00:00:00"));
}
