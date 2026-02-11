const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const PlainDateTime = @import("PlainDateTime.zig");
const PlainMonthDay = @import("PlainMonthDay.zig");
const PlainYearMonth = @import("PlainYearMonth.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const Duration = @import("Duration.zig");

/// # Temporal.PlainDate
///
/// The `Temporal.PlainDate` object represents a calendar date (year, month, day) with no time or time zone.
///
/// The `Temporal.PlainDate` object represents a calendar date (year, month, day) with no time or time zone.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/PlainDate
const PlainDate = @This();

/// Internal pointer to the underlying C PlainDate object.
_inner: *abi.c.PlainDate,

/// Units used for date and time calculations.
pub const Unit = t.Unit;
/// Rounding modes for date/time operations.
pub const RoundingMode = t.RoundingMode;
/// Sign type for durations.
pub const Sign = t.Sign;
/// Settings for difference calculations between dates.
pub const DifferenceSettings = t.DifferenceSettings;

/// Options for `toString()` method.
pub const ToStringOptions = struct {
    /// Controls how the calendar is displayed in the string output.
    calendar_id: ?CalendarDisplay = null,
};

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

/// Options for `toZonedDateTime()` method.
pub const ToZonedDateTimeOptions = struct {
    /// The time zone identifier (IANA string).
    time_zone: []const u8,
    /// Optional PlainTime to use for the time part.
    plain_time: ?PlainTime = null,
};

/// Creates a new PlainDate from the given ISO year, month, and day.
pub fn init(year_val: i32, month_val: u8, day_val: u8) !PlainDate {
    return calInit(year_val, month_val, day_val, "iso8601");
}

/// Creates a new PlainDate with a specific calendar.
/// - `calendar`: Calendar identifier string (e.g., "iso8601").
pub fn calInit(year_val: i32, month_val: u8, day_val: u8, calendar: []const u8) !PlainDate {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_try_new(year_val, month_val, day_val, cal_kind));
}

/// Creates a PlainDate from another PlainDate or from a string (ISO 8601) or UTF-16 array.
pub fn from(info: anytype) !PlainDate {
    const T = @TypeOf(info);

    if (T == PlainDate) return info.clone();

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
        else => @compileError("from() expects a PlainDate, []const u8, or []const u16"),
    }
}

/// Internal: Creates a PlainDate from a UTF-8 string.
inline fn fromUtf8(text: []const u8) !PlainDate {
    const view = abi.toDiplomatStringView(text);
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_from_utf8(view));
}

/// Internal: Creates a PlainDate from a UTF-16 string.
inline fn fromUtf16(text: []const u16) !PlainDate {
    const view = abi.toDiplomatString16View(text);
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_from_utf16(view));
}

/// Compares two PlainDate objects. Returns -1, 0, or 1.
pub fn compare(a: PlainDate, b: PlainDate) i8 {
    return abi.c.temporal_rs_PlainDate_compare(a._inner, b._inner);
}

/// Returns true if two PlainDate objects represent the same date.
pub fn equals(self: PlainDate, other: PlainDate) bool {
    return abi.c.temporal_rs_PlainDate_equals(self._inner, other._inner);
}

/// Returns a new PlainDate by adding a Duration to this date.
pub fn add(self: PlainDate, duration: Duration) !PlainDate {
    const overflow_opt = abi.c.ArithmeticOverflow_option{ .is_ok = true, .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain } };
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_add(self._inner, duration._inner, overflow_opt));
}

/// Returns a new PlainDate by subtracting a Duration from this date.
pub fn subtract(self: PlainDate, duration: Duration) !PlainDate {
    const overflow_opt = abi.c.ArithmeticOverflow_option{ .is_ok = true, .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain } };
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_subtract(self._inner, duration._inner, overflow_opt));
}

/// Returns the Duration until another PlainDate, according to the given settings.
pub fn until(self: PlainDate, other: PlainDate, settings: DifferenceSettings) !Duration {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_until(self._inner, other._inner, abi.to.diffsettings(settings)))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns the Duration since another PlainDate, according to the given settings.
pub fn since(self: PlainDate, other: PlainDate, settings: DifferenceSettings) !Duration {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_since(self._inner, other._inner, abi.to.diffsettings(settings)))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns a new PlainDate with some fields replaced (not implemented).
pub fn with(self: PlainDate, fields: anytype) !PlainDate {
    _ = self;
    _ = fields;
    return error.TemporalNotImplemented;
}

/// Returns a new PlainDate with a different calendar.
pub fn withCalendar(self: PlainDate, calendar: []const u8) !PlainDate {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);
    const ptr = abi.c.temporal_rs_PlainDate_with_calendar(self._inner, cal_kind) orelse return abi.TemporalError.Generic;

    return .{ ._inner = ptr };
}

