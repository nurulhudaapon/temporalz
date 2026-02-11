const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const PlainDate = @import("PlainDate.zig");
const PlainTime = @import("PlainTime.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");
const Duration = @import("Duration.zig");

/// # Temporal.PlainDateTime
///
/// The `Temporal.PlainDateTime` object represents a calendar date and wall-clock time, but no time zone or offset.
///
/// - [MDN Temporal.PlainDateTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDateTime)
/// The `Temporal.PlainDateTime` object represents a calendar date and wall-clock time, but no time zone or offset.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDateTime
const PlainDateTime = @This();

/// Internal pointer to the underlying C PlainDateTime object.
_inner: *abi.c.PlainDateTime,

/// Units used for date and time calculations.
pub const Unit = t.Unit;
/// Rounding modes for date/time operations.
pub const RoundingMode = t.RoundingMode;
/// Sign type for durations.
pub const Sign = t.Sign;
/// Settings for difference calculations between date-times.
pub const DifferenceSettings = t.DifferenceSettings;
/// Options for rounding operations.
pub const RoundOptions = t.RoundingOptions;

/// Controls how the calendar is displayed in string output.
pub const CalendarDisplay = enum {
    /// Display calendar only if not ISO.
    auto,
    /// Always display calendar.
    always,
    /// Never display calendar.
    never,
    /// Display calendar as a critical flag.
    critical,
};

/// Options for `toString()` method.
pub const ToStringOptions = struct {
    /// Number of fractional second digits to include.
    fractional_second_digits: ?u8 = null,
    /// The smallest unit to include in the output.
    smallest_unit: ?Unit = null,
    /// Rounding mode for the output.
    rounding_mode: ?RoundingMode = null,
    /// How to display the calendar in the output.
    calendar_display: ?CalendarDisplay = null,
};

/// Options for `toZonedDateTime()` method.
pub const ToZonedDateTimeOptions = struct {
    /// The time zone identifier (IANA string).
    timeZone: []const u8,
    /// Disambiguation option for ambiguous times.
    disambiguation: ?[]const u8 = null,
};

/// Options for `with()` method.
pub const WithOptions = struct {
    /// Year value to override.
    year: ?i32 = null,
    /// Month value to override.
    month: ?u8 = null,
    /// Day value to override.
    day: ?u8 = null,
    /// Hour value to override.
    hour: ?u8 = null,
    /// Minute value to override.
    minute: ?u8 = null,
    /// Second value to override.
    second: ?u8 = null,
    /// Millisecond value to override.
    millisecond: ?u16 = null,
    /// Microsecond value to override.
    microsecond: ?u16 = null,
    /// Nanosecond value to override.
    nanosecond: ?u16 = null,
};

const FromOptions = struct {
    overflow: ?Overflow = null,
};

const Overflow = enum {
    constrain,
    reject,
};

const PartialDateTime = struct {
    // Date fields (recognized by PlainDate.from)
    calendar: ?[]const u8 = null,
    era: ?[]const u8 = null,
    eraYear: ?u32 = null,
    year: ?i32 = null,
    month: ?u8 = null,
    monthCode: ?[]const u8 = null,
    day: ?u8 = null,
    // Time fields (recognized by PlainTime.from)
    hour: ?u8 = null,
    minute: ?u8 = null,
    second: ?u8 = null,
    millisecond: ?u16 = null,
    microsecond: ?u16 = null,
    nanosecond: ?u16 = null,
};

/// Creates a new PlainDateTime with all date and time components.
pub fn init(
    year_val: i32,
    month_val: u8,
    day_val: u8,
    hour_val: u8,
    minute_val: u8,
    second_val: u8,
    millisecond_val: u16,
    microsecond_val: u16,
    nanosecond_val: u16,
) !PlainDateTime {
    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_try_new(
        year_val,
        month_val,
        day_val,
        hour_val,
        minute_val,
        second_val,
        millisecond_val,
        microsecond_val,
        nanosecond_val,
        abi.c.AnyCalendarKind_Iso,
    ));
}

/// Creates a new PlainDateTime with a specific calendar.
/// - `calendar`: Calendar identifier string (e.g., "iso8601").
pub fn calInit(
    year_val: i32,
    month_val: u8,
    day_val: u8,
    hour_val: u8,
    minute_val: u8,
    second_val: u8,
    millisecond_val: u16,
    microsecond_val: u16,
    nanosecond_val: u16,
    calendar: []const u8,
) !PlainDateTime {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);
    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_try_new(
        year_val,
        month_val,
        day_val,
        hour_val,
        minute_val,
        second_val,
        millisecond_val,
        microsecond_val,
        nanosecond_val,
        cal_kind,
    ));
}

