const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const Duration = @import("Duration.zig");

/// # Temporal.PlainTime
///
/// The `Temporal.PlainTime` object represents a wall-clock time, with no date or time zone.
///
/// - [MDN Temporal.PlainTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime)
const PlainTime = @This();

_inner: *abi.c.PlainTime,

// Import types from temporal.zig
pub const Unit = t.Unit;
pub const RoundingMode = t.RoundingMode;
pub const DifferenceSettings = t.DifferenceSettings;
pub const RoundOptions = t.RoundingOptions;

pub const WithOptions = struct {
    hour: ?u8 = null,
    minute: ?u8 = null,
    second: ?u8 = null,
    millisecond: ?u16 = null,
    microsecond: ?u16 = null,
    nanosecond: ?u16 = null,
};

// Helper to wrap PlainTime pointer
fn wrapPlainTime(result: anytype) !PlainTime {
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return PlainTime{ ._inner = ptr };
}

/// Creates a new PlainTime from the given time components.
/// Equivalent to the Temporal.PlainTime constructor.
/// See [MDN Temporal.PlainTime() constructor](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/PlainTime)
pub fn init(
    hour_val: u8,
    minute_val: u8,
    second_val: u8,
    millisecond_val: u16,
    microsecond_val: u16,
    nanosecond_val: u16,
) !PlainTime {
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_try_new(
        hour_val,
        minute_val,
        second_val,
        millisecond_val,
        microsecond_val,
        nanosecond_val,
    ));
}

/// Parses a PlainTime from a string.
/// See [MDN Temporal.PlainTime.from()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/from)
pub fn from(s: []const u8) !PlainTime {
    return fromUtf8(s);
}

fn fromUtf8(utf8: []const u8) !PlainTime {
    const view = abi.toDiplomatStringView(utf8);
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_from_utf8(view));
}

fn fromUtf16(utf16: []const u16) !PlainTime {
    const view = abi.toDiplomatString16View(utf16);
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_from_utf16(view));
}

/// Compares two PlainTime instances by their time values.
/// Returns -1, 0, or 1 if the first is before, equal, or after the second.
/// See [MDN Temporal.PlainTime.compare()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/compare)
pub fn compare(a: PlainTime, b: PlainTime) i8 {
    return abi.c.temporal_rs_PlainTime_compare(a._inner, b._inner);
}

/// Returns true if this PlainTime is equal to another (same time values).
/// See [MDN Temporal.PlainTime.prototype.equals()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/equals)
pub fn equals(self: PlainTime, other: PlainTime) bool {
    return abi.c.temporal_rs_PlainTime_equals(self._inner, other._inner);
}

/// Returns a new PlainTime moved forward by the given duration, wrapping around the clock if necessary.
/// See [MDN Temporal.PlainTime.prototype.add()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/add)
pub fn add(self: PlainTime, duration: Duration) !PlainTime {
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_add(self._inner, duration._inner));
}

/// Returns a new PlainTime moved backward by the given duration, wrapping around the clock if necessary.
/// See [MDN Temporal.PlainTime.prototype.subtract()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/subtract)
pub fn subtract(self: PlainTime, duration: Duration) !PlainTime {
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_subtract(self._inner, duration._inner));
}

