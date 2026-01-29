const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const Duration = @import("Duration.zig");

const ZonedDateTime = @This();

_inner: *abi.c.ZonedDateTime,

// Import types from temporal.zig
pub const Unit = t.Unit;
pub const RoundingMode = t.RoundingMode;
pub const Sign = t.Sign;
pub const DifferenceSettings = t.DifferenceSettings;
pub const RoundOptions = t.RoundingOptions;

pub const TimeZone = struct {
    _inner: abi.c.TimeZone,

    pub fn init(id: []const u8) !TimeZone {
        const view = abi.toDiplomatStringView(id);
        const result = abi.c.temporal_rs_TimeZone_try_from_str(view);
        const tz = try abi.extractResult(result);
        return .{ ._inner = tz };
    }

    // ...existing code...
};

pub const Disambiguation = enum {
    compatible,
    earlier,
    later,
    reject,

    // ...existing code...
};

pub const OffsetDisambiguation = enum {
    use_offset,
    prefer_offset,
    ignore_offset,
    reject,

    // ...existing code...
};

pub const CalendarDisplay = enum {
    auto,
    always,
    never,
    critical,

    // ...existing code...
};

pub const DisplayOffset = enum {
    auto,
    never,

    // ...existing code...
};

pub const DisplayTimeZone = enum {
    auto,
    never,
    critical,

    // ...existing code...
};

pub const ToStringOptions = struct {
    fractional_second_digits: ?u8 = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    calendar_display: CalendarDisplay = .auto,
    offset_display: DisplayOffset = .auto,
    time_zone_name: DisplayTimeZone = .auto,
};

/// Helper function to wrap a C API result into a ZonedDateTime
fn wrapZonedDateTime(result: anytype) !ZonedDateTime {
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Create a ZonedDateTime from epoch nanoseconds
pub fn init(epoch_ns: i128, time_zone: TimeZone) !ZonedDateTime {
    const ns_parts = abi.toI128Nanoseconds(epoch_ns);
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_from_epoch_nanoseconds(ns_parts, abi.to.toTimeZone(time_zone)));
}

/// Create from epoch milliseconds
pub fn fromEpochMilliseconds(epoch_ms: i64, time_zone: TimeZone) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_from_epoch_milliseconds(epoch_ms, abi.to.toTimeZone(time_zone)));
}

/// Create from epoch nanoseconds
pub fn fromEpochNanoseconds(epoch_ns: i128, time_zone: TimeZone) !ZonedDateTime {
    const ns_parts = abi.toI128Nanoseconds(epoch_ns);
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_from_epoch_nanoseconds(ns_parts, abi.to.toTimeZone(time_zone)));
}

/// Parse from string
pub fn from(s: []const u8, time_zone: ?TimeZone, disambiguation: Disambiguation, offset_disambiguation: OffsetDisambiguation) !ZonedDateTime {
    _ = time_zone; // The time zone is parsed from the string
    const view = abi.toDiplomatStringView(s);
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_from_utf8(view, abi.to.toDisambiguation(disambiguation), abi.to.toOffsetDisambiguation(offset_disambiguation)));
}

/// Compare two ZonedDateTime instances
pub fn compare(a: ZonedDateTime, b: ZonedDateTime) i8 {
    return abi.c.temporal_rs_ZonedDateTime_compare_instant(a._inner, b._inner);
}

/// Add a duration
pub fn add(self: ZonedDateTime, duration: Duration) !ZonedDateTime {
    const overflow_opt = abi.toOption(abi.c.ArithmeticOverflow_option, null);
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_add(self._inner, duration._inner, overflow_opt));
}

/// Check equality
pub fn equals(self: ZonedDateTime, other: ZonedDateTime) bool {
    return abi.c.temporal_rs_ZonedDateTime_equals(self._inner, other._inner);
}

/// Get the time zone transition
pub fn getTimeZoneTransition(self: ZonedDateTime, direction: enum { next, previous }) !?ZonedDateTime {
    const dir = switch (direction) {
        .next => abi.c.TransitionDirection_Next,
        .previous => abi.c.TransitionDirection_Previous,
    };
    const result = abi.c.temporal_rs_ZonedDateTime_get_time_zone_transition(self._inner, dir);
    const maybe_ptr = try abi.extractResult(result);
    if (maybe_ptr) |ptr| {
        return .{ ._inner = ptr };
    }
    return null;
}