const FromInit = union(enum) { plain_date: PlainDate, plain_date_time: PlainDateTime };

/// Creates a PlainDateTime from another PlainDateTime, PlainDate, PlainTime, or from a string (ISO 8601) or UTF-16 array.
pub fn from(info: anytype, opts: FromOptions) !PlainDateTime {
    const T = @TypeOf(info);

    const overflow = if (opts.overflow) |f| abi.to.toArithmeticOverflow(f) else null;
    if (T == PlainDateTime) return info.clone();
    if (T == PlainTime) return abi.c.temporal_rs_PlainDateTime_from_partial(.{ .time = info._inner }, abi.toArithmeticOverflowOption(overflow));
    if (T == PlainDate) return abi.c.temporal_rs_PlainDateTime_from_partial(.{ .date = info._inner }, abi.toArithmeticOverflowOption(overflow));

    // Handle string types (both literals and slices)
    const type_info = @typeInfo(T);
    switch (type_info) {
        .pointer => |ptr_info| {
            const ChildType = switch (@typeInfo(ptr_info.child)) {
                .array => |arr| arr.child,
                else => ptr_info.child,
            };

            if (ChildType == u8) return fromUtf8(info);
            if (ChildType == u16) return fromUtf16(info);
            return abi.TemporalError.Generic;
        },
        else => return abi.TemporalError.Generic,
    }
}

fn fromUtf8(utf8: []const u8) !PlainDateTime {
    const view = abi.toDiplomatStringView(utf8);
    const parsed = abi.c.temporal_rs_ParsedDateTime_from_utf8(view);
    const ptr = try abi.extractResult(parsed);
    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_from_parsed(ptr));
}

fn fromUtf16(utf16: []const u16) !PlainDateTime {
    const view = abi.toDiplomatString16View(utf16);
    const parsed = abi.c.temporal_rs_ParsedDateTime_from_utf16(view);
    const ptr = try abi.extractResult(parsed);
    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_from_parsed(ptr));
}

/// Compares two PlainDateTime objects. Returns -1, 0, or 1.
pub fn compare(a: PlainDateTime, b: PlainDateTime) i8 {
    return abi.c.temporal_rs_PlainDateTime_compare(a._inner, b._inner);
}

/// Returns true if two PlainDateTime objects represent the same date and time.
pub fn equals(self: PlainDateTime, other: PlainDateTime) bool {
    return compare(self, other) == 0;
}

/// Returns a new PlainDateTime by adding a Duration to this date-time.
pub fn add(self: PlainDateTime, duration: Duration) !PlainDateTime {
    const overflow_opt = abi.c.ArithmeticOverflow_option{
        .is_ok = true,
        .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain },
    };

    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_add(self._inner, duration._inner, overflow_opt));
}

/// Returns a new PlainDateTime by subtracting a Duration from this date-time.
pub fn subtract(self: PlainDateTime, duration: Duration) !PlainDateTime {
    const overflow_opt = abi.c.ArithmeticOverflow_option{
        .is_ok = true,
        .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain },
    };
    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_subtract(self._inner, duration._inner, overflow_opt));
}

/// Returns the Duration until another PlainDateTime, according to the given settings.
pub fn until(self: PlainDateTime, other: PlainDateTime, options: DifferenceSettings) !Duration {
    const result = abi.c.temporal_rs_PlainDateTime_until(self._inner, other._inner, abi.to.diffsettings(options));
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns the Duration since another PlainDateTime, according to the given settings.
pub fn since(self: PlainDateTime, other: PlainDateTime, options: DifferenceSettings) !Duration {
    const result = abi.c.temporal_rs_PlainDateTime_since(self._inner, other._inner, abi.to.diffsettings(options));
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns a new PlainDateTime rounded according to the given options.
pub fn round(self: PlainDateTime, options: RoundOptions) !PlainDateTime {
    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_round(self._inner, abi.to.roundingOpts(options)));
}

/// Returns the calendar identifier for this date-time.
pub fn calendarId(self: PlainDateTime, allocator: std.mem.Allocator) ![]u8 {
    const calendar_ptr = abi.c.temporal_rs_PlainDateTime_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);
    return try allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]);
}