/// Returns the duration from this PlainTime to another.
/// See [MDN Temporal.PlainTime.prototype.until()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/until)
pub fn until(self: PlainTime, other: PlainTime, options: DifferenceSettings) !Duration {
    const settings = abi.to.diffsettings(options);
    const result = abi.c.temporal_rs_PlainTime_until(self._inner, other._inner, settings);
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns the duration from another PlainTime to this one.
/// See [MDN Temporal.PlainTime.prototype.since()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/since)
pub fn since(self: PlainTime, other: PlainTime, options: DifferenceSettings) !Duration {
    const settings = abi.to.diffsettings(options);
    const result = abi.c.temporal_rs_PlainTime_since(self._inner, other._inner, settings);
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

// Rounding
/// Returns a new PlainTime rounded to the given unit and options.
/// See [MDN Temporal.PlainTime.prototype.round()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/round)
pub fn round(self: PlainTime, options: RoundOptions) !PlainTime {
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_round(self._inner, abi.to.roundingOpts(options)));
}

// Property accessors
/// Returns the hour component of this time (0-23).
/// See [MDN Temporal.PlainTime.prototype.hour](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/hour)
pub fn hour(self: PlainTime) u8 {
    return abi.c.temporal_rs_PlainTime_hour(self._inner);
}

/// Returns the minute component of this time (0-59).
/// See [MDN Temporal.PlainTime.prototype.minute](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/minute)
pub fn minute(self: PlainTime) u8 {
    return abi.c.temporal_rs_PlainTime_minute(self._inner);
}

/// Returns the second component of this time (0-59).
/// See [MDN Temporal.PlainTime.prototype.second](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/second)
pub fn second(self: PlainTime) u8 {
    return abi.c.temporal_rs_PlainTime_second(self._inner);
}

/// Returns the millisecond component of this time (0-999).
/// See [MDN Temporal.PlainTime.prototype.millisecond](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/millisecond)
pub fn millisecond(self: PlainTime) u16 {
    return abi.c.temporal_rs_PlainTime_millisecond(self._inner);
}

/// Returns the microsecond component of this time (0-999).
/// See [MDN Temporal.PlainTime.prototype.microsecond](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/microsecond)
pub fn microsecond(self: PlainTime) u16 {
    return abi.c.temporal_rs_PlainTime_microsecond(self._inner);
}

/// Returns the nanosecond component of this time (0-999).
/// See [MDN Temporal.PlainTime.prototype.nanosecond](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/nanosecond)
pub fn nanosecond(self: PlainTime) u16 {
    return abi.c.temporal_rs_PlainTime_nanosecond(self._inner);
}

// Modification
/// Returns a new PlainTime with some fields replaced by new values.
/// See [MDN Temporal.PlainTime.prototype.with()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/with)
pub fn with(self: PlainTime, options: WithOptions) !PlainTime {
    const partial = abi.c.PartialTime{
        .hour = abi.toOption(abi.c.OptionU8, options.hour),
        .minute = abi.toOption(abi.c.OptionU8, options.minute),
        .second = abi.toOption(abi.c.OptionU8, options.second),
        .millisecond = abi.toOption(abi.c.OptionU16, options.millisecond),
        .microsecond = abi.toOption(abi.c.OptionU16, options.microsecond),
        .nanosecond = abi.toOption(abi.c.OptionU16, options.nanosecond),
    };
    const overflow_opt = abi.c.ArithmeticOverflow_option{
        .is_ok = true,
        .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain },
    };
    return wrapPlainTime(abi.c.temporal_rs_PlainTime_with(self._inner, partial, overflow_opt));
}

// String conversions
/// Returns a string representing this PlainTime in RFC 9557 format.
/// See [MDN Temporal.PlainTime.prototype.toString()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/toString)
pub fn toString(self: PlainTime, allocator: std.mem.Allocator) ![]u8 {
    return toStringWithOptions(self, allocator, .{});
}

fn toStringWithOptions(self: PlainTime, allocator: std.mem.Allocator, options: t.ToStringRoundingOptions) ![]u8 {
    const rounding_opts = abi.to.strRoundingOpts(options);
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const result = abi.c.temporal_rs_PlainTime_to_ixdtf_string(
        self._inner,
        rounding_opts,
        &write.inner,
    );

    if (!result.is_ok) return error.TemporalError;

    return try write.toOwnedSlice();
}

/// Returns a string representing this PlainTime in RFC 9557 format (ISO 8601).
/// See [MDN Temporal.PlainTime.prototype.toJSON()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/toJSON)
pub fn toJSON(self: PlainTime, allocator: std.mem.Allocator) ![]u8 {
    return toString(self, allocator);
}