/// Returns a PlainDateTime by combining this date with a PlainTime (or midnight if null).
pub fn toPlainDateTime(self: PlainDate, time: ?PlainTime) !PlainDateTime {
    const time_ptr = if (time) |tt| tt._inner else null;
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_to_plain_date_time(self._inner, time_ptr))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns a PlainMonthDay representing the month and day in this date.
pub fn toPlainMonthDay(self: PlainDate) !PlainMonthDay {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_to_plain_month_day(self._inner))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns a PlainYearMonth representing the year and month in this date.
pub fn toPlainYearMonth(self: PlainDate) !PlainYearMonth {
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_to_plain_year_month(self._inner))) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Returns a ZonedDateTime by combining this date with a time and time zone.
pub fn toZonedDateTime(self: PlainDate, options: ToZonedDateTimeOptions) !ZonedDateTime {
    const tz_view = abi.toDiplomatStringView(options.time_zone);
    const tz_result = abi.c.temporal_rs_TimeZone_try_from_str(tz_view);
    const time_zone = try abi.extractResult(tz_result);

    const time_ptr = if (options.plain_time) |tt| tt._inner else null;
    const ptr = (try abi.extractResult(abi.c.temporal_rs_PlainDate_to_zoned_date_time(self._inner, time_zone, time_ptr))) orelse return abi.TemporalError.Generic;

    return .{ ._inner = ptr };
}

/// Returns a string representation of the date.
pub fn toString(self: PlainDate, allocator: std.mem.Allocator, options: ToStringOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const display_cal: abi.c.DisplayCalendar = if (options.calendar_id) |cal| switch (cal) {
        .auto => @intCast(abi.c.DisplayCalendar_Auto),
        .always => @intCast(abi.c.DisplayCalendar_Always),
        .never => @intCast(abi.c.DisplayCalendar_Never),
        .critical => @intCast(abi.c.DisplayCalendar_Critical),
    } else @intCast(abi.c.DisplayCalendar_Auto);

    abi.c.temporal_rs_PlainDate_to_ixdtf_string(self._inner, display_cal, &write.inner);
    return try write.toOwnedSlice();
}

/// Returns a string suitable for use as JSON.
pub fn toJSON(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Not implemented. Throws TemporalNotImplemented error.
pub fn toLocaleString(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

/// Not supported. Throws TemporalValueOfNotSupported error.
pub fn valueOf(self: PlainDate) !void {
    _ = self;
    return error.TemporalValueOfNotSupported;
}

/// Returns the day of the month (1-31).
pub fn day(self: PlainDate) u8 {
    return abi.c.temporal_rs_PlainDate_day(self._inner);
}

/// Returns the day of the week (1 = Monday, 7 = Sunday).
pub fn dayOfWeek(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_day_of_week(self._inner);
}

/// Returns the day of the year (1-366).
pub fn dayOfYear(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_day_of_year(self._inner);
}

/// Returns the number of days in the month for this date.
pub fn daysInMonth(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_days_in_month(self._inner);
}

/// Returns the number of days in the week for this date.
pub fn daysInWeek(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_days_in_week(self._inner);
}

/// Returns the number of days in the year for this date.
pub fn daysInYear(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_days_in_year(self._inner);
}

/// Returns the month code (e.g., "M03").
pub fn monthCode(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_PlainDate_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

/// Returns the month (1-12).
pub fn month(self: PlainDate) u8 {
    return abi.c.temporal_rs_PlainDate_month(self._inner);
}

/// Returns the number of months in the year for this date.
pub fn monthsInYear(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_months_in_year(self._inner);
}

/// Returns the year.
pub fn year(self: PlainDate) i32 {
    return abi.c.temporal_rs_PlainDate_year(self._inner);
}

/// Returns true if the year is a leap year.
pub fn inLeapYear(self: PlainDate) bool {
    return abi.c.temporal_rs_PlainDate_in_leap_year(self._inner);
}

/// Returns the calendar identifier for this date.
pub fn calendarId(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    const calendar_ptr = abi.c.temporal_rs_PlainDate_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);
    return try allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]);
}

/// Returns the era for this date, if any.
pub fn era(self: PlainDate, allocator: std.mem.Allocator) !?[]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_PlainDate_era(self._inner, &write.inner);
    const result = try write.toOwnedSlice();
    if (result.len == 0) {
        allocator.free(result);
        return null;
    }
    return result;
}

