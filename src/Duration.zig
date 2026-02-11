const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");

/// The `Temporal.Duration` object represents a difference between two time points, which can be used in date/time arithmetic.
/// It is fundamentally represented as a combination of years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, and nanoseconds values.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration
const Duration = @This();

_inner: *abi.c.Duration,

/// Options for controlling stringification of a Duration.
pub const ToStringOptions = t.ToStringRoundingOptions;
/// Options for controlling stringification of a Duration (alias).
pub const ToStringRoundingOptions = t.ToStringRoundingOptions;
/// Units supported by Temporal.Duration (years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds).
pub const Unit = t.Unit;
/// Rounding modes for Duration operations.
pub const RoundingMode = t.RoundingMode;
/// The sign of a Duration: positive, zero, or negative.
pub const Sign = t.Sign;

/// Options for rounding a Duration.
pub const RoundingOptions = struct {
    /// The largest unit to round to.
    largest_unit: ?Unit = null,
    /// The smallest unit to round to.
    smallest_unit: ?Unit = null,
    /// The rounding mode to use.
    rounding_mode: ?RoundingMode = null,
    /// The increment to round to.
    rounding_increment: ?u32 = null,
    /// The relative-to context (PlainDate, PlainDateTime, or ZonedDateTime).
    relative_to: ?RelativeTo = null,
};

/// Partial duration specification for creating Duration objects.
/// This is a wrapper around the C API type to avoid exposing C types directly.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/from
pub const PartialDuration = struct {
    years: ?i64 = null,
    months: ?i64 = null,
    weeks: ?i64 = null,
    days: ?i64 = null,
    hours: ?i64 = null,
    minutes: ?i64 = null,
    seconds: ?i64 = null,
    milliseconds: ?i64 = null,
    microseconds: ?f64 = null,
    nanoseconds: ?f64 = null,
};

/// Relative-to context for duration operations, used for balancing and calendar-aware math.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration#calendar_durations
pub const RelativeTo = union(enum) {
    plain_date: PlainDate,
    plain_date_time: PlainDateTime,
    zoned_date_time: ZonedDateTime,
};

/// Options for Duration.total() providing unit and relative-to context.
pub const TotalOptions = struct {
    /// The unit to total in.
    unit: Unit,
    /// The relative-to context (PlainDate, PlainDateTime, or ZonedDateTime).
    relative_to: ?RelativeTo = null,
};

/// Options for Duration.compare() providing relative-to context.
pub const CompareOptions = struct {
    /// The relative-to context (PlainDate, PlainDateTime, or ZonedDateTime).
    relative_to: ?RelativeTo = null,
};

/// Construct a Duration from years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, and nanoseconds.
/// Equivalent to `Temporal.Duration()` constructor.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/Duration
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
    return wrapDuration(abi.c.temporal_rs_Duration_try_new(
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

/// The Temporal.Duration.from() static method creates a new Temporal.Duration object from one of the following:
/// - A Temporal.Duration instance, which creates a copy of the instance.
/// - An ISO 8601 string representing a duration.
/// - A @Temporal.Duration.PartialDuration struct containing at least one of the following properties:
///   - days
///   - hours
///   - microseconds
///   - milliseconds
///   - minutes
///   - months
///   - nanoseconds
///   - seconds
///   - weeks
///   - years
/// The resulting duration must not have mixed signs, so all of these properties must have the same sign (or zero). Missing properties are treated as zero.
pub fn from(info: anytype) !Duration {
    const T = @TypeOf(info);

    if (T == Duration) return info.clone();
    if (T == PartialDuration) return fromPartialDuration(info);

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
        else => @compileError("from() expects a Duration, []const u8, or []const u16, or Temporal.Duration.PartialDuration"),
    }
}

inline fn fromUtf16(text: []const u16) !Duration {
    const view = abi.toDiplomatString16View(text);
    return wrapDuration(abi.c.temporal_rs_Duration_from_utf16(view));
}

inline fn fromUtf8(text: []const u8) !Duration {
    const view = abi.toDiplomatStringView(text);
    return wrapDuration(abi.c.temporal_rs_Duration_from_utf8(view));
}

/// Create a Duration from a partial duration (where some fields may be omitted).
fn fromPartialDuration(partial: PartialDuration) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_from_partial_duration(abi.to.partialdur(partial)));
}

