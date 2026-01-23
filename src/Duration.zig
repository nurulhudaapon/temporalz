const std = @import("std");

/// The Zig implementation of `Temporal.Duration`.
///
/// Represents a span of time such as "2 hours and 30 minutes" or "3 years, 2 months".
/// Unlike `Instant` which represents a specific moment in time, Duration represents
/// the amount of time between two moments.
///
/// A Duration consists of two categories of components:
/// - Date components: years, months, weeks, and days
/// - Time components: hours, minutes, seconds, and subsecond units (nanosecond precision)
///
/// Note that date arithmetic can be complex. For example, adding "1 month" to January 31st
/// could result in February 28th (non-leap year), February 29th (leap year), or March 3rd
/// (if you overflow February), depending on the calendar system and overflow handling.
///
/// ## Examples
///
/// ### Creating durations
///
/// ```zig
/// const Duration = @import("Duration.zig");
///
/// // Create a duration with specific components
/// // 2 weeks and 3 days, no time components
/// const vacation_duration = try Duration.init(
///     0, 0, 2, 3,    // years, months, weeks, days
///     0, 0, 0,       // hours, minutes, seconds
///     0, 0, 0        // milliseconds, microseconds, nanoseconds
/// );
/// defer vacation_duration.deinit();
///
/// try std.testing.expectEqual(@as(i64, 2), vacation_duration.weeks());
/// try std.testing.expectEqual(@as(i64, 3), vacation_duration.days());
/// ```
///
/// ### Parsing ISO 8601 duration strings
///
/// ```zig
/// const Duration = @import("Duration.zig");
///
/// // Complex duration with multiple components
/// const complex = try Duration.from("P1Y2M3DT4H5M6.789S");
/// defer complex.deinit();
/// try std.testing.expectEqual(@as(i64, 1), complex.years());
/// try std.testing.expectEqual(@as(i64, 2), complex.months());
/// try std.testing.expectEqual(@as(i64, 3), complex.days());
/// try std.testing.expectEqual(@as(i64, 4), complex.hours());
/// try std.testing.expectEqual(@as(i64, 5), complex.minutes());
/// try std.testing.expectEqual(@as(i64, 6), complex.seconds());
///
/// // Time-only duration
/// const movie_length = try Duration.from("PT2H30M");
/// defer movie_length.deinit();
/// try std.testing.expectEqual(@as(i64, 2), movie_length.hours());
/// try std.testing.expectEqual(@as(i64, 30), movie_length.minutes());
///
/// // Negative durations
/// const negative = try Duration.from("-P1D");
/// defer negative.deinit();
/// try std.testing.expectEqual(@as(i64, -1), negative.days());
/// ```
///
/// ### Duration arithmetic
///
/// ```zig
/// const Duration = @import("Duration.zig");
///
/// const commute_time = try Duration.from("PT45M");
/// defer commute_time.deinit();
/// const lunch_break = try Duration.from("PT1H");
/// defer lunch_break.deinit();
///
/// // Add durations together
/// const total_time = try commute_time.add(lunch_break);
/// defer total_time.deinit();
/// try std.testing.expectEqual(@as(i64, 1), total_time.hours());    // Results in 1 hour 45 minutes
/// try std.testing.expectEqual(@as(i64, 45), total_time.minutes());
///
/// // Subtract duration components
/// const shortened = try lunch_break.subtract(try Duration.from("PT15M"));
/// defer shortened.deinit();
/// try std.testing.expectEqual(@as(i64, 45), shortened.minutes());
/// ```
///
/// ### Working with partial durations
///
/// ```zig
/// const Duration = @import("Duration.zig");
///
/// var partial = Duration.PartialDuration.empty();
/// partial = partial.withHours(3);
/// partial = partial.withMinutes(45);
///
/// const duration = try Duration.fromPartialDuration(partial);
/// defer duration.deinit();
/// try std.testing.expectEqual(@as(i64, 3), duration.hours());
/// try std.testing.expectEqual(@as(i64, 45), duration.minutes());
/// try std.testing.expectEqual(@as(i64, 0), duration.days()); // other fields default to 0
/// ```
///
/// ### Duration properties
///
/// ```zig
/// const Duration = @import("Duration.zig");
///
/// const duration = try Duration.from("P1Y2M3D");
/// defer duration.deinit();
///
/// // Check if duration is zero
/// try std.testing.expect(!duration.isZero());
///
/// // Get the sign of the duration
/// const sign_val = duration.sign();
///
/// // Get absolute value
/// const abs_duration = duration.abs();
/// defer abs_duration.deinit();
/// try std.testing.expectEqual(@as(i64, 1), abs_duration.years());
/// try std.testing.expectEqual(@as(i64, 2), abs_duration.months());
/// try std.testing.expectEqual(@as(i64, 3), abs_duration.days());
///
/// // Negate duration
/// const negated_dur = duration.negated();
/// defer negated_dur.deinit();
/// try std.testing.expectEqual(@as(i64, -1), negated_dur.years());
/// try std.testing.expectEqual(@as(i64, -2), negated_dur.months());
/// try std.testing.expectEqual(@as(i64, -3), negated_dur.days());
/// ```
///
/// ## Reference
///
/// For more information, see the [MDN documentation][mdn-duration].
///
/// [mdn-duration]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration
const Duration = @This();