/// Returns the era year for this date, if any.
pub fn eraYear(self: PlainDate) ?i32 {
    const result = abi.c.temporal_rs_PlainDate_era_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

/// Returns the week of the year for this date, if any.
pub fn weekOfYear(self: PlainDate) ?u8 {
    const result = abi.c.temporal_rs_PlainDate_week_of_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

/// Returns the year of the week for this date, if any.
pub fn yearOfWeek(self: PlainDate) ?i32 {
    const result = abi.c.temporal_rs_PlainDate_year_of_week(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

/// Returns a clone of this PlainDate.
fn clone(self: PlainDate) PlainDate {
    const ptr = abi.c.temporal_rs_PlainDate_clone(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Frees resources associated with this PlainDate.
pub fn deinit(self: PlainDate) void {
    abi.c.temporal_rs_PlainDate_destroy(self._inner);
}

/// Internal: Wraps a result as a PlainDate.
fn wrapPlainDate(res: anytype) !PlainDate {
    const ptr = (try abi.extractResult(res)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

/// Internal: Handles a void result from an FFI call.
fn handleVoidResult(res: anytype) !void {
    _ = try abi.extractResult(res);
}

test init {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    try std.testing.expectEqual(@as(i32, 2024), date.year());
    try std.testing.expectEqual(@as(u8, 3), date.month());
    try std.testing.expectEqual(@as(u8, 15), date.day());
}

test from {
    const date = try PlainDate.from("2024-03-15");
    defer date.deinit();

    try std.testing.expectEqual(@as(i32, 2024), date.year());
    try std.testing.expectEqual(@as(u8, 3), date.month());
    try std.testing.expectEqual(@as(u8, 15), date.day());

    const date2 = try PlainDate.from(date);
    defer date2.deinit();

    try std.testing.expect(PlainDate.equals(date, date2));
}

test compare {
    const date1 = try PlainDate.init(2024, 1, 1);
    defer date1.deinit();
    const date2 = try PlainDate.init(2024, 1, 1);
    defer date2.deinit();
    const date3 = try PlainDate.init(2024, 12, 31);
    defer date3.deinit();

    try std.testing.expectEqual(@as(i8, 0), PlainDate.compare(date1, date2));
    try std.testing.expectEqual(@as(i8, -1), PlainDate.compare(date1, date3));
    try std.testing.expectEqual(@as(i8, 1), PlainDate.compare(date3, date1));
}

test equals {
    const date1 = try PlainDate.init(2024, 3, 15);
    defer date1.deinit();
    const date2 = try PlainDate.init(2024, 3, 15);
    defer date2.deinit();
    const date3 = try PlainDate.init(2024, 3, 16);
    defer date3.deinit();

    try std.testing.expect(PlainDate.equals(date1, date2));
    try std.testing.expect(!PlainDate.equals(date1, date3));
}

test add {
    const date = try PlainDate.init(2024, 1, 1);
    defer date.deinit();

    var duration = try Duration.from("P1M");
    defer duration.deinit();

    const result = try date.add(duration);
    defer result.deinit();

    try std.testing.expectEqual(@as(i32, 2024), result.year());
    try std.testing.expectEqual(@as(u8, 2), result.month());
    try std.testing.expectEqual(@as(u8, 1), result.day());
}

test subtract {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    var duration = try Duration.from("P10D");
    defer duration.deinit();

    const result = try date.subtract(duration);
    defer result.deinit();

    try std.testing.expectEqual(@as(i32, 2024), result.year());
    try std.testing.expectEqual(@as(u8, 3), result.month());
    try std.testing.expectEqual(@as(u8, 5), result.day());
}

test until {
    const start = try PlainDate.init(2024, 1, 1);
    defer start.deinit();
    const end = try PlainDate.init(2024, 2, 1);
    defer end.deinit();

    const settings = DifferenceSettings{
        .largest_unit = .month,
        .smallest_unit = .day,
        .rounding_mode = .trunc,
        .rounding_increment = null,
    };

    const duration = try start.until(end, settings);
    defer duration.deinit();

    try std.testing.expectEqual(@as(i64, 1), duration.months());
}

test since {
    const end = try PlainDate.init(2024, 2, 1);
    defer end.deinit();
    const start = try PlainDate.init(2024, 1, 1);
    defer start.deinit();

    const settings = DifferenceSettings{
        .largest_unit = .month,
        .smallest_unit = .day,
        .rounding_mode = .trunc,
        .rounding_increment = null,
    };

    const duration = try end.since(start, settings);
    defer duration.deinit();

    try std.testing.expectEqual(@as(i64, 1), duration.months());
}

test toString {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    const allocator = std.testing.allocator;
    const str = try date.toString(allocator, .{});
    defer allocator.free(str);

    try std.testing.expect(std.mem.indexOf(u8, str, "2024-03-15") != null);
}

test toJSON {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    const allocator = std.testing.allocator;
    const str = try date.toJSON(allocator);
    defer allocator.free(str);

    try std.testing.expect(std.mem.indexOf(u8, str, "2024-03-15") != null);
}

test toLocaleString {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    const allocator = std.testing.allocator;
    try std.testing.expectError(error.TemporalNotImplemented, date.toLocaleString(allocator));
}

test toPlainDateTime {
    const date = try PlainDate.init(2024, 1, 15);
    const datetime = try date.toPlainDateTime(null);
    try std.testing.expectEqual(@as(i32, 2024), datetime.year());
    try std.testing.expectEqual(@as(u8, 1), datetime.month());
    try std.testing.expectEqual(@as(u8, 15), datetime.day());
    try std.testing.expectEqual(@as(u8, 0), datetime.hour());
    try std.testing.expectEqual(@as(u8, 0), datetime.minute());
}

test toPlainMonthDay {
    const date = try PlainDate.init(2024, 12, 25);
    const md = try date.toPlainMonthDay();
    try std.testing.expectEqual(@as(u8, 25), md.day());
    const month_code = try md.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(month_code);
    try std.testing.expect(month_code.len > 0);
}

test toPlainYearMonth {
    const date = try PlainDate.init(2024, 12, 25);
    const ym = try date.toPlainYearMonth();
    try std.testing.expectEqual(@as(i32, 2024), ym.year());
    try std.testing.expectEqual(@as(u8, 12), ym.month());
}

test toZonedDateTime {
    const date = try PlainDate.init(2024, 1, 15);
    const zdt = try date.toZonedDateTime(.{ .time_zone = "UTC", .plain_time = null });
    try std.testing.expectEqual(@as(i32, 2024), zdt.year());
    try std.testing.expectEqual(@as(u8, 1), zdt.month());
    try std.testing.expectEqual(@as(u8, 15), zdt.day());
}

test with {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    try std.testing.expectError(error.TemporalNotImplemented, date.with(.{}));
}

test withCalendar {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();

    const result = try date.withCalendar("iso8601");
    defer result.deinit();

    try std.testing.expectEqual(@as(i32, 2024), result.year());
}

test calInit {
    const date = try PlainDate.calInit(2024, 3, 15, "iso8601");
    defer date.deinit();
    try std.testing.expectEqual(@as(i32, 2024), date.year());
}

test valueOf {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectError(error.TemporalValueOfNotSupported, date.valueOf());
}

test day {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(u8, 15), date.day());
}

test dayOfWeek {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const dow = date.dayOfWeek();
    try std.testing.expect(dow >= 1 and dow <= 7);
}

test dayOfYear {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const doy = date.dayOfYear();
    try std.testing.expect(doy >= 1 and doy <= 366);
}

test daysInMonth {
    const date = try PlainDate.init(2024, 2, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(u16, 29), date.daysInMonth());
}

test daysInWeek {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(u16, 7), date.daysInWeek());
}

test daysInYear {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(u16, 366), date.daysInYear());
}

test monthCode {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const code = try date.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(code);
    try std.testing.expectEqualStrings("M03", code);
}

test month {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(u8, 3), date.month());
}

test monthsInYear {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(u16, 12), date.monthsInYear());
}

test year {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    try std.testing.expectEqual(@as(i32, 2024), date.year());
}

test inLeapYear {
    const leap = try PlainDate.init(2024, 3, 15);
    defer leap.deinit();
    try std.testing.expect(leap.inLeapYear());

    const non_leap = try PlainDate.init(2023, 3, 15);
    defer non_leap.deinit();
    try std.testing.expect(!non_leap.inLeapYear());
}

test calendarId {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const cal = try date.calendarId(std.testing.allocator);
    defer std.testing.allocator.free(cal);
    try std.testing.expectEqualStrings("iso8601", cal);
}

test era {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const e = try date.era(std.testing.allocator);
    if (e) |era_val| {
        defer std.testing.allocator.free(era_val);
        try std.testing.expect(era_val.len > 0);
    }
}

test eraYear {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const ey = date.eraYear();
    if (ey) |y| {
        try std.testing.expect(y > 0);
    }
}

test weekOfYear {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const woy = date.weekOfYear();
    if (woy) |week| {
        try std.testing.expect(week >= 1 and week <= 53);
    }
}

test yearOfWeek {
    const date = try PlainDate.init(2024, 3, 15);
    defer date.deinit();
    const yow = date.yearOfWeek();
    if (yow) |y| {
        try std.testing.expect(y >= 2020);
    }
}