/// Returns a language-sensitive string representation of this PlainTime.
/// See [MDN Temporal.PlainTime.prototype.toLocaleString()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/toLocaleString)
pub fn toLocaleString(self: PlainTime, allocator: std.mem.Allocator) ![]u8 {
    // For now, just use toString - locale-specific formatting would require more work
    return toString(self, allocator);
}

/// Throws an error; valueOf() is not supported for PlainTime.
/// See [MDN Temporal.PlainTime.prototype.valueOf()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainTime/valueOf)
pub fn valueOf(self: PlainTime) !void {
    _ = self;
    // PlainTime should not be used in arithmetic/comparison operations implicitly
    return error.ValueError;
}

// ---------- Tests ---------------------

test init {
    {
        const time = try init(14, 30, 45, 123, 456, 789);
        try std.testing.expectEqual(@as(u8, 14), time.hour());
        try std.testing.expectEqual(@as(u8, 30), time.minute());
        try std.testing.expectEqual(@as(u8, 45), time.second());
        try std.testing.expectEqual(@as(u16, 123), time.millisecond());
        try std.testing.expectEqual(@as(u16, 456), time.microsecond());
        try std.testing.expectEqual(@as(u16, 789), time.nanosecond());
    }
    {
        const time = try init(0, 0, 0, 0, 0, 0);
        try std.testing.expectEqual(@as(u8, 0), time.hour());
        try std.testing.expectEqual(@as(u8, 0), time.minute());
        try std.testing.expectEqual(@as(u8, 0), time.second());
    }
    {
        const time = try init(23, 59, 59, 999, 999, 999);
        try std.testing.expectEqual(@as(u8, 23), time.hour());
        try std.testing.expectEqual(@as(u8, 59), time.minute());
        try std.testing.expectEqual(@as(u8, 59), time.second());
    }
}

test from {
    {
        const time = try from("14:30:45.123456789");
        try std.testing.expectEqual(@as(u8, 14), time.hour());
        try std.testing.expectEqual(@as(u8, 30), time.minute());
        try std.testing.expectEqual(@as(u8, 45), time.second());
        try std.testing.expectEqual(@as(u16, 123), time.millisecond());
        try std.testing.expectEqual(@as(u16, 456), time.microsecond());
        try std.testing.expectEqual(@as(u16, 789), time.nanosecond());
    }
    {
        const time = try from("14:30");
        try std.testing.expectEqual(@as(u8, 14), time.hour());
        try std.testing.expectEqual(@as(u8, 30), time.minute());
        try std.testing.expectEqual(@as(u8, 0), time.second());
    }

    {
        const time = try from("14:30:45");
        try std.testing.expectEqual(@as(u8, 14), time.hour());
        try std.testing.expectEqual(@as(u8, 30), time.minute());
        try std.testing.expectEqual(@as(u8, 45), time.second());
    }
}

test compare {
    {
        const time1 = try init(14, 30, 45, 123, 456, 789);
        const time2 = try init(14, 30, 45, 123, 456, 789);
        try std.testing.expectEqual(@as(i8, 0), compare(time1, time2));
    }
    {
        const time1 = try init(14, 30, 45, 123, 456, 789);
        const time2 = try init(15, 30, 45, 123, 456, 789);
        try std.testing.expectEqual(@as(i8, -1), compare(time1, time2));
    }
    {
        const time1 = try init(15, 30, 45, 123, 456, 789);
        const time2 = try init(14, 30, 45, 123, 456, 789);
        try std.testing.expectEqual(@as(i8, 1), compare(time1, time2));
    }
}

test equals {
    {
        const time1 = try init(14, 30, 45, 123, 456, 789);
        const time2 = try init(14, 30, 45, 123, 456, 789);
        try std.testing.expect(time1.equals(time2));
    }
    {
        const time1 = try init(14, 30, 45, 123, 456, 789);
        const time2 = try init(15, 30, 45, 123, 456, 789);
        try std.testing.expect(!time1.equals(time2));
    }
}

