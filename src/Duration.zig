const std = @import("std");
const abi = @import("abi.zig");
const temporal = @import("temporal.zig");

const Duration = @This();

pub const RoundingOptions = temporal.RoundingOptions;
pub const ToStringOptions = temporal.ToStringRoundingOptions;
pub const ToStringRoundingOptions = temporal.ToStringRoundingOptions;
pub const Unit = temporal.Unit;
pub const RoundingMode = temporal.RoundingMode;
pub const Sign = temporal.Sign;

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

    fn toCApi(self: PartialDuration) abi.c.PartialDuration {
        return .{
            .years = abi.toOption(abi.c.OptionI64, self.years),
            .months = abi.toOption(abi.c.OptionI64, self.months),
            .weeks = abi.toOption(abi.c.OptionI64, self.weeks),
            .days = abi.toOption(abi.c.OptionI64, self.days),
            .hours = abi.toOption(abi.c.OptionI64, self.hours),
            .minutes = abi.toOption(abi.c.OptionI64, self.minutes),
            .seconds = abi.toOption(abi.c.OptionI64, self.seconds),
            .milliseconds = abi.toOption(abi.c.OptionI64, self.milliseconds),
            .microseconds = abi.toOption(abi.c.OptionF64, self.microseconds),
            .nanoseconds = abi.toOption(abi.c.OptionF64, self.nanoseconds),
        };
    }
};

/// Wrapper for PlainDate reference in RelativeTo
const PlainDateRef = struct {
    _inner: *abi.c.PlainDate,
};

/// Wrapper for ZonedDateTime reference in RelativeTo
const ZonedDateTimeRef = struct {
    _inner: *abi.c.ZonedDateTime,
};

/// Relative-to context for duration operations.
pub const RelativeTo = struct {
    plain_date: ?PlainDateRef = null,
    zoned_date_time: ?ZonedDateTimeRef = null,

    fn toCApi(self: RelativeTo) abi.c.RelativeTo {
        return .{
            .date = if (self.plain_date) |pd| pd._inner else null,
            .zoned = if (self.zoned_date_time) |zdt| zdt._inner else null,
        };
    }
};
/// Options for Duration.total() providing unit and relative-to context.
pub const TotalOptions = struct {
    unit: Unit,
    relative_to: ?RelativeTo = null,
};

_inner: *abi.c.Duration,

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

/// Parse an ISO 8601 duration string (Temporal.Duration.from).
pub fn from(text: []const u8) !Duration {
    const view = abi.toDiplomatStringView(text);
    return wrapDuration(abi.c.temporal_rs_Duration_from_utf8(view));
}

/// Parse an ISO 8601 UTF-16 duration string.
fn fromUtf16(text: []const u16) !Duration {
    const view = abi.toDiplomatString16View(text);
    return wrapDuration(abi.c.temporal_rs_Duration_from_utf16(view));
}

/// Create a Duration from a partial duration (where some fields may be omitted).
fn fromPartialDuration(partial: PartialDuration) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_from_partial_duration(partial.toCApi()));
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
    return Sign.fromCApi(abi.c.temporal_rs_Duration_sign(self._inner));
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
pub fn round(self: Duration, options: RoundingOptions, relative_to: RelativeTo) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_round(self._inner, options.toCApi(), relative_to.toCApi()));
}

/// Round the duration with an explicit provider.
fn roundWithProvider(self: Duration, options: RoundingOptions, relative_to: RelativeTo, provider: *const abi.c.Provider) !Duration {
    return wrapDuration(abi.c.temporal_rs_Duration_round_with_provider(self._inner, options.toCApi(), relative_to, provider));
}

/// Compare two durations (Temporal.Duration.compare).
pub fn compare(self: Duration, other: Duration, relative_to: RelativeTo) !i8 {
    const res = abi.c.temporal_rs_Duration_compare(self._inner, other._inner, relative_to.toCApi());
    return abi.success(res) orelse return error.TemporalError;
}

/// Compare two durations with an explicit provider.
fn compareWithProvider(self: Duration, other: Duration, relative_to: RelativeTo, provider: *const abi.c.Provider) !i8 {
    const res = abi.c.temporal_rs_Duration_compare_with_provider(self._inner, other._inner, relative_to.toCApi(), provider);
    return abi.success(res) orelse return error.TemporalError;
}

/// Get the total value of the duration in the specified unit (Temporal.Duration.prototype.total).
pub fn total(self: Duration, options: TotalOptions) !f64 {
    const rel = if (options.relative_to) |r| r.toCApi() else abi.c.RelativeTo{ .date = null, .zoned = null };
    const res = abi.c.temporal_rs_Duration_total(self._inner, options.unit.toCApi(), rel);
    return abi.success(res) orelse return error.TemporalError;
}

/// Get the total value of the duration with an explicit provider.
fn totalWithProvider(self: Duration, options: TotalOptions, provider: *const abi.c.Provider) !f64 {
    const rel = if (options.relative_to) |r| r.toCApi() else abi.c.RelativeTo{ .date = null, .zoned = null };
    const res = abi.c.temporal_rs_Duration_total_with_provider(self._inner, options.unit.toCApi(), rel, provider);
    return abi.success(res) orelse return error.TemporalError;
}

/// Convert to string (Temporal.Duration.prototype.toString); caller owns returned slice.
pub fn toString(self: Duration, allocator: std.mem.Allocator, options: ToStringRoundingOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const res = abi.c.temporal_rs_Duration_to_string(self._inner, options.toCApi(), &write.inner);
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

fn handleVoidResult(res: anytype) !void {
    _ = abi.success(res) orelse return error.TemporalError;
}

fn wrapDuration(res: anytype) !Duration {
    const ptr = (abi.success(res) orelse return error.TemporalError) orelse return error.TemporalError;
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
