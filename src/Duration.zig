const std = @import("std");
const abi = @import("abi.zig");
const c = abi.c;

const Duration = @This();

_inner: *c.Duration,

/// Construct a Duration from years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, and nanoseconds.
/// Equivalent to `Temporal.Duration.from()` or the constructor.
pub fn init(
    years_val: i64,
    months_val: i64,
    weeks_val: i64,
    days_val: i64,
    hours_val: i64,
    minutes_val: i64,
    seconds_val: i64,
    milliseconds_val: i64,
    microseconds_val: f64,
    nanoseconds_val: f64,
) !Duration {
    return wrapDuration(c.temporal_rs_Duration_try_new(
        years_val,
        months_val,
        weeks_val,
        days_val,
        hours_val,
        minutes_val,
        seconds_val,
        milliseconds_val,
        microseconds_val,
        nanoseconds_val,
    ));
}

/// Parse an ISO 8601 duration string (Temporal.Duration.from).
pub fn from(text: []const u8) !Duration {
    const view = abi.toDiplomatStringView(text);
    return wrapDuration(c.temporal_rs_Duration_from_utf8(view));
}

/// Parse an ISO 8601 UTF-16 duration string.
fn fromUtf16(text: []const u16) !Duration {
    const view = abi.toDiplomatString16View(text);
    return wrapDuration(c.temporal_rs_Duration_from_utf16(view));
}

/// Create a Duration from a partial duration (where some fields may be omitted).
fn fromPartialDuration(partial: PartialDuration) !Duration {
    return wrapDuration(c.temporal_rs_Duration_from_partial_duration(partial));
}

/// Check if the time portion of the duration is within valid ranges.
fn isTimeWithinRange(self: Duration) bool {
    return c.temporal_rs_Duration_is_time_within_range(self._inner);
}

/// Get the years component of the duration.
pub fn years(self: Duration) i64 {
    return c.temporal_rs_Duration_years(self._inner);
}

/// Get the months component of the duration.
pub fn months(self: Duration) i64 {
    return c.temporal_rs_Duration_months(self._inner);
}

/// Get the weeks component of the duration.
pub fn weeks(self: Duration) i64 {
    return c.temporal_rs_Duration_weeks(self._inner);
}

/// Get the days component of the duration.
pub fn days(self: Duration) i64 {
    return c.temporal_rs_Duration_days(self._inner);
}

/// Get the hours component of the duration.
pub fn hours(self: Duration) i64 {
    return c.temporal_rs_Duration_hours(self._inner);
}

/// Get the minutes component of the duration.
pub fn minutes(self: Duration) i64 {
    return c.temporal_rs_Duration_minutes(self._inner);
}

/// Get the seconds component of the duration.
pub fn seconds(self: Duration) i64 {
    return c.temporal_rs_Duration_seconds(self._inner);
}

/// Get the milliseconds component of the duration.
pub fn milliseconds(self: Duration) i64 {
    return c.temporal_rs_Duration_milliseconds(self._inner);
}

/// Get the microseconds component of the duration.
pub fn microseconds(self: Duration) f64 {
    return c.temporal_rs_Duration_microseconds(self._inner);
}

/// Get the nanoseconds component of the duration.
pub fn nanoseconds(self: Duration) f64 {
    return c.temporal_rs_Duration_nanoseconds(self._inner);
}

/// Get the sign of the duration: positive (1), zero (0), or negative (-1).
pub fn sign(self: Duration) Sign {
    return @as(Sign, @enumFromInt(c.temporal_rs_Duration_sign(self._inner)));
}

/// Check if the duration is zero (all fields are zero).
pub fn blank(self: Duration) bool {
    return c.temporal_rs_Duration_is_zero(self._inner);
}