test add {
    {
        const time = try init(14, 30, 0, 0, 0, 0);
        const duration = try Duration.from("PT1H30M");
        const result = try time.add(duration);
        try std.testing.expectEqual(@as(u8, 16), result.hour());
        try std.testing.expectEqual(@as(u8, 0), result.minute());
    }
    {
        const time = try init(23, 30, 0, 0, 0, 0);
        const duration = try Duration.from("PT1H");
        const result = try time.add(duration);
        try std.testing.expectEqual(@as(u8, 0), result.hour());
        try std.testing.expectEqual(@as(u8, 30), result.minute());
    }
}

test subtract {
    {
        const time = try init(16, 0, 0, 0, 0, 0);
        const duration = try Duration.from("PT1H30M");
        const result = try time.subtract(duration);
        try std.testing.expectEqual(@as(u8, 14), result.hour());
        try std.testing.expectEqual(@as(u8, 30), result.minute());
    }
    {
        const time = try init(0, 30, 0, 0, 0, 0);
        const duration = try Duration.from("PT1H");
        const result = try time.subtract(duration);
        try std.testing.expectEqual(@as(u8, 23), result.hour());
        try std.testing.expectEqual(@as(u8, 30), result.minute());
    }
}

test with {
    {
        const time = try init(14, 30, 45, 123, 456, 789);
        const result = try time.with(.{ .hour = 18 });
        try std.testing.expectEqual(@as(u8, 18), result.hour());
        try std.testing.expectEqual(@as(u8, 30), result.minute());
        try std.testing.expectEqual(@as(u8, 45), result.second());
    }

    {
        const time = try init(14, 30, 45, 123, 456, 789);
        const result = try time.with(.{ .hour = 18, .minute = 15, .second = 0 });
        try std.testing.expectEqual(@as(u8, 18), result.hour());
        try std.testing.expectEqual(@as(u8, 15), result.minute());
        try std.testing.expectEqual(@as(u8, 0), result.second());
    }
}

test toString {
    const time = try init(14, 30, 45, 123, 456, 789);
    const str = try time.toString(std.testing.allocator);
    defer std.testing.allocator.free(str);

    // Should be in format: 14:30:45.123456789
    try std.testing.expect(str.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, str, "14:30:45") != null);
}

test toJSON {
    const time = try init(14, 30, 45, 123, 456, 789);
    const str = try time.toJSON(std.testing.allocator);
    defer std.testing.allocator.free(str);
    try std.testing.expect(str.len > 0);
}

test round {
    const time = try init(14, 30, 45, 999, 999, 999);
    const rounded = try time.round(.{ .smallest_unit = .second });

    try std.testing.expectEqual(@as(u8, 14), rounded.hour());
    try std.testing.expectEqual(@as(u8, 30), rounded.minute());
    try std.testing.expectEqual(@as(u8, 46), rounded.second());
    try std.testing.expectEqual(@as(u16, 0), rounded.millisecond());
    try std.testing.expectEqual(@as(u16, 0), rounded.microsecond());
    try std.testing.expectEqual(@as(u16, 0), rounded.nanosecond());
}

test since {
    const time1 = try init(15, 30, 0, 0, 0, 0);
    const time2 = try init(14, 0, 0, 0, 0, 0);
    const dur = try time1.since(time2, .{});

    try std.testing.expectEqual(@as(i64, 1), dur.hours());
    try std.testing.expectEqual(@as(i64, 30), dur.minutes());
}

test until {
    const time1 = try init(14, 0, 0, 0, 0, 0);
    const time2 = try init(15, 30, 0, 0, 0, 0);
    const dur = try time1.until(time2, .{});

    try std.testing.expectEqual(@as(i64, 1), dur.hours());
    try std.testing.expectEqual(@as(i64, 30), dur.minutes());
}

test hour {
    if (true) return error.Todo;
}

test minute {
    if (true) return error.Todo;
}

test second {
    if (true) return error.Todo;
}

test millisecond {
    if (true) return error.Todo;
}

test microsecond {
    if (true) return error.Todo;
}

test nanosecond {
    if (true) return error.Todo;
}

test toLocaleString {
    if (true) return error.Todo;
}

test valueOf {
    if (true) return error.Todo;
}