/// Round to the given options
pub fn round(self: ZonedDateTime, options: RoundOptions) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_round(self._inner, abi.to.roundingOpts(options)));
}

/// Calculate duration since another ZonedDateTime
pub fn since(self: ZonedDateTime, other: ZonedDateTime, settings: DifferenceSettings) !Duration {
    const ptr = try abi.extractResult(abi.c.temporal_rs_ZonedDateTime_since(self._inner, other._inner, abi.to.diffsettings(settings)));
    return .{ ._inner = ptr };
}

/// Get the start of the day
pub fn startOfDay(self: ZonedDateTime) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_start_of_day(self._inner));
}

/// Subtract a duration
pub fn subtract(self: ZonedDateTime, duration: Duration) !ZonedDateTime {
    const overflow_opt = abi.toOption(abi.c.ArithmeticOverflow_option, null);
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_subtract(self._inner, duration._inner, overflow_opt));
}

/// Convert to Instant
pub fn toInstant(self: ZonedDateTime) !Instant {
    const instant_ptr = abi.c.temporal_rs_ZonedDateTime_to_instant(self._inner) orelse return error.TemporalError;
    return .{ ._inner = instant_ptr };
}

/// Convert to JSON string (ISO 8601 format)
pub fn toJSON(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Convert to locale string (placeholder - returns ISO string)
pub fn toLocaleString(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Convert to PlainDate
pub fn toPlainDate(self: ZonedDateTime) !PlainDate {
    const ptr = abi.c.temporal_rs_ZonedDateTime_to_plain_date(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Convert to PlainDateTime
pub fn toPlainDateTime(self: ZonedDateTime) !PlainDateTime {
    const ptr = abi.c.temporal_rs_ZonedDateTime_to_plain_datetime(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Convert to PlainTime
pub fn toPlainTime(self: ZonedDateTime) !PlainTime {
    const ptr = abi.c.temporal_rs_ZonedDateTime_to_plain_time(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Convert to string with options
pub fn toString(self: ZonedDateTime, allocator: std.mem.Allocator, opts: ToStringOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const result = abi.c.temporal_rs_ZonedDateTime_to_ixdtf_string(
        self._inner,
        abi.to.displayOffset(opts.offset_display),
        abi.to.toDisplayTimeZone(opts.time_zone_name),
        abi.to.calendarDisplay(opts.calendar_display),
        abi.to_string_rounding_options_auto,
        &write.inner,
    );

    if (!result.is_ok) return error.TemporalError;
    return try write.toOwnedSlice();
}

/// Calculate duration until another ZonedDateTime
pub fn until(self: ZonedDateTime, other: ZonedDateTime, settings: DifferenceSettings) !Duration {
    const ptr = try abi.extractResult(abi.c.temporal_rs_ZonedDateTime_until(self._inner, other._inner, abi.to.diffsettings(settings)));
    return .{ ._inner = ptr };
}

/// valueOf() is not supported for ZonedDateTime
pub fn valueOf(_: ZonedDateTime) !void {
    return error.ValueOfNotSupported;
}

/// Create a new ZonedDateTime with some fields changed
pub fn with(self: ZonedDateTime, allocator: std.mem.Allocator, fields: anytype) !ZonedDateTime {
    _ = allocator;
    _ = fields;
    _ = self;
    return error.Todo; // Need PartialZonedDateTime mapping
}

/// Create a new ZonedDateTime with a different calendar
pub fn withCalendar(self: ZonedDateTime, calendar: []const u8) !ZonedDateTime {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);
    const ptr = abi.c.temporal_rs_ZonedDateTime_with_calendar(self._inner, cal_kind);
    return .{ ._inner = ptr, .calendar_id = calendar };
}

/// Create a new ZonedDateTime with a different time
pub fn withPlainTime(self: ZonedDateTime, time: ?PlainTime) !ZonedDateTime {
    const time_ptr = if (time) |tt| tt._inner else null;
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_with_plain_time(self._inner, time_ptr));
}

/// Create a new ZonedDateTime with a different time zone
pub fn withTimeZone(self: ZonedDateTime, time_zone: TimeZone) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_rs_ZonedDateTime_with_timezone(self._inner, abi.to.toTimeZone(time_zone)));
}

// Property accessors
pub fn calendarId(self: ZonedDateTime) []const u8 {
    return self.calendar_id;
}

pub fn day(self: ZonedDateTime) u8 {
    return abi.c.temporal_rs_ZonedDateTime_day(self._inner);
}

pub fn dayOfWeek(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_day_of_week(self._inner);
}

pub fn dayOfYear(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_day_of_year(self._inner);
}

pub fn daysInMonth(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_days_in_month(self._inner);
}

pub fn daysInWeek(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_days_in_week(self._inner);
}

pub fn daysInYear(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_days_in_year(self._inner);
}

pub fn epochMilliseconds(self: ZonedDateTime) i64 {
    return abi.c.temporal_rs_ZonedDateTime_epoch_milliseconds(self._inner);
}

pub fn epochNanoseconds(self: ZonedDateTime) i128 {
    const parts = abi.c.temporal_rs_ZonedDateTime_epoch_nanoseconds(self._inner);
    return abi.fromI128Nanoseconds(parts);
}

pub fn era(self: ZonedDateTime, allocator: std.mem.Allocator) !?[]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    abi.c.temporal_rs_ZonedDateTime_era(self._inner, &write.inner);
    const result = try write.toOwnedSlice();
    if (result.len == 0) {
        allocator.free(result);
        return null;
    }
    return result;
}

pub fn eraYear(self: ZonedDateTime) ?i32 {
    const result = abi.c.temporal_rs_ZonedDateTime_era_year(self._inner);
    return abi.fromOption(result);
}

pub fn hour(self: ZonedDateTime) u8 {
    return abi.c.temporal_rs_ZonedDateTime_hour(self._inner);
}

pub fn hoursInDay(self: ZonedDateTime) !f64 {
    const result = abi.c.temporal_rs_ZonedDateTime_hours_in_day(self._inner);
    return try abi.extractResult(result);
}

pub fn inLeapYear(self: ZonedDateTime) bool {
    return abi.c.temporal_rs_ZonedDateTime_in_leap_year(self._inner);
}

pub fn microsecond(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_microsecond(self._inner);
}

pub fn millisecond(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_millisecond(self._inner);
}

pub fn minute(self: ZonedDateTime) u8 {
    return abi.c.temporal_rs_ZonedDateTime_minute(self._inner);
}

pub fn month(self: ZonedDateTime) u8 {
    return abi.c.temporal_rs_ZonedDateTime_month(self._inner);
}

pub fn monthCode(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    abi.c.temporal_rs_ZonedDateTime_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

pub fn monthsInYear(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_months_in_year(self._inner);
}

pub fn nanosecond(self: ZonedDateTime) u16 {
    return abi.c.temporal_rs_ZonedDateTime_nanosecond(self._inner);
}

pub fn offset(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    const res = abi.c.temporal_rs_ZonedDateTime_offset(self._inner, &write.inner);
    _ = try abi.extractResult(res);
    return try write.toOwnedSlice();
}

pub fn offsetNanoseconds(self: ZonedDateTime) i64 {
    return abi.c.temporal_rs_ZonedDateTime_offset_nanoseconds(self._inner);
}

pub fn second(self: ZonedDateTime) u8 {
    return abi.c.temporal_rs_ZonedDateTime_second(self._inner);
}

pub fn timeZoneId(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    const tz = abi.c.temporal_rs_ZonedDateTime_timezone(self._inner);
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_TimeZone_identifier(tz, &write.inner);

    return try write.toOwnedSlice();
}

pub fn weekOfYear(self: ZonedDateTime) ?u8 {
    const result = abi.c.temporal_rs_ZonedDateTime_week_of_year(self._inner);
    return abi.fromOption(result);
}

pub fn year(self: ZonedDateTime) i32 {
    return abi.c.temporal_rs_ZonedDateTime_year(self._inner);
}

pub fn yearOfWeek(self: ZonedDateTime) ?i32 {
    const result = abi.c.temporal_rs_ZonedDateTime_year_of_week(self._inner);
    return abi.fromOption(result);
}

/// Clone this ZonedDateTime
pub fn clone(self: ZonedDateTime) ZonedDateTime {
    const ptr = abi.c.temporal_rs_ZonedDateTime_clone(self._inner);
    return .{ ._inner = ptr };
}

/// Free the ZonedDateTime
pub fn deinit(self: ZonedDateTime) void {
    abi.c.temporal_rs_ZonedDateTime_destroy(self._inner);
}

// ---------- Tests ---------------------
test init {
    const tz = try TimeZone.init("America/New_York");
    const zdt = try init(0, tz);
    defer zdt.deinit();

    try std.testing.expectEqual(@as(i64, 0), zdt.epochMilliseconds());
}

test fromEpochMilliseconds {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz); // 2021-01-01T00:00:00Z
    defer zdt.deinit();

    try std.testing.expectEqual(@as(i64, 1609459200000), zdt.epochMilliseconds());
}

test from {
    const zdt = try from("2021-01-01T00:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    try std.testing.expectEqual(@as(i32, 2021), zdt.year());
    try std.testing.expectEqual(@as(u8, 1), zdt.month());
    try std.testing.expectEqual(@as(u8, 1), zdt.day());
}

test compare {
    const tz = try TimeZone.init("UTC");
    const zdt1 = try fromEpochMilliseconds(1000, tz);
    defer zdt1.deinit();
    const zdt2 = try fromEpochMilliseconds(2000, tz);
    defer zdt2.deinit();

    try std.testing.expect(compare(zdt1, zdt2) < 0);
    try std.testing.expect(compare(zdt2, zdt1) > 0);
    try std.testing.expect(compare(zdt1, zdt1) == 0);
}

test equals {
    const tz = try TimeZone.init("UTC");
    const zdt1 = try fromEpochMilliseconds(1000, tz);
    defer zdt1.deinit();
    const zdt2 = try fromEpochMilliseconds(1000, tz);
    defer zdt2.deinit();
    const zdt3 = try fromEpochMilliseconds(2000, tz);
    defer zdt3.deinit();

    try std.testing.expect(zdt1.equals(zdt2));
    try std.testing.expect(!zdt1.equals(zdt3));
}

test toInstant {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();

    const instant = try zdt.toInstant();
    defer instant.deinit();

    try std.testing.expectEqual(@as(i64, 1609459200000), instant.epochMilliseconds());
}

test toPlainDate {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();

    const pd = try zdt.toPlainDate();
    defer pd.deinit();

    try std.testing.expectEqual(@as(i32, 2021), pd.year());
    try std.testing.expectEqual(@as(u8, 1), pd.month());
    try std.testing.expectEqual(@as(u8, 1), pd.day());
}

test toPlainDateTime {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();

    var pdt = try zdt.toPlainDateTime();
    defer pdt.deinit();

    try std.testing.expectEqual(@as(i32, 2021), pdt.year());
    try std.testing.expectEqual(@as(u8, 1), pdt.month());
    try std.testing.expectEqual(@as(u8, 1), pdt.day());
}

test toPlainTime {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();

    const pt = try zdt.toPlainTime();
    defer abi.c.temporal_rs_PlainTime_destroy(pt._inner);

    try std.testing.expectEqual(@as(u8, 0), pt.hour());
    try std.testing.expectEqual(@as(u8, 0), pt.minute());
}

test toString {
    const zdt = try from("2021-01-01T00:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const str = try zdt.toString(std.testing.allocator, .{});
    defer std.testing.allocator.free(str);

    try std.testing.expect(str.len > 0);
    try std.testing.expectEqualStrings("2021-01-01T00:00:00+00:00[UTC]", str);
}

test "props" {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();

    try std.testing.expectEqual(@as(i32, 2021), zdt.year());
    try std.testing.expectEqual(@as(u8, 1), zdt.month());
    try std.testing.expectEqual(@as(u8, 1), zdt.day());
    try std.testing.expectEqual(@as(u8, 0), zdt.hour());
    try std.testing.expectEqual(@as(u8, 0), zdt.minute());
    try std.testing.expectEqual(@as(u8, 0), zdt.second());
    try std.testing.expectEqual(@as(u16, 0), zdt.millisecond());

    const tzo = try zdt.timeZoneId(std.testing.allocator);
    defer std.testing.allocator.free(tzo);
    try std.testing.expectEqualStrings("UTC", tzo);
}