/// Check if the time portion of the duration is within valid ranges.
fn isTimeWithinRange(self: Duration) bool {
    return abi.c.temporal_rs_Duration_is_time_within_range(self._inner);
}

/// Returns the number of years in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/years
pub fn years(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_years(self._inner);
}

/// Returns the number of months in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/months
pub fn months(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_months(self._inner);
}

/// Returns the number of weeks in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/weeks
pub fn weeks(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_weeks(self._inner);
}

/// Returns the number of days in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/days
pub fn days(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_days(self._inner);
}

/// Returns the number of hours in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/hours
pub fn hours(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_hours(self._inner);
}

/// Returns the number of minutes in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/minutes
pub fn minutes(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_minutes(self._inner);
}

/// Returns the number of seconds in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/seconds
pub fn seconds(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_seconds(self._inner);
}

/// Returns the number of milliseconds in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/milliseconds
pub fn milliseconds(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_milliseconds(self._inner);
}

/// Returns the number of microseconds in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/microseconds
pub fn microseconds(self: Duration) f64 {
    return abi.c.temporal_rs_Duration_microseconds(self._inner);
}

/// Returns the number of nanoseconds in the duration.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/nanoseconds
pub fn nanoseconds(self: Duration) f64 {
    return abi.c.temporal_rs_Duration_nanoseconds(self._inner);
}

/// Returns the sign of the duration: positive (1), zero (0), or negative (-1).
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/sign
pub fn sign(self: Duration) Sign {
    return abi.from.sign(abi.c.temporal_rs_Duration_sign(self._inner));
}

/// Returns true if the duration is zero (all fields are zero), false otherwise.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/blank
pub fn blank(self: Duration) bool {
    return abi.c.temporal_rs_Duration_is_zero(self._inner);
}

/// Returns a new Duration with the absolute value (all components positive).
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/abs
pub fn abs(self: Duration) Duration {
    const ptr: *abi.c.Duration = abi.c.temporal_rs_Duration_abs(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Returns a new Duration with all components negated (sign reversed).
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/negated
pub fn negated(self: Duration) Duration {
    const ptr: *abi.c.Duration = abi.c.temporal_rs_Duration_negated(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Returns a new Duration with the sum of this duration and another (balanced as needed).
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/add
pub fn add(self: Duration, other: Duration) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_add(self._inner, other._inner));
}

/// Returns a new Duration with the difference between this duration and another (balanced as needed).
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/subtract
pub fn subtract(self: Duration, other: Duration) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_subtract(self._inner, other._inner));
}

/// Returns a new Duration rounded to the given smallest/largest unit and/or balanced.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/round
pub fn round(self: Duration, options: RoundingOptions) !Duration {
    const rel = if (options.relative_to) |r| abi.to.durRelativeTo(r) else abi.c.RelativeTo{ .date = null, .zoned = null };
    return wrapDuration(abi.c.temporal_rs_Duration_round(self._inner, abi.to.durRoundingOpts(options), rel));
}

/// Round the duration with an explicit provider.
fn roundWithProvider(self: Duration, options: RoundingOptions, relative_to: RelativeTo, provider: *const abi.c.Provider) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_round_with_provider(self._inner, options.toCApi(), relative_to, provider));
}

/// Compares two durations, returning -1, 0, or 1 if this duration is shorter, equal, or longer than the other.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/compare
pub fn compare(self: Duration, other: Duration, options: CompareOptions) !i8 {
    const rel = if (options.relative_to) |r| abi.to.durRelativeTo(r) else abi.c.RelativeTo{ .date = null, .zoned = null };
    const res = abi.c.temporal_rs_Duration_compare(self._inner, other._inner, rel);
    return try abi.extractResult(res);
}

/// Compare two durations with an explicit provider.
fn compareWithProvider(self: Duration, other: Duration, relative_to: RelativeTo, provider: *const abi.c.Provider) !i8 {
    const res = abi.c.temporal_rs_Duration_compare_with_provider(self._inner, other._inner, relative_to.toCApi(), provider);
    return try abi.extractResult(res);
}