/// Returns the day of the month (1-31).
pub fn day(self: PlainDateTime) u8 {
    return abi.c.temporal_rs_PlainDateTime_day(self._inner);
}

/// Returns the day of the week (1 = Monday, 7 = Sunday).
pub fn dayOfWeek(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_day_of_week(self._inner);
}

/// Returns the day of the year (1-366).
pub fn dayOfYear(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_day_of_year(self._inner);
}

/// Returns the number of days in the month for this date-time.
pub fn daysInMonth(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_days_in_month(self._inner);
}

/// Returns the number of days in the week for this date-time.
pub fn daysInWeek(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_days_in_week(self._inner);
}

/// Returns the number of days in the year for this date-time.
pub fn daysInYear(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_days_in_year(self._inner);
}

/// Returns the month (1-12).
pub fn month(self: PlainDateTime) u8 {
    return abi.c.temporal_rs_PlainDateTime_month(self._inner);
}

/// Returns the month code (e.g., "M03").
pub fn monthCode(self: PlainDateTime, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    abi.c.temporal_rs_PlainDateTime_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

/// Returns the number of months in the year for this date-time.
pub fn monthsInYear(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_months_in_year(self._inner);
}

/// Returns the year.
pub fn year(self: PlainDateTime) i32 {
    return abi.c.temporal_rs_PlainDateTime_year(self._inner);
}

/// Returns true if the year is a leap year.
pub fn inLeapYear(self: PlainDateTime) bool {
    return abi.c.temporal_rs_PlainDateTime_in_leap_year(self._inner);
}

/// Returns the era for this date-time, if any.
pub fn era(self: PlainDateTime, allocator: std.mem.Allocator) !?[]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    abi.c.temporal_rs_PlainDateTime_era(self._inner, &write.inner);
    const result = try write.toOwnedSlice();
    if (result.len == 0) {
        allocator.free(result);
        return null;
    }
    return result;
}

/// Returns the era year for this date-time, if any.
pub fn eraYear(self: PlainDateTime) !?i32 {
    const result = abi.c.temporal_rs_PlainDateTime_era_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

/// Returns the week of the year for this date-time, if any.
pub fn weekOfYear(self: PlainDateTime) !?u16 {
    const result = abi.c.temporal_rs_PlainDateTime_week_of_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

/// Returns the year of the week for this date-time, if any.
pub fn yearOfWeek(self: PlainDateTime) !?i32 {
    const result = abi.c.temporal_rs_PlainDateTime_year_of_week(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

/// Returns the hour (0-23).
pub fn hour(self: PlainDateTime) u8 {
    return abi.c.temporal_rs_PlainDateTime_hour(self._inner);
}

/// Returns the minute (0-59).
pub fn minute(self: PlainDateTime) u8 {
    return abi.c.temporal_rs_PlainDateTime_minute(self._inner);
}

/// Returns the second (0-59).
pub fn second(self: PlainDateTime) u8 {
    return abi.c.temporal_rs_PlainDateTime_second(self._inner);
}

/// Returns the millisecond (0-999).
pub fn millisecond(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_millisecond(self._inner);
}

/// Returns the microsecond (0-999).
pub fn microsecond(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_microsecond(self._inner);
}

/// Returns the nanosecond (0-999).
pub fn nanosecond(self: PlainDateTime) u16 {
    return abi.c.temporal_rs_PlainDateTime_nanosecond(self._inner);
}

/// Returns a new PlainDateTime with some fields replaced.
pub fn with(self: PlainDateTime, partial: WithOptions) !PlainDateTime {
    // Extract fields from partial, or use current values as defaults
    const new_year = partial.year orelse self.year();
    const new_month = partial.month orelse self.month();
    const new_day = partial.day orelse self.day();
    const new_hour = partial.hour orelse self.hour();
    const new_minute = partial.minute orelse self.minute();
    const new_second = partial.second orelse self.second();
    const new_millisecond = partial.millisecond orelse self.millisecond();
    const new_microsecond = partial.microsecond orelse self.microsecond();
    const new_nanosecond = partial.nanosecond orelse self.nanosecond();

    // Preserve calendar
    const calendar_ptr = abi.c.temporal_rs_PlainDateTime_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);
    const cal_view = abi.c.DiplomatStringView{ .data = cal_id_view.data, .len = cal_id_view.len };
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);

    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_try_new(
        new_year,
        new_month,
        new_day,
        new_hour,
        new_minute,
        new_second,
        new_millisecond,
        new_microsecond,
        new_nanosecond,
        cal_kind,
    ));
}

/// Returns a new PlainDateTime with a different calendar.
pub fn withCalendar(self: PlainDateTime, calendar: []const u8) !PlainDateTime {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);
    const ptr = abi.c.temporal_rs_PlainDateTime_with_calendar(self._inner, cal_kind) orelse return abi.TemporalError.Generic;

    return .{ ._inner = ptr };
}

