const std = @import("std");
const abi = @import("abi.zig");
const temporal = @import("temporal.zig");

const PlainDateTime = @import("PlainDateTime.zig");
const PlainMonthDay = @import("PlainMonthDay.zig");
const PlainYearMonth = @import("PlainYearMonth.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const Duration = @import("Duration.zig");

const PlainDate = @This();

pub const Unit = temporal.Unit;
pub const RoundingMode = temporal.RoundingMode;
pub const Sign = temporal.Sign;
pub const DifferenceSettings = temporal.DifferenceSettings;

pub const ToStringOptions = struct {
    calendar_id: ?CalendarDisplay = null,
};

pub const CalendarDisplay = enum {
    auto,
    always,
    never,
    critical,

    fn toCApi(self: CalendarDisplay) abi.c.ShowCalendar {
        return switch (self) {
            .auto => .Auto,
            .always => .Always,
            .never => .Never,
            .critical => .Critical,
        };
    }
};

pub const ToZonedDateTimeOptions = struct {
    time_zone: []const u8,
    plain_time: ?PlainTime = null,
};

_inner: *abi.c.PlainDate,

pub fn init(year_val: i32, month_val: u8, day_val: u8) !PlainDate {
    return initWithCalendar(year_val, month_val, day_val, "iso8601");
}

pub fn initWithCalendar(year_val: i32, month_val: u8, day_val: u8, calendar: []const u8) !PlainDate {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = abi.success(cal_result) orelse return error.TemporalError;
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_try_new(year_val, month_val, day_val, cal_kind));
}

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

inline fn fromUtf8(text: []const u8) !PlainDate {
    const view = abi.toDiplomatStringView(text);
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_from_utf8(view));
}

inline fn fromUtf16(text: []const u16) !PlainDate {
    const view = abi.toDiplomatString16View(text);
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_from_utf16(view));
}

pub fn compare(a: PlainDate, b: PlainDate) i8 {
    return abi.c.temporal_rs_PlainDate_compare(a._inner, b._inner);
}

pub fn equals(self: PlainDate, other: PlainDate) bool {
    return abi.c.temporal_rs_PlainDate_equals(self._inner, other._inner);
}

pub fn add(self: PlainDate, duration: Duration) !PlainDate {
    const overflow_opt = abi.c.ArithmeticOverflow_option{ .is_ok = true, .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain } };
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_add(self._inner, duration._inner, overflow_opt));
}

pub fn subtract(self: PlainDate, duration: Duration) !PlainDate {
    const overflow_opt = abi.c.ArithmeticOverflow_option{ .is_ok = true, .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain } };
    return wrapPlainDate(abi.c.temporal_rs_PlainDate_subtract(self._inner, duration._inner, overflow_opt));
}