/// Returns the total value of the duration in the specified unit.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/total
pub fn total(self: Duration, options: TotalOptions) !f64 {
    const rel = if (options.relative_to) |r| abi.to.durRelativeTo(r) else abi.c.RelativeTo{ .date = null, .zoned = null };
    const res = abi.c.temporal_rs_Duration_total(self._inner, abi.to.unit(options.unit).?, rel);
    return try abi.extractResult(res);
}

/// Get the total value of the duration with an explicit provider.
fn totalWithProvider(self: Duration, options: TotalOptions, provider: *const abi.c.Provider) !f64 {
    const rel = if (options.relative_to) |r| abi.to.durRelativeTo(r) else abi.c.RelativeTo{ .date = null, .zoned = null };
    const res = abi.c.temporal_rs_Duration_total_with_provider(self._inner, options.unit.toCApi(), rel, provider);
    return try abi.extractResult(res);
}

/// Returns a string representing this duration in the ISO 8601 format.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toString
pub fn toString(self: Duration, allocator: std.mem.Allocator, options: ToStringRoundingOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = abi.c.temporal_rs_Duration_to_string(self._inner, abi.to.strRoundingOpts(options), &write.inner);
    try handleVoidResult(res);

    return try write.toOwnedSlice();
}

/// Returns a string representing this duration in the ISO 8601 format (same as toString). Intended for JSON serialization.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toJSON
pub fn toJSON(self: Duration, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Returns a string with a language-sensitive representation of this duration. Not implemented.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toLocaleString
pub fn toLocaleString(self: Duration, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

/// Clone the underlying duration.
fn clone(self: Duration) Duration {
    const ptr: *abi.c.Duration = abi.c.temporal_rs_Duration_clone(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Deinitialize the Duration, freeing underlying resources.
pub fn deinit(self: Duration) void {
    abi.c.temporal_rs_Duration_destroy(self._inner);
}

// --- Helpers -----------------------------------------------------------------

inline fn handleVoidResult(res: anytype) !void {
    _ = try abi.extractResult(res);
}

fn wrapDuration(res: anytype) !Duration {
    const ptr = try abi.extractResult(res);
    if (ptr == null) return abi.TemporalError.RangeError;
    return .{ ._inner = ptr.? };
}

// --- Aliases and enums ------------------------------------------

const OptionU8 = abi.c.OptionU8;
const OptionU32 = abi.c.OptionU32;
const OptionI64 = abi.c.OptionI64;
const OptionF64 = abi.c.OptionF64;
const Precision = abi.c.Precision;
const Unit_option = abi.c.Unit_option;
const RoundingMode_option = abi.c.RoundingMode_option;

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
    { // P1Y2M3DT4H5M6.789S = 1 year, 2 months, 3 days, 4 hours, 5 minutes, 6.789 seconds
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
    {
        const partial = PartialDuration{
            .hours = 3,
            .minutes = 45,
        };

        const dur = try Duration.from(partial);
        defer dur.deinit();

        try std.testing.expectEqual(@as(i64, 3), dur.hours());
        try std.testing.expectEqual(@as(i64, 45), dur.minutes());
    }
    {
        const dur1 = try Duration.from("PT1H");
        defer dur1.deinit();
        const dur2 = try Duration.from(dur1);
        defer dur2.deinit();

        try std.testing.expectEqual(@as(i64, 1), dur2.hours());
        try std.testing.expectEqual(@as(i64, 0), dur2.minutes());
    }
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

test compare {
    const dur1 = try Duration.from("PT1H");
    defer dur1.deinit();
    const dur2 = try Duration.from("PT30M");
    defer dur2.deinit();

    const result = try dur1.compare(dur2, .{});

    try std.testing.expectEqual(@as(i8, 1), result);
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
    const str = try dur.toString(allocator, .{});
    defer allocator.free(str);

    // Should output ISO 8601 duration format
    try std.testing.expect(str.len > 0);
}

test fromPartialDuration {
    const partial = PartialDuration{
        .hours = 3,
        .minutes = 45,
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

test round {
    {
        const dur = try Duration.from("PT1H30M");
        defer dur.deinit();

        const rounded = try dur.round(.{
            .smallest_unit = .hour,
            .relative_to = .{
                .plain_date_time = try PlainDateTime.init(2024, 1, 1, 12, 0, 0, 0, 0, 0),
            },
        });
        defer rounded.deinit();

        try std.testing.expectEqual(@as(i64, 2), rounded.hours());
        try std.testing.expectEqual(@as(i64, 0), rounded.minutes());
    }

    {
        const dur = try Duration.from("PT1H30M");
        defer dur.deinit();

        const rounded = try dur.round(.{
            .smallest_unit = .hour,
            .relative_to = .{
                .plain_date = try PlainDate.init(2024, 1, 1),
            },
        });
        defer rounded.deinit();

        try std.testing.expectEqual(@as(i64, 2), rounded.hours());
        try std.testing.expectEqual(@as(i64, 0), rounded.minutes());
    }

    {
        const dur = try Duration.from("PT1H30M");
        defer dur.deinit();

        const rounded = try dur.round(.{ .smallest_unit = .hour });
        defer rounded.deinit();

        try std.testing.expectEqual(@as(i64, 2), rounded.hours());
        try std.testing.expectEqual(@as(i64, 0), rounded.minutes());
    }
}

test total {
    {
        const dur = try Duration.init(0, 0, 0, 0, 1, 30, 0, 0, 0, 0);
        defer dur.deinit();

        const ttl = try dur.total(.{ .unit = .hour });
        try std.testing.expectEqual(1.5, ttl);
    }
    {
        const dur = try Duration.from("PT4H5M6S");
        defer dur.deinit();

        const ttl = try dur.total(.{ .unit = .hour });
        try std.testing.expectEqual(4.085, ttl);
    }

    {
        // Calendar units require relative_to; the C API will return RangeError.
        const dur = try Duration.from("P1Y");
        defer dur.deinit();

        try std.testing.expectError(error.RangeError, dur.total(.{ .unit = .day }));
    }
}

test years {
    const dur = try Duration.from("P5Y");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 5), dur.years());
}

test months {
    const dur = try Duration.from("P2M");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 2), dur.months());
}

test weeks {
    const dur = try Duration.from("P3W");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 3), dur.weeks());
}

test days {
    const dur = try Duration.from("P7D");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 7), dur.days());
}