/// Returns a new PlainDateTime with the time fields replaced by the given PlainTime (or zeroed if null).
pub fn withPlainTime(self: PlainDateTime, time: ?PlainTime) !PlainDateTime {
    const new_hour: u8 = if (time) |tt| tt.hour() else 0;
    const new_minute: u8 = if (time) |tt| tt.minute() else 0;
    const new_second: u8 = if (time) |tt| tt.second() else 0;
    const new_millisecond: u16 = if (time) |tt| tt.millisecond() else 0;
    const new_microsecond: u16 = if (time) |tt| tt.microsecond() else 0;
    const new_nanosecond: u16 = if (time) |tt| tt.nanosecond() else 0;

    const calendar_ptr = abi.c.temporal_rs_PlainDateTime_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);
    const cal_view = abi.c.DiplomatStringView{ .data = cal_id_view.data, .len = cal_id_view.len };
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);

    return wrapPlainDateTime(abi.c.temporal_rs_PlainDateTime_try_new(
        self.year(),
        self.month(),
        self.day(),
        new_hour,
        new_minute,
        new_second,
        new_millisecond,
        new_microsecond,
        new_nanosecond,
        cal_kind,
    ));
}

/// Returns a PlainDate representing the date part of this PlainDateTime.
pub fn toPlainDate(self: PlainDateTime) !PlainDate {
    const ptr = abi.c.temporal_rs_PlainDateTime_to_plain_date(self._inner) orelse return error.TemporalError;

    return .{ ._inner = ptr };
}

/// Returns a PlainTime representing the time part of this PlainDateTime.
pub fn toPlainTime(self: PlainDateTime) !PlainTime {
    const ptr = abi.c.temporal_rs_PlainDateTime_to_plain_time(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Returns a ZonedDateTime by combining this date-time with a time zone.
pub fn toZonedDateTime(self: PlainDateTime, options: ToZonedDateTimeOptions) !ZonedDateTime {
    const tz_view = abi.toDiplomatStringView(options.timeZone);
    const tz_result = abi.c.temporal_rs_TimeZone_try_from_str(tz_view);
    const time_zone = try abi.extractResult(tz_result);

    // Convert to PlainDate and PlainTime
    const date = try self.toPlainDate();
    const time = try self.toPlainTime();

    // Use PlainDate's toZonedDateTime with the time component
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_to_zoned_date_time(date._inner, time_zone, time._inner))) orelse return abi.TemporalError.Generic;

    return .{ ._inner = ptr };
}

/// Returns a string representation of the date-time.
pub fn toString(self: PlainDateTime, allocator: std.mem.Allocator, options: ToStringOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const rounding_options = std.mem.zeroes(abi.c.ToStringRoundingOptions);

    const display_cal: abi.c.DisplayCalendar = if (options.calendar_display) |cal| switch (cal) {
        .auto => @intCast(abi.c.DisplayCalendar_Auto),
        .always => @intCast(abi.c.DisplayCalendar_Always),
        .never => @intCast(abi.c.DisplayCalendar_Never),
        .critical => @intCast(abi.c.DisplayCalendar_Critical),
    } else @intCast(abi.c.DisplayCalendar_Auto);

    const result = abi.c.temporal_rs_PlainDateTime_to_ixdtf_string(
        self._inner,
        rounding_options,
        display_cal,
        &write.inner,
    );

    if (!result.is_ok) return error.TemporalError;
    return try write.toOwnedSlice();
}

/// Returns a string suitable for use as JSON.
pub fn toJSON(self: PlainDateTime, allocator: std.mem.Allocator) ![]u8 {
    return try self.toString(allocator, .{});
}

/// Returns a locale-specific string representation of the date-time.
pub fn toLocaleString(self: PlainDateTime, allocator: std.mem.Allocator) []const u8 {
    const s = self.toString(allocator, .{}) catch return "PlainDateTime.toLocaleString error";
    return s;
}

/// Not supported. Throws ComparisonNotSupported error.
pub fn valueOf(self: PlainDateTime) !void {
    _ = self;
    return error.ComparisonNotSupported;
}