/// Returns a new Duration with the absolute value (all components positive).
pub fn abs(self: Duration) Duration {
    const ptr: *c.Duration = c.temporal_rs_Duration_abs(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Returns a new Duration with all components negated.
pub fn negated(self: Duration) Duration {
    const ptr: *c.Duration = c.temporal_rs_Duration_negated(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Add two durations together (Temporal.Duration.prototype.add).
pub fn add(self: Duration, other: Duration) !Duration {
    return wrapDuration(c.temporal_rs_Duration_add(self._inner, other._inner));
}

/// Subtract another duration from this one (Temporal.Duration.prototype.subtract).
pub fn subtract(self: Duration, other: Duration) !Duration {
    return wrapDuration(c.temporal_rs_Duration_subtract(self._inner, other._inner));
}

/// Round the duration according to the specified options (Temporal.Duration.prototype.round).
pub fn round(self: Duration, options: RoundingOptions, relative_to: RelativeTo) !Duration {
    return wrapDuration(c.temporal_rs_Duration_round(self._inner, options, relative_to));
}

/// Round the duration with an explicit provider.
fn roundWithProvider(self: Duration, options: RoundingOptions, relative_to: RelativeTo, provider: *const c.Provider) !Duration {
    return wrapDuration(c.temporal_rs_Duration_round_with_provider(self._inner, options, relative_to, provider));
}

/// Compare two durations (Temporal.Duration.compare).
pub fn compare(self: Duration, other: Duration, relative_to: RelativeTo) !i8 {
    const res = c.temporal_rs_Duration_compare(self._inner, other._inner, relative_to);
    return abi.success(res) orelse return error.TemporalError;
}

/// Compare two durations with an explicit provider.
fn compareWithProvider(self: Duration, other: Duration, relative_to: RelativeTo, provider: *const c.Provider) !i8 {
    const res = c.temporal_rs_Duration_compare_with_provider(self._inner, other._inner, relative_to, provider);
    return abi.success(res) orelse return error.TemporalError;
}

/// Get the total value of the duration in the specified unit (Temporal.Duration.prototype.total).
pub fn total(self: Duration, unit: Unit, relative_to: RelativeTo) !f64 {
    const res = c.temporal_rs_Duration_total(self._inner, @intFromEnum(unit), relative_to);
    return abi.success(res) orelse return error.TemporalError;
}

/// Get the total value of the duration with an explicit provider.
fn totalWithProvider(self: Duration, unit: Unit, relative_to: RelativeTo, provider: *const c.Provider) !f64 {
    const res = c.temporal_rs_Duration_total_with_provider(self._inner, @intFromEnum(unit), relative_to, provider);
    return abi.success(res) orelse return error.TemporalError;
}

/// Convert to string (Temporal.Duration.prototype.toString); caller owns returned slice.
pub fn toString(self: Duration, allocator: std.mem.Allocator, options: ToStringRoundingOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = c.temporal_rs_Duration_to_string(self._inner, options, &write.inner);
    try handleVoidResult(res);

    return try write.toOwnedSlice();
}

pub fn toJSON(self: Duration, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, defaultToStringRoundingOptions());
}

pub fn toLocaleString(self: Duration, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

/// Clone the underlying duration.
fn clone(self: Duration) Duration {
    const ptr: *c.Duration = c.temporal_rs_Duration_clone(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

pub fn deinit(self: Duration) void {
    c.temporal_rs_Duration_destroy(self._inner);
}

// --- Helpers -----------------------------------------------------------------

fn handleVoidResult(res: anytype) !void {
    _ = abi.success(res) orelse return error.TemporalError;
}

fn wrapDuration(res: anytype) !Duration {
    const ptr = (abi.success(res) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

fn defaultToStringRoundingOptions() ToStringRoundingOptions {
    return abi.to_string_rounding_options_auto;
}

// --- Public helper types -----------------------------------------------------

/// Options for Duration.toString()
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toString
pub const ToStringOptions = struct {
    /// Specifies the number of fractional seconds digits to display.
    fractional_second_digits: ?u8 = null,

    /// Specifies how to round off fractional second digits.
    /// Defaults to "trunc" (truncate).
    rounding_mode: ?RoundingMode = null,

    /// Specifies the smallest unit to include in the output.
    smallest_unit: ?Unit = null,
};

pub const PartialDuration = c.PartialDuration;

/// Relative-to context for duration operations.
pub const RelativeTo = extern struct {
    plain_date: ?*c.PlainDate,
    zoned_date_time: ?*c.ZonedDateTime,
};

// --- Public type aliases and enums ------------------------------------------

const OptionU8 = c.OptionU8;
const OptionU32 = c.OptionU32;
const OptionI64 = c.OptionI64;
const OptionF64 = c.OptionF64;
const Precision = c.Precision;
const Unit_option = c.Unit_option;
const RoundingMode_option = c.RoundingMode_option;

/// Time unit for Temporal operations.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal
pub const Unit = enum(c_uint) {
    auto = c.Unit_Auto,
    nanosecond = c.Unit_Nanosecond,
    microsecond = c.Unit_Microsecond,
    millisecond = c.Unit_Millisecond,
    second = c.Unit_Second,
    minute = c.Unit_Minute,
    hour = c.Unit_Hour,
    day = c.Unit_Day,
    week = c.Unit_Week,
    month = c.Unit_Month,
    year = c.Unit_Year,
};

/// Rounding mode for Temporal operations.
/// See: https://tc39.es/ecma402/#table-sanctioned-single-unit-identifiers
pub const RoundingMode = enum(c_uint) {
    /// Round toward positive infinity
    ceil = c.RoundingMode_Ceil,
    /// Round toward negative infinity
    floor = c.RoundingMode_Floor,
    /// Round away from zero
    expand = c.RoundingMode_Expand,
    /// Round toward zero (truncate)
    trunc = c.RoundingMode_Trunc,
    /// Round half toward positive infinity
    half_ceil = c.RoundingMode_HalfCeil,
    /// Round half toward negative infinity
    half_floor = c.RoundingMode_HalfFloor,
    /// Round half away from zero
    half_expand = c.RoundingMode_HalfExpand,
    /// Round half toward zero
    half_trunc = c.RoundingMode_HalfTrunc,
    /// Round half to even (banker's rounding)
    half_even = c.RoundingMode_HalfEven,
};

pub const Sign = enum(c_int) {
    positive = c.Sign_Positive,
    zero = c.Sign_Zero,
    negative = c.Sign_Negative,
};

pub const RoundingOptions = c.RoundingOptions;
pub const ToStringRoundingOptions = c.ToStringRoundingOptions;

// --- Tests -------------------------------------------------------------------

test init {
    // Create a simple duration: 1 hour, 30 minutes
    const dur = try Duration.init(0, 0, 0, 0, 1, 30, 0, 0, 0, 0);
    defer dur.deinit();

    try std.testing.expectEqual(@as(i64, 1), dur.hours());
    try std.testing.expectEqual(@as(i64, 30), dur.minutes());
    try std.testing.expectEqual(@as(i64, 0), dur.seconds());
}

test from {
    // P1Y2M3DT4H5M6.789S = 1 year, 2 months, 3 days, 4 hours, 5 minutes, 6.789 seconds
    const dur = try Duration.from("P1Y2M3DT4H5M6.789S");
    defer dur.deinit();

    try std.testing.expectEqual(@as(i64, 1), dur.years());
    try std.testing.expectEqual(@as(i64, 2), dur.months());
    try std.testing.expectEqual(@as(i64, 3), dur.days());
    try std.testing.expectEqual(@as(i64, 4), dur.hours());
    try std.testing.expectEqual(@as(i64, 5), dur.minutes());
    try std.testing.expectEqual(@as(i64, 6), dur.seconds());

    // from-time
    // PT2H30M = 2 hours, 30 minutes
    const dur_time = try Duration.from("PT2H30M");
    defer dur_time.deinit();

    try std.testing.expectEqual(@as(i64, 0), dur_time.years());
    try std.testing.expectEqual(@as(i64, 2), dur_time.hours());
    try std.testing.expectEqual(@as(i64, 30), dur_time.minutes());

    // from-negative
    const dur_negative = try Duration.from("-P1D");
    defer dur_negative.deinit();

    try std.testing.expectEqual(@as(i64, -1), dur_negative.days());
    try std.testing.expectEqual(Sign.negative, dur_negative.sign());
}

test blank {
    const dur = try Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer dur.deinit();

    try std.testing.expect(dur.blank());
    try std.testing.expectEqual(Sign.zero, dur.sign());
}

test add {
    const dur1 = try Duration.from("PT1H");
    defer dur1.deinit();
    const dur2 = try Duration.from("PT30M");
    defer dur2.deinit();

    const result = try dur1.add(dur2);
    defer result.deinit();

    try std.testing.expectEqual(@as(i64, 1), result.hours());
    try std.testing.expectEqual(@as(i64, 30), result.minutes());
}

test subtract {
    const dur1 = try Duration.from("PT2H");
    defer dur1.deinit();
    const dur2 = try Duration.from("PT30M");
    defer dur2.deinit();

    const result = try dur1.subtract(dur2);
    defer result.deinit();

    try std.testing.expectEqual(@as(i64, 1), result.hours());
    try std.testing.expectEqual(@as(i64, 30), result.minutes());
}

test abs {
    const dur = try Duration.from("-PT1H30M");
    defer dur.deinit();

    const abs_dur = dur.abs();
    defer abs_dur.deinit();

    try std.testing.expectEqual(@as(i64, 1), abs_dur.hours());
    try std.testing.expectEqual(@as(i64, 30), abs_dur.minutes());
    try std.testing.expectEqual(Sign.positive, abs_dur.sign());
}

test negated {
    const dur = try Duration.from("PT1H");
    defer dur.deinit();

    const neg = dur.negated();
    defer neg.deinit();

    try std.testing.expectEqual(@as(i64, -1), neg.hours());
    try std.testing.expectEqual(Sign.negative, neg.sign());
}

test toString {
    const dur = try Duration.from("P1Y2M3DT4H5M6S");
    defer dur.deinit();

    const allocator = std.testing.allocator;
    const str = try dur.toString(allocator, defaultToStringRoundingOptions());
    defer allocator.free(str);

    // Should output ISO 8601 duration format
    try std.testing.expect(str.len > 0);
}

test fromPartialDuration {
    const empty_i64 = abi.toOption(c.OptionI64, null);
    const empty_f64 = abi.toOption(c.OptionF64, null);

    const partial = c.PartialDuration{
        .years = empty_i64,
        .months = empty_i64,
        .weeks = empty_i64,
        .days = empty_i64,
        .hours = .{ .is_ok = true, .unnamed_0 = .{ .ok = 3 } },
        .minutes = .{ .is_ok = true, .unnamed_0 = .{ .ok = 45 } },
        .seconds = empty_i64,
        .milliseconds = empty_i64,
        .microseconds = empty_f64,
        .nanoseconds = empty_f64,
    };

    const dur = try Duration.fromPartialDuration(partial);
    defer dur.deinit();

    try std.testing.expectEqual(@as(i64, 3), dur.hours());
    try std.testing.expectEqual(@as(i64, 45), dur.minutes());
    try std.testing.expectEqual(@as(i64, 0), dur.days());
}

test isTimeWithinRange {
    const dur = try Duration.from("PT23H59M59S");
    defer dur.deinit();

    try std.testing.expect(dur.isTimeWithinRange());
}

test clone {
    const dur = try Duration.from("PT1H");
    defer dur.deinit();

    const cloned = dur.clone();
    defer cloned.deinit();

    try std.testing.expectEqual(dur.hours(), cloned.hours());
}