test hours {
    const dur = try Duration.from("PT5H");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 5), dur.hours());
}

test minutes {
    const dur = try Duration.from("PT30M");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 30), dur.minutes());
}

test seconds {
    const dur = try Duration.from("PT45S");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 45), dur.seconds());
}

test milliseconds {
    const dur = try Duration.from("PT0.500S");
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 500), dur.milliseconds());
}

test microseconds {
    const dur = try Duration.from("PT0.000500S");
    defer dur.deinit();
    const us = dur.microseconds();
    try std.testing.expect(us > 499 and us < 501);
}

test nanoseconds {
    const dur = try Duration.from("PT0.000000500S");
    defer dur.deinit();
    const ns = dur.nanoseconds();
    try std.testing.expect(ns > 499 and ns < 501);
}

test sign {
    const pos = try Duration.from("P1Y");
    defer pos.deinit();
    try std.testing.expectEqual(Sign.positive, pos.sign());

    const neg = try Duration.from("-P1Y");
    defer neg.deinit();
    try std.testing.expectEqual(Sign.negative, neg.sign());

    const zero = try Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer zero.deinit();
    try std.testing.expectEqual(Sign.zero, zero.sign());
}

test toJSON {
    const dur = try Duration.from("P1Y2M3DT4H5M6.789S");
    defer dur.deinit();

    const json_str = try dur.toJSON(std.testing.allocator);
    defer std.testing.allocator.free(json_str);

    try std.testing.expect(json_str.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, json_str, "P") != null);
}

test toLocaleString {
    const dur = try Duration.from("P1Y2M3DT4H5M6S");
    defer dur.deinit();

    try std.testing.expectError(error.TemporalNotImplemented, dur.toLocaleString(std.testing.allocator));
}