/// Returns a clone of this PlainDateTime.
fn clone(self: PlainDateTime) PlainDateTime {
    return abi.c.temporal_rs_PlainDateTime_clone(self._inner);
}

/// Frees resources associated with this PlainDateTime.
pub fn deinit(self: *PlainDateTime) void {
    abi.c.temporal_rs_PlainDateTime_destroy(self._inner);
}

/// Internal: Wraps a result as a PlainDateTime.
fn wrapPlainDateTime(res: anytype) !PlainDateTime {
    const ptr = (try abi.extractResult(res)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

// ---------- Tests ---------------------
test init {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(i32, 2024), dt.year());
    try std.testing.expectEqual(@as(u8, 1), dt.month());
    try std.testing.expectEqual(@as(u8, 15), dt.day());
    try std.testing.expectEqual(@as(u8, 14), dt.hour());
    try std.testing.expectEqual(@as(u8, 30), dt.minute());
    try std.testing.expectEqual(@as(u8, 45), dt.second());
}

test from {
    const dt = try PlainDateTime.from("2024-01-15T14:30:45", .{});
    try std.testing.expectEqual(@as(i32, 2024), dt.year());
    try std.testing.expectEqual(@as(u8, 1), dt.month());
    try std.testing.expectEqual(@as(u8, 15), dt.day());
}

test compare {
    const dt1 = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dt2 = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dt3 = try PlainDateTime.init(2024, 1, 16, 14, 30, 0, 0, 0, 0);

    try std.testing.expectEqual(@as(i8, 0), PlainDateTime.compare(dt1, dt2));
    try std.testing.expectEqual(@as(i8, -1), PlainDateTime.compare(dt1, dt3));
    try std.testing.expectEqual(@as(i8, 1), PlainDateTime.compare(dt3, dt1));
}

test equals {
    const dt1 = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dt2 = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dt3 = try PlainDateTime.init(2024, 1, 16, 14, 30, 0, 0, 0, 0);

    try std.testing.expect(dt1.equals(dt2));
    try std.testing.expect(!dt1.equals(dt3));
}

test add {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dur = try Duration.from("P1D");
    const result = try dt.add(dur);

    try std.testing.expectEqual(@as(u8, 16), result.day());
}

test subtract {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dur = try Duration.from("P1D");
    const result = try dt.subtract(dur);

    try std.testing.expectEqual(@as(u8, 14), result.day());
}

test until {
    const dt1 = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dt2 = try PlainDateTime.init(2024, 1, 16, 14, 30, 0, 0, 0, 0);
    const dur = try dt1.until(dt2, .{});

    try std.testing.expectEqual(@as(i64, 1), dur.days());
}

test since {
    const dt1 = try PlainDateTime.init(2024, 1, 16, 14, 30, 0, 0, 0, 0);
    const dt2 = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const dur = try dt1.since(dt2, .{});

    try std.testing.expectEqual(@as(i64, 1), dur.days());
}

test round {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 999, 999, 999);
    const rounded = try dt.round(.{ .smallest_unit = .second });

    try std.testing.expectEqual(@as(u8, 46), rounded.second());
    try std.testing.expectEqual(@as(u16, 0), rounded.millisecond());
    try std.testing.expectEqual(@as(u16, 0), rounded.microsecond());
    try std.testing.expectEqual(@as(u16, 0), rounded.nanosecond());
}

test toString {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 0, 0);
    const str = try dt.toString(std.testing.allocator, .{});
    defer std.testing.allocator.free(str);

    try std.testing.expect(std.mem.indexOf(u8, str, "2024-01-15") != null);
    try std.testing.expect(std.mem.indexOf(u8, str, "14:30:45") != null);
}

test toJSON {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 0, 0, 0);
    const str = try dt.toJSON(std.testing.allocator);
    defer std.testing.allocator.free(str);

    try std.testing.expect(std.mem.indexOf(u8, str, "2024-01-15") != null);
}

test toLocaleString {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 0, 0, 0);
    const s_const = dt.toLocaleString(std.testing.allocator);
    const s = @constCast(s_const);
    defer std.testing.allocator.free(s);
    try std.testing.expect(std.mem.indexOf(u8, s, "2024-01-15") != null);
}

test toPlainDate {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const date = try dt.toPlainDate();

    try std.testing.expectEqual(@as(i32, 2024), date.year());
    try std.testing.expectEqual(@as(u8, 1), date.month());
    try std.testing.expectEqual(@as(u8, 15), date.day());
}