_inner: *CDuration,

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
    return wrapDuration(temporal_rs_Duration_try_new(
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
    const view = DiplomatStringView{ .data = text.ptr, .len = text.len };
    return wrapDuration(temporal_rs_Duration_from_utf8(view));
}

/// Parse an ISO 8601 UTF-16 duration string.
fn fromUtf16(text: []const u16) !Duration {
    const view = DiplomatString16View{ .data = text.ptr, .len = text.len };
    return wrapDuration(temporal_rs_Duration_from_utf16(view));
}

/// Create a Duration from a partial duration (where some fields may be omitted).
fn fromPartialDuration(partial: PartialDuration) !Duration {
    return wrapDuration(temporal_rs_Duration_from_partial_duration(partial));
}

/// Check if the time portion of the duration is within valid ranges.
fn isTimeWithinRange(self: Duration) bool {
    return temporal_rs_Duration_is_time_within_range(self._inner);
}

/// Get the years component of the duration.
pub fn years(self: Duration) i64 {
    return temporal_rs_Duration_years(self._inner);
}

/// Get the months component of the duration.
pub fn months(self: Duration) i64 {
    return temporal_rs_Duration_months(self._inner);
}

/// Get the weeks component of the duration.
pub fn weeks(self: Duration) i64 {
    return temporal_rs_Duration_weeks(self._inner);
}

/// Get the days component of the duration.
pub fn days(self: Duration) i64 {
    return temporal_rs_Duration_days(self._inner);
}

/// Get the hours component of the duration.
pub fn hours(self: Duration) i64 {
    return temporal_rs_Duration_hours(self._inner);
}

/// Get the minutes component of the duration.
pub fn minutes(self: Duration) i64 {
    return temporal_rs_Duration_minutes(self._inner);
}

/// Get the seconds component of the duration.
pub fn seconds(self: Duration) i64 {
    return temporal_rs_Duration_seconds(self._inner);
}

/// Get the milliseconds component of the duration.
pub fn milliseconds(self: Duration) i64 {
    return temporal_rs_Duration_milliseconds(self._inner);
}

/// Get the microseconds component of the duration.
pub fn microseconds(self: Duration) f64 {
    return temporal_rs_Duration_microseconds(self._inner);
}

/// Get the nanoseconds component of the duration.
pub fn nanoseconds(self: Duration) f64 {
    return temporal_rs_Duration_nanoseconds(self._inner);
}

/// Get the sign of the duration: positive (1), zero (0), or negative (-1).
pub fn sign(self: Duration) Sign {
    return temporal_rs_Duration_sign(self._inner);
}

/// Check if the duration is zero (all fields are zero).
pub fn blank(self: Duration) bool {
    return temporal_rs_Duration_is_zero(self._inner);
}

/// Returns a new Duration with the absolute value (all components positive).
pub fn abs(self: Duration) Duration {
    const ptr = temporal_rs_Duration_abs(self._inner);
    return .{ ._inner = ptr };
}

/// Returns a new Duration with all components negated.
pub fn negated(self: Duration) Duration {
    const ptr = temporal_rs_Duration_negated(self._inner);
    return .{ ._inner = ptr };
}

/// Add two durations together (Temporal.Duration.prototype.add).
pub fn add(self: Duration, other: Duration) !Duration {
    return wrapDuration(temporal_rs_Duration_add(self._inner, other._inner));
}

/// Subtract another duration from this one (Temporal.Duration.prototype.subtract).
pub fn subtract(self: Duration, other: Duration) !Duration {
    return wrapDuration(temporal_rs_Duration_subtract(self._inner, other._inner));
}

/// Round the duration according to the specified options (Temporal.Duration.prototype.round).
pub fn round(self: Duration, options: RoundingOptions, relative_to: RelativeTo) !Duration {
    return wrapDuration(temporal_rs_Duration_round(self._inner, options, relative_to));
}

/// Round the duration with an explicit provider.
fn roundWithProvider(self: Duration, options: RoundingOptions, relative_to: RelativeTo, provider: *const Provider) !Duration {
    return wrapDuration(temporal_rs_Duration_round_with_provider(self._inner, options, relative_to, provider));
}

/// Compare two durations (Temporal.Duration.compare).
pub fn compare(self: Duration, other: Duration, relative_to: RelativeTo) !i8 {
    const res = temporal_rs_Duration_compare(self._inner, other._inner, relative_to);
    if (!res.is_ok) return error.TemporalError;
    return res.result.ok;
}

/// Compare two durations with an explicit provider.
fn compareWithProvider(self: Duration, other: Duration, relative_to: RelativeTo, provider: *const Provider) !i8 {
    const res = temporal_rs_Duration_compare_with_provider(self._inner, other._inner, relative_to, provider);
    if (!res.is_ok) return error.TemporalError;
    return res.result.ok;
}

/// Get the total value of the duration in the specified unit (Temporal.Duration.prototype.total).
pub fn total(self: Duration, unit: Unit, relative_to: RelativeTo) !f64 {
    const res = temporal_rs_Duration_total(self._inner, unit, relative_to);
    if (!res.is_ok) return error.TemporalError;
    return res.result.ok;
}

/// Get the total value of the duration with an explicit provider.
fn totalWithProvider(self: Duration, unit: Unit, relative_to: RelativeTo, provider: *const Provider) !f64 {
    const res = temporal_rs_Duration_total_with_provider(self._inner, unit, relative_to, provider);
    if (!res.is_ok) return error.TemporalError;
    return res.result.ok;
}

/// Convert to string (Temporal.Duration.prototype.toString); caller owns returned slice.
pub fn toString(self: Duration, allocator: std.mem.Allocator, options: ToStringRoundingOptions) ![]u8 {
    const writer = diplomat_buffer_write_create(128);
    defer diplomat_buffer_write_destroy(writer);

    const res = temporal_rs_Duration_to_string(self._inner, options, writer);
    try handleVoidResult(res);

    const len = diplomat_buffer_write_len(writer);
    const source = diplomat_buffer_write_get_bytes(writer)[0..len];

    const out = try allocator.alloc(u8, len);
    std.mem.copyForwards(u8, out, source);
    return out;
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
    const ptr = temporal_rs_Duration_clone(self._inner);
    return .{ ._inner = ptr };
}

pub fn deinit(self: Duration) void {
    temporal_rs_Duration_destroy(self._inner);
}

// --- Helpers -----------------------------------------------------------------

fn wrapDuration(res: DurationResult) !Duration {
    if (!res.is_ok) return error.TemporalError;
    const ptr = res.result.ok orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

fn handleVoidResult(res: VoidResult) !void {
    if (!res.is_ok) return error.TemporalError;
}

fn defaultToStringRoundingOptions() ToStringRoundingOptions {
    return .{
        .precision = .{ .is_minute = false, .precision = OptionU8{ .ok = 0, .is_ok = false } },
        .smallest_unit = Unit_option{ .ok = .auto, .is_ok = false },
        .rounding_mode = RoundingMode_option{ .ok = .trunc, .is_ok = false },
    };
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

/// A partial duration where some or all fields may be omitted.
pub const PartialDuration = extern struct {
    years: OptionI64,
    months: OptionI64,
    weeks: OptionI64,
    days: OptionI64,
    hours: OptionI64,
    minutes: OptionI64,
    seconds: OptionI64,
    milliseconds: OptionI64,
    microseconds: OptionI128,
    nanoseconds: OptionI128,

    pub fn empty() PartialDuration {
        return .{
            .years = .{ .ok = 0, .is_ok = false },
            .months = .{ .ok = 0, .is_ok = false },
            .weeks = .{ .ok = 0, .is_ok = false },
            .days = .{ .ok = 0, .is_ok = false },
            .hours = .{ .ok = 0, .is_ok = false },
            .minutes = .{ .ok = 0, .is_ok = false },
            .seconds = .{ .ok = 0, .is_ok = false },
            .milliseconds = .{ .ok = 0, .is_ok = false },
            .microseconds = .{ .ok = 0, .is_ok = false },
            .nanoseconds = .{ .ok = 0, .is_ok = false },
        };
    }

    pub fn withYears(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.years = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withMonths(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.months = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withWeeks(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.weeks = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withDays(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.days = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withHours(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.hours = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withMinutes(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.minutes = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withSeconds(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.seconds = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withMilliseconds(self: PartialDuration, value: i64) PartialDuration {
        var result = self;
        result.milliseconds = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withMicroseconds(self: PartialDuration, value: i128) PartialDuration {
        var result = self;
        result.microseconds = .{ .ok = value, .is_ok = true };
        return result;
    }

    pub fn withNanoseconds(self: PartialDuration, value: i128) PartialDuration {
        var result = self;
        result.nanoseconds = .{ .ok = value, .is_ok = true };
        return result;
    }
};

/// Relative-to context for duration operations.
pub const RelativeTo = extern struct {
    plain_date: ?*PlainDate,
    zoned_date_time: ?*ZonedDateTime,
};

// --- Extern types ------------------------------------------------------------

const CDuration = opaque {};
const PlainDate = opaque {};
const ZonedDateTime = opaque {};
const Provider = opaque {};

const DiplomatStringView = extern struct { data: [*c]const u8, len: usize };
const DiplomatString16View = extern struct { data: [*c]const u16, len: usize };

const OptionStringView = extern struct { ok: DiplomatStringView, is_ok: bool };
const OptionU8 = extern struct { ok: u8, is_ok: bool };
const OptionU32 = extern struct { ok: u32, is_ok: bool };
const OptionI64 = extern struct { ok: i64, is_ok: bool };
const OptionI128 = extern struct { ok: i128, is_ok: bool };

const DiplomatWrite = extern struct {
    context: ?*anyopaque,
    buf: [*c]u8,
    len: usize,
    cap: usize,
    grow_failed: bool,
    flush: ?*const fn (*DiplomatWrite) void,
    grow: ?*const fn (*DiplomatWrite, usize) bool,
};

const Precision = extern struct {
    is_minute: bool,
    precision: OptionU8,
};

/// Time unit for Temporal operations.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal
pub const Unit = enum(c_int) {
    auto = 0,
    nanosecond = 1,
    microsecond = 2,
    millisecond = 3,
    second = 4,
    minute = 5,
    hour = 6,
    day = 7,
    week = 8,
    month = 9,
    year = 10,
};

const Unit_option = extern struct { ok: Unit, is_ok: bool };

/// Rounding mode for Temporal operations.
/// See: https://tc39.es/ecma402/#table-sanctioned-single-unit-identifiers
pub const RoundingMode = enum(c_int) {
    /// Round toward positive infinity
    ceil = 0,
    /// Round toward negative infinity
    floor = 1,
    /// Round away from zero
    expand = 2,
    /// Round toward zero (truncate)
    trunc = 3,
    /// Round half toward positive infinity
    half_ceil = 4,
    /// Round half toward negative infinity
    half_floor = 5,
    /// Round half away from zero
    half_expand = 6,
    /// Round half toward zero
    half_trunc = 7,
    /// Round half to even (banker's rounding)
    half_even = 8,
};

const RoundingMode_option = extern struct { ok: RoundingMode, is_ok: bool };

pub const RoundingOptions = extern struct {
    largest_unit: Unit_option,
    smallest_unit: Unit_option,
    rounding_mode: RoundingMode_option,
    increment: OptionU32,
};

pub const ToStringRoundingOptions = extern struct {
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

pub const Sign = enum(c_int) {
    Sign_Positive = 1,
    Sign_Zero = 0,
    Sign_Negative = -1,
};

// --- Result wrappers ---------------------------------------------------------

const DurationResult = extern struct {
    result: extern union {
        ok: ?*CDuration,
        err: TemporalError,
    },
    is_ok: bool,
};

const I8Result = extern struct {
    result: extern union {
        ok: i8,
        err: TemporalError,
    },
    is_ok: bool,
};

const F64Result = extern struct {
    result: extern union {
        ok: f64,
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

extern "c" fn temporal_rs_Duration_try_new(years: i64, months: i64, weeks: i64, days: i64, hours: i64, minutes: i64, seconds: i64, milliseconds: i64, microseconds: f64, nanoseconds: f64) DurationResult;
extern "c" fn temporal_rs_Duration_from_partial_duration(partial: PartialDuration) DurationResult;
extern "c" fn temporal_rs_Duration_from_utf8(s: DiplomatStringView) DurationResult;
extern "c" fn temporal_rs_Duration_from_utf16(s: DiplomatString16View) DurationResult;
extern "c" fn temporal_rs_Duration_is_time_within_range(self: *const CDuration) bool;
extern "c" fn temporal_rs_Duration_years(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_months(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_weeks(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_days(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_hours(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_minutes(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_seconds(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_milliseconds(self: *const CDuration) i64;
extern "c" fn temporal_rs_Duration_microseconds(self: *const CDuration) f64;
extern "c" fn temporal_rs_Duration_nanoseconds(self: *const CDuration) f64;
extern "c" fn temporal_rs_Duration_sign(self: *const CDuration) Sign;
extern "c" fn temporal_rs_Duration_is_zero(self: *const CDuration) bool;
extern "c" fn temporal_rs_Duration_abs(self: *const CDuration) *CDuration;
extern "c" fn temporal_rs_Duration_negated(self: *const CDuration) *CDuration;
extern "c" fn temporal_rs_Duration_add(self: *const CDuration, other: *const CDuration) DurationResult;
extern "c" fn temporal_rs_Duration_subtract(self: *const CDuration, other: *const CDuration) DurationResult;
extern "c" fn temporal_rs_Duration_to_string(self: *const CDuration, options: ToStringRoundingOptions, write: *DiplomatWrite) VoidResult;
extern "c" fn temporal_rs_Duration_round(self: *const CDuration, options: RoundingOptions, relative_to: RelativeTo) DurationResult;
extern "c" fn temporal_rs_Duration_round_with_provider(self: *const CDuration, options: RoundingOptions, relative_to: RelativeTo, p: *const Provider) DurationResult;
extern "c" fn temporal_rs_Duration_compare(self: *const CDuration, other: *const CDuration, relative_to: RelativeTo) I8Result;
extern "c" fn temporal_rs_Duration_compare_with_provider(self: *const CDuration, other: *const CDuration, relative_to: RelativeTo, p: *const Provider) I8Result;
extern "c" fn temporal_rs_Duration_total(self: *const CDuration, unit: Unit, relative_to: RelativeTo) F64Result;
extern "c" fn temporal_rs_Duration_total_with_provider(self: *const CDuration, unit: Unit, relative_to: RelativeTo, p: *const Provider) F64Result;
extern "c" fn temporal_rs_Duration_clone(self: *const CDuration) *CDuration;
extern "c" fn temporal_rs_Duration_destroy(self: *CDuration) void;

extern "c" fn diplomat_buffer_write_create(cap: usize) *DiplomatWrite;
extern "c" fn diplomat_buffer_write_get_bytes(write: *DiplomatWrite) [*c]u8;
extern "c" fn diplomat_buffer_write_len(write: *DiplomatWrite) usize;
extern "c" fn diplomat_buffer_write_destroy(write: *DiplomatWrite) void;

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
    try std.testing.expectEqual(Sign.Sign_Negative, dur_negative.sign());
}

test blank {
    const dur = try Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer dur.deinit();

    try std.testing.expect(dur.blank());
    try std.testing.expectEqual(Sign.Sign_Zero, dur.sign());
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
    try std.testing.expectEqual(Sign.Sign_Positive, abs_dur.sign());
}

test negated {
    const dur = try Duration.from("PT1H");
    defer dur.deinit();

    const neg = dur.negated();
    defer neg.deinit();

    try std.testing.expectEqual(@as(i64, -1), neg.hours());
    try std.testing.expectEqual(Sign.Sign_Negative, neg.sign());
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
    var partial = PartialDuration.empty();
    partial = partial.withHours(3);
    partial = partial.withMinutes(45);

    const dur = try Duration.fromPartialDuration(partial);
    defer dur.deinit();

    try std.testing.expectEqual(@as(i64, 3), dur.hours());
    try std.testing.expectEqual(@as(i64, 45), dur.minutes());
    try std.testing.expectEqual(@as(i64, 0), dur.days());
}

test "isTimeWithinRange" {
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