pub fn until(self: PlainDate, other: PlainDate, settings: DifferenceSettings) !Duration {
    const ptr = (abi.success(abi.c.temporal_rs_PlainDate_until(self._inner, other._inner, settings.toCApi())) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

pub fn since(self: PlainDate, other: PlainDate, settings: DifferenceSettings) !Duration {
    const ptr = (abi.success(abi.c.temporal_rs_PlainDate_since(self._inner, other._inner, settings.toCApi())) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

pub fn with(self: PlainDate, fields: anytype) !PlainDate {
    _ = self;
    _ = fields;
    return error.TemporalNotImplemented;
}

pub fn withCalendar(self: PlainDate, calendar: []const u8) !PlainDate {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = abi.success(cal_result) orelse return error.TemporalError;
    const ptr = abi.c.temporal_rs_PlainDate_with_calendar(self._inner, cal_kind) orelse return error.TemporalError;

    return .{ ._inner = ptr };
}

pub fn toPlainDateTime(self: PlainDate, time: ?PlainTime) !PlainDateTime {
    const time_ptr = if (time) |t| t._inner else null;
    const ptr = (abi.success(abi.c.temporal_rs_PlainDate_to_plain_date_time(self._inner, time_ptr)) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

pub fn toPlainMonthDay(self: PlainDate) !PlainMonthDay {
    const ptr = (abi.success(abi.c.temporal_rs_PlainDate_to_plain_month_day(self._inner)) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

pub fn toPlainYearMonth(self: PlainDate) !PlainYearMonth {
    const ptr = (abi.success(abi.c.temporal_rs_PlainDate_to_plain_year_month(self._inner)) orelse return error.TemporalError) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

pub fn toZonedDateTime(self: PlainDate, options: ToZonedDateTimeOptions) !ZonedDateTime {
    const tz_view = abi.toDiplomatStringView(options.time_zone);
    const tz_result = abi.c.temporal_rs_TimeZone_try_from_str(tz_view);
    const time_zone = abi.success(tz_result) orelse return error.TemporalError;

    const time_ptr = if (options.plain_time) |t| t._inner else null;
    const ptr = (abi.success(abi.c.temporal_rs_PlainDate_to_zoned_date_time(self._inner, time_zone, time_ptr)) orelse return error.TemporalError) orelse return error.TemporalError;

    // Get time zone identifier for ZonedDateTime
    // const allocator = std.heap.page_allocator;
    // var write = abi.DiplomatWrite.init(allocator);
    // defer write.deinit();
    // abi.c.temporal_rs_TimeZone_identifier(time_zone, &write.inner);
    // const tz_id = try write.toOwnedSlice();

    return .{ ._inner = ptr };
}

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

pub fn toJSON(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

pub fn toLocaleString(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    _ = self;
    _ = allocator;
    return error.TemporalNotImplemented;
}

pub fn valueOf(self: PlainDate) !void {
    _ = self;
    return error.TemporalValueOfNotSupported;
}

pub fn day(self: PlainDate) u8 {
    return abi.c.temporal_rs_PlainDate_day(self._inner);
}

pub fn dayOfWeek(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_day_of_week(self._inner);
}

pub fn dayOfYear(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_day_of_year(self._inner);
}

pub fn daysInMonth(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_days_in_month(self._inner);
}

pub fn daysInWeek(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_days_in_week(self._inner);
}

pub fn daysInYear(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_days_in_year(self._inner);
}

pub fn monthCode(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_PlainDate_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

pub fn month(self: PlainDate) u8 {
    return abi.c.temporal_rs_PlainDate_month(self._inner);
}

pub fn monthsInYear(self: PlainDate) u16 {
    return abi.c.temporal_rs_PlainDate_months_in_year(self._inner);
}

pub fn year(self: PlainDate) i32 {
    return abi.c.temporal_rs_PlainDate_year(self._inner);
}

pub fn inLeapYear(self: PlainDate) bool {
    return abi.c.temporal_rs_PlainDate_in_leap_year(self._inner);
}

pub fn calendarId(self: PlainDate, allocator: std.mem.Allocator) ![]u8 {
    const calendar_ptr = abi.c.temporal_rs_PlainDate_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);
    return try allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]);
}

pub fn era(self: PlainDate, allocator: std.mem.Allocator) !?[]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const has_era = abi.c.temporal_rs_PlainDate_era(self._inner, &write.inner);
    if (!has_era) return null;
    return try write.toOwnedSlice();
}

pub fn eraYear(self: PlainDate) ?u32 {
    const result = abi.c.temporal_rs_PlainDate_era_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

pub fn weekOfYear(self: PlainDate) ?u8 {
    const result = abi.c.temporal_rs_PlainDate_week_of_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

pub fn yearOfWeek(self: PlainDate) ?i32 {
    const result = abi.c.temporal_rs_PlainDate_year_of_week(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

fn clone(self: PlainDate) PlainDate {
    const ptr = abi.c.temporal_rs_PlainDate_clone(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

pub fn deinit(self: PlainDate) void {
    abi.c.temporal_rs_PlainDate_destroy(self._inner);
}

fn wrapPlainDate(res: anytype) !PlainDate {
    const ptr = (abi.success(res) orelse return error.TemporalError) orelse return error.TemporalError;

    // const calendar_ptr = abi.c.temporal_rs_PlainDate_calendar(ptr) orelse return error.TemporalError;
    // const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);

    // const allocator = std.heap.page_allocator;
    // const cal_id = allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]) catch "iso8601";

    return .{ ._inner = ptr };
}

fn handleVoidResult(res: anytype) !void {
    _ = abi.success(res) orelse return error.TemporalError;
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