test toPlainTime {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 0, 0, 0);
    const tt = try dt.toPlainTime();
    try std.testing.expectEqual(@as(u8, 14), tt.hour());
    try std.testing.expectEqual(@as(u8, 30), tt.minute());
    try std.testing.expectEqual(@as(u8, 45), tt.second());
}

test toZonedDateTime {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const zdt = try dt.toZonedDateTime(.{ .timeZone = "UTC" });

    const pdt = try zdt.toPlainDateTime();
    try std.testing.expectEqual(@as(i32, 2024), pdt.year());
    try std.testing.expectEqual(@as(u8, 1), pdt.month());
    try std.testing.expectEqual(@as(u8, 15), pdt.day());
}

test with {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 0, 0, 0);
    const result = try dt.with(.{ .day = 20, .hour = 16 });
    try std.testing.expectEqual(@as(i32, 2024), result.year());
    try std.testing.expectEqual(@as(u8, 1), result.month());
    try std.testing.expectEqual(@as(u8, 20), result.day());
    try std.testing.expectEqual(@as(u8, 16), result.hour());
    try std.testing.expectEqual(@as(u8, 30), result.minute());
}

test withCalendar {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const result = try dt.withCalendar("iso8601");

    try std.testing.expectEqual(@as(i32, 2024), result.year());
    const cal_id = try result.calendarId(std.testing.allocator);
    defer std.testing.allocator.free(cal_id);
    try std.testing.expectEqualStrings("iso8601", cal_id);
}

test withPlainTime {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 0, 0, 0, 0);
    const tt = try PlainTime.from("10:15:30");
    const result = try dt.withPlainTime(tt);
    try std.testing.expectEqual(@as(u8, 10), result.hour());
    try std.testing.expectEqual(@as(u8, 15), result.minute());
    try std.testing.expectEqual(@as(u8, 30), result.second());
}

test calInit {
    const dt = try PlainDateTime.calInit(2024, 1, 15, 14, 30, 45, 123, 456, 789, "iso8601");
    try std.testing.expectEqual(@as(i32, 2024), dt.year());
}

test calendarId {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const cal_id = try dt.calendarId(std.testing.allocator);
    defer std.testing.allocator.free(cal_id);
    try std.testing.expectEqualStrings("iso8601", cal_id);
}

test day {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u8, 15), dt.day());
}

test dayOfWeek {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const dow = dt.dayOfWeek();
    try std.testing.expect(dow >= 1 and dow <= 7);
}

test dayOfYear {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const doy = dt.dayOfYear();
    try std.testing.expect(doy >= 1 and doy <= 366);
}

test daysInMonth {
    const dt = try PlainDateTime.init(2024, 2, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 29), dt.daysInMonth());
}

test daysInWeek {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 7), dt.daysInWeek());
}

test daysInYear {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 366), dt.daysInYear());
}

test month {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u8, 1), dt.month());
}

test monthCode {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const code = try dt.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(code);
    try std.testing.expectEqualStrings("M01", code);
}

test monthsInYear {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 12), dt.monthsInYear());
}

test year {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(i32, 2024), dt.year());
}

test inLeapYear {
    const leap = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expect(leap.inLeapYear());

    const non_leap = try PlainDateTime.init(2023, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expect(!non_leap.inLeapYear());
}

test era {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const e = try dt.era(std.testing.allocator);
    if (e) |era_val| {
        defer std.testing.allocator.free(era_val);
        try std.testing.expect(era_val.len > 0);
    }
}

test eraYear {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const ey = try dt.eraYear();
    if (ey) |y| {
        try std.testing.expect(y > 0);
    }
}

test weekOfYear {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const woy = try dt.weekOfYear();
    if (woy) |week| {
        try std.testing.expect(week >= 1 and week <= 53);
    }
}

test yearOfWeek {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    const yow = try dt.yearOfWeek();
    if (yow) |y| {
        try std.testing.expect(y >= 2020);
    }
}

test hour {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u8, 14), dt.hour());
}

test minute {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u8, 30), dt.minute());
}

test second {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u8, 45), dt.second());
}

test millisecond {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 123), dt.millisecond());
}

test microsecond {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 456), dt.microsecond());
}

test nanosecond {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectEqual(@as(u16, 789), dt.nanosecond());
}

test valueOf {
    const dt = try PlainDateTime.init(2024, 1, 15, 14, 30, 45, 123, 456, 789);
    try std.testing.expectError(error.ComparisonNotSupported, dt.valueOf());
}
