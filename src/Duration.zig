const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");

const Duration = @This();

_inner: *abi.c.Duration,

pub const ToStringOptions = t.ToStringRoundingOptions;
pub const ToStringRoundingOptions = t.ToStringRoundingOptions;
pub const Unit = t.Unit;
pub const RoundingMode = t.RoundingMode;
pub const Sign = t.Sign;

pub const RoundingOptions = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,
    relative_to: ?RelativeTo = null,
};

/// Partial duration specification for creating Duration objects.
/// This is a wrapper around the C API type to avoid exposing C types directly.
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

/// Relative-to context for duration operations.
pub const RelativeTo = union(enum) {
    plain_date: PlainDate,
    plain_date_time: PlainDateTime,
    zoned_date_time: ZonedDateTime,
};

/// Options for Duration.total() providing unit and relative-to context.
pub const TotalOptions = struct {
    unit: Unit,
    relative_to: ?RelativeTo = null,
};

pub const CompareOptions = struct {
    relative_to: ?RelativeTo = null,
};

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

/// Get the years component of the duration.
pub fn years(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_years(self._inner);
}

/// Get the months component of the duration.
pub fn months(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_months(self._inner);
}

/// Get the weeks component of the duration.
pub fn weeks(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_weeks(self._inner);
}

/// Get the days component of the duration.
pub fn days(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_days(self._inner);
}

/// Get the hours component of the duration.
pub fn hours(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_hours(self._inner);
}

/// Get the minutes component of the duration.
pub fn minutes(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_minutes(self._inner);
}

/// Get the seconds component of the duration.
pub fn seconds(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_seconds(self._inner);
}

/// Get the milliseconds component of the duration.
pub fn milliseconds(self: Duration) i64 {
    return abi.c.temporal_rs_Duration_milliseconds(self._inner);
}

/// Get the microseconds component of the duration.
pub fn microseconds(self: Duration) f64 {
    return abi.c.temporal_rs_Duration_microseconds(self._inner);
}

/// Get the nanoseconds component of the duration.
pub fn nanoseconds(self: Duration) f64 {
    return abi.c.temporal_rs_Duration_nanoseconds(self._inner);
}

/// Get the sign of the duration: positive (1), zero (0), or negative (-1).
pub fn sign(self: Duration) Sign {
    return abi.from.sign(abi.c.temporal_rs_Duration_sign(self._inner));
}

/// Check if the duration is zero (all fields are zero).
pub fn blank(self: Duration) bool {
    return abi.c.temporal_rs_Duration_is_zero(self._inner);
}

/// Returns a new Duration with the absolute value (all components positive).
pub fn abs(self: Duration) Duration {
    const ptr: *abi.c.Duration = abi.c.temporal_rs_Duration_abs(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Returns a new Duration with all components negated.
pub fn negated(self: Duration) Duration {
    const ptr: *abi.c.Duration = abi.c.temporal_rs_Duration_negated(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Add two durations together (Temporal.Duration.prototype.add).
pub fn add(self: Duration, other: Duration) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_add(self._inner, other._inner));
}

/// Subtract another duration from this one (Temporal.Duration.prototype.subtract).
pub fn subtract(self: Duration, other: Duration) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_subtract(self._inner, other._inner));
}

/// Round the duration according to the specified options (Temporal.Duration.prototype.round).
pub fn round(self: Duration, options: RoundingOptions) !Duration {
    const rel = if (options.relative_to) |r| abi.to.durRelativeTo(r) else abi.c.RelativeTo{ .date = null, .zoned = null };
    return wrapDuration(abi.c.temporal_rs_Duration_round(self._inner, abi.to.durRoundingOpts(options), rel));
}

/// Round the duration with an explicit provider.
fn roundWithProvider(self: Duration, options: RoundingOptions, relative_to: RelativeTo, provider: *const abi.c.Provider) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_round_with_provider(self._inner, options.toCApi(), relative_to, provider));
}

/// Compare two durations (Temporal.Duration.compare).
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

/// Get the total value of the duration in the specified unit (Temporal.Duration.prototype.total).
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

/// Convert to string (Temporal.Duration.prototype.toString); caller owns returned slice.
pub fn toString(self: Duration, allocator: std.mem.Allocator, options: ToStringRoundingOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = abi.c.temporal_rs_Duration_to_string(self._inner, abi.to.strRoundingOpts(options), &write.inner);
    try handleVoidResult(res);

    return try write.toOwnedSlice();
}

pub fn toJSON(self: Duration, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

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

pub fn deinit(self: Duration) void {
    abi.c.temporal_rs_Duration_destroy(self._inner);
}

// --- Helpers -----------------------------------------------------------------

inline fn handleVoidResult(res: anytype) !void {
    _ = try abi.extractResult(res);
}

fn wrapDuration(res: anytype) !Duration {
    const ptr = (try abi.extractResult(res)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
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
