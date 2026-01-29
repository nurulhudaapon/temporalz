const std = @import("std");
const abi = @import("abi.zig");
const t = @import("temporal.zig");

const PlainDate = @import("PlainDate.zig");
const Duration = @import("Duration.zig");

const PlainYearMonth = @This();

_inner: *abi.c.PlainYearMonth,

// Import types from temporal.zig
pub const Unit = t.Unit;
pub const RoundingMode = t.RoundingMode;
pub const DifferenceSettings = t.DifferenceSettings;
pub const RoundOptions = t.RoundingOptions;

// Type definitions for API compatibility
pub const CalendarDisplay = enum {
    auto,
    always,
    never,
    critical,
};

pub const ToStringOptions = struct {
    calendar_display: ?CalendarDisplay = null,
};

pub const WithOptions = struct {
    year: ?i32 = null,
    month: ?u8 = null,
    month_code: ?[]const u8 = null,
};

// Helper to wrap PlainYearMonth pointer
fn wrapPlainYearMonth(result: anytype) !PlainYearMonth {
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;

    return .{ ._inner = ptr };
}

// Constructor
pub fn init(year_val: i32, month_val: u8, calendar: ?[]const u8) !PlainYearMonth {
    const cal_kind = if (calendar) |cal| blk: {
        const cal_view = abi.toDiplomatStringView(cal);
        const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
        break :blk try abi.extractResult(cal_result);
    } else abi.c.AnyCalendarKind_Iso;

    const overflow = abi.c.ArithmeticOverflow_Constrain;
    const ref_day = abi.c.OptionU8{ .is_ok = false };

    return wrapPlainYearMonth(abi.c.temporal_rs_PlainYearMonth_try_new_with_overflow(
        year_val,
        month_val,
        ref_day,
        cal_kind,
        overflow,
    ));
}

// Parse from string
pub fn from(s: []const u8) !PlainYearMonth {
    return fromUtf8(s);
}

fn fromUtf8(utf8: []const u8) !PlainYearMonth {
    const view = abi.toDiplomatStringView(utf8);
    return wrapPlainYearMonth(abi.c.temporal_rs_PlainYearMonth_from_utf8(view));
}

fn fromUtf16(utf16: []const u16) !PlainYearMonth {
    const view = abi.toDiplomatString16View(utf16);
    return wrapPlainYearMonth(abi.c.temporal_rs_PlainYearMonth_from_utf16(view));
}

// Comparison
pub fn compare(a: PlainYearMonth, b: PlainYearMonth) i8 {
    return abi.c.temporal_rs_PlainYearMonth_compare(a._inner, b._inner);
}

pub fn equals(self: PlainYearMonth, other: PlainYearMonth) bool {
    return abi.c.temporal_rs_PlainYearMonth_equals(self._inner, other._inner);
}

// Arithmetic
pub fn add(self: PlainYearMonth, duration: Duration) !PlainYearMonth {
    const overflow = abi.c.ArithmeticOverflow_Constrain;
    return wrapPlainYearMonth(abi.c.temporal_rs_PlainYearMonth_add(self._inner, duration._inner, overflow));
}

pub fn subtract(self: PlainYearMonth, duration: Duration) !PlainYearMonth {
    const overflow = abi.c.ArithmeticOverflow_Constrain;
    return wrapPlainYearMonth(abi.c.temporal_rs_PlainYearMonth_subtract(self._inner, duration._inner, overflow));
}

pub fn until(self: PlainYearMonth, other: PlainYearMonth, options: DifferenceSettings) !Duration {
    const settings = abi.to.diffsettings(options);
    const result = abi.c.temporal_rs_PlainYearMonth_until(self._inner, other._inner, settings);
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

pub fn since(self: PlainYearMonth, other: PlainYearMonth, options: DifferenceSettings) !Duration {
    const settings = abi.to.diffsettings(options);
    const result = abi.c.temporal_rs_PlainYearMonth_since(self._inner, other._inner, settings);
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

// Property accessors
pub fn calendarId(self: PlainYearMonth, allocator: std.mem.Allocator) ![]u8 {
    const calendar_ptr = abi.c.temporal_rs_PlainYearMonth_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);
    return try allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]);
}

pub fn year(self: PlainYearMonth) i32 {
    return abi.c.temporal_rs_PlainYearMonth_year(self._inner);
}

pub fn month(self: PlainYearMonth) u8 {
    return abi.c.temporal_rs_PlainYearMonth_month(self._inner);
}

pub fn monthCode(self: PlainYearMonth, allocator: std.mem.Allocator) ![]const u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_PlainYearMonth_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

pub fn daysInMonth(self: PlainYearMonth) u16 {
    return abi.c.temporal_rs_PlainYearMonth_days_in_month(self._inner);
}

pub fn daysInYear(self: PlainYearMonth) u16 {
    return abi.c.temporal_rs_PlainYearMonth_days_in_year(self._inner);
}

pub fn monthsInYear(self: PlainYearMonth) u16 {
    return abi.c.temporal_rs_PlainYearMonth_months_in_year(self._inner);
}

pub fn inLeapYear(self: PlainYearMonth) bool {
    return abi.c.temporal_rs_PlainYearMonth_in_leap_year(self._inner);
}

pub fn era(self: PlainYearMonth, allocator: std.mem.Allocator) !?[]const u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_PlainYearMonth_era(self._inner, &write.inner);
    const result = try write.toOwnedSlice();
    if (result.len == 0) return null;
    return result;
}

pub fn eraYear(self: PlainYearMonth) ?i32 {
    const result = abi.c.temporal_rs_PlainYearMonth_era_year(self._inner);
    if (!result.is_ok) return null;
    return result.unnamed_0.ok;
}

// Modification
pub fn with(self: PlainYearMonth, options: WithOptions) !PlainYearMonth {
    // Build month_code view
    const month_code_view = if (options.month_code) |mc|
        abi.toDiplomatStringView(mc)
    else
        abi.c.DiplomatStringView{ .data = null, .len = 0 };

    // Build partial date with only the fields we want to modify
    const partial_date = abi.c.PartialDate{
        .year = if (options.year) |y| abi.toOption(abi.c.OptionI32, y) else .{ .is_ok = false },
        .month = if (options.month) |m| abi.toOption(abi.c.OptionU8, m) else .{ .is_ok = false },
        .day = .{ .is_ok = false },
        .month_code = month_code_view,
        .era = .{ .data = null, .len = 0 },
        .era_year = .{ .is_ok = false },
        .calendar = abi.c.AnyCalendarKind_Iso,
    };

    const overflow = abi.c.ArithmeticOverflow_option{
        .is_ok = true,
        .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain },
    };

    return wrapPlainYearMonth(abi.c.temporal_rs_PlainYearMonth_with(
        self._inner,
        partial_date,
        overflow,
    ));
}

// Conversion
pub fn toPlainDate(self: PlainYearMonth, day: u8) !PlainDate {
    const partial_date = abi.c.PartialDate_option{
        .is_ok = true,
        .unnamed_0 = .{
            .ok = .{
                .year = .{ .is_ok = false },
                .month = .{ .is_ok = false },
                .day = abi.toOption(abi.c.OptionU8, day),
                .month_code = .{ .data = null, .len = 0 },
                .era = .{ .data = null, .len = 0 },
                .era_year = .{ .is_ok = false },
                .calendar = abi.c.AnyCalendarKind_Iso,
            },
        },
    };

    const result = abi.c.temporal_rs_PlainYearMonth_to_plain_date(self._inner, partial_date);
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;

    return PlainDate{ ._inner = ptr };
}

// String conversions
pub fn toString(self: PlainYearMonth, allocator: std.mem.Allocator) ![]u8 {
    return toStringWithOptions(self, allocator, .{});
}

fn toStringWithOptions(self: PlainYearMonth, allocator: std.mem.Allocator, options: ToStringOptions) ![]u8 {
    _ = options;
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const display = abi.c.DisplayCalendar_Auto;
    abi.c.temporal_rs_PlainYearMonth_to_ixdtf_string(self._inner, display, &write.inner);

    return try write.toOwnedSlice();
}

pub fn toJSON(self: PlainYearMonth, allocator: std.mem.Allocator) ![]u8 {
    return toString(self, allocator);
}

pub fn toLocaleString(self: PlainYearMonth, allocator: std.mem.Allocator) ![]u8 {
    return toString(self, allocator);
}

pub fn valueOf(self: PlainYearMonth) !void {
    _ = self;
    return error.ValueError;
}

// ---------- Tests ---------------------

test init {
    const ym = try init(2024, 12, null);
    try std.testing.expectEqual(@as(i32, 2024), ym.year());
    try std.testing.expectEqual(@as(u8, 12), ym.month());
}

test from {
    const ym = try from("2024-12");
    try std.testing.expectEqual(@as(i32, 2024), ym.year());
    try std.testing.expectEqual(@as(u8, 12), ym.month());
}

test compare {
    {
        const ym1 = try init(2024, 12, null);
        const ym2 = try init(2024, 12, null);
        try std.testing.expectEqual(@as(i8, 0), compare(ym1, ym2));
    }
    {
        const ym1 = try init(2024, 11, null);
        const ym2 = try init(2024, 12, null);
        try std.testing.expectEqual(@as(i8, -1), compare(ym1, ym2));
    }

    {
        const ym1 = try init(2025, 1, null);
        const ym2 = try init(2024, 12, null);
        try std.testing.expectEqual(@as(i8, 1), compare(ym1, ym2));
    }

    {
        const ym1 = try init(2024, 12, null);
        const ym2 = try init(2024, 12, null);
        try std.testing.expect(ym1.equals(ym2));
    }
}

test equals {
    {
        const ym1 = try init(2024, 12, null);
        const ym2 = try init(2024, 12, null);
        try std.testing.expect(ym1.equals(ym2));
    }

    {
        const ym1 = try init(2024, 12, null);
        const ym2 = try init(2024, 11, null);
        try std.testing.expect(!ym1.equals(ym2));
    }
}

test add {
    const ym = try init(2024, 6, null);
    const duration = try Duration.from("P6M");
    const result = try ym.add(duration);
    try std.testing.expectEqual(@as(i32, 2024), result.year());
    try std.testing.expectEqual(@as(u8, 12), result.month());
}

test subtract {
    const ym = try init(2024, 12, null);
    const duration = try Duration.from("P6M");
    const result = try ym.subtract(duration);
    try std.testing.expectEqual(@as(i32, 2024), result.year());
    try std.testing.expectEqual(@as(u8, 6), result.month());
}

test daysInMonth {
    const ym = try init(2024, 2, null);
    try std.testing.expectEqual(@as(u16, 29), ym.daysInMonth()); // 2024 is a leap year
}

test daysInYear {
    const ym = try init(2024, 1, null);
    try std.testing.expectEqual(@as(u16, 366), ym.daysInYear()); // 2024 is a leap year
}

test monthsInYear {
    const ym = try init(2024, 1, null);
    try std.testing.expectEqual(@as(u16, 12), ym.monthsInYear());
}

test inLeapYear {
    const ym2024 = try init(2024, 1, null);
    const ym2023 = try init(2023, 1, null);
    try std.testing.expect(ym2024.inLeapYear());
    try std.testing.expect(!ym2023.inLeapYear());
}

test toPlainDate {
    const ym = try init(2024, 12, null);
    const date = try ym.toPlainDate(25);
    try std.testing.expectEqual(@as(i32, 2024), date.year());
    try std.testing.expectEqual(@as(u8, 12), date.month());
    try std.testing.expectEqual(@as(u8, 25), date.day());
}

test toString {
    const ym = try init(2024, 12, null);
    const str = try ym.toString(std.testing.allocator);
    defer std.testing.allocator.free(str);
    try std.testing.expect(str.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, str, "2024") != null);
}

test toJSON {
    const ym = try init(2024, 12, null);
    const str = try ym.toJSON(std.testing.allocator);
    defer std.testing.allocator.free(str);
    try std.testing.expect(str.len > 0);
}

test since {
    const ym1 = try init(2024, 12, null);
    const ym2 = try init(2024, 6, null);
    const dur = try ym1.since(ym2, .{});

    try std.testing.expectEqual(@as(i64, 6), dur.months());
}

test until {
    const ym1 = try init(2024, 6, null);
    const ym2 = try init(2024, 12, null);
    const dur = try ym1.until(ym2, .{});

    try std.testing.expectEqual(@as(i64, 6), dur.months());
}

test with {
    // Test modifying year
    const ym1 = try init(2024, 6, null);
    const ym2 = try ym1.with(.{ .year = 2025 });
    try std.testing.expectEqual(@as(i32, 2025), ym2.year());
    try std.testing.expectEqual(@as(u8, 6), ym2.month());

    // Test modifying month
    const ym3 = try init(2024, 6, null);
    const ym4 = try ym3.with(.{ .month = 12 });
    try std.testing.expectEqual(@as(i32, 2024), ym4.year());
    try std.testing.expectEqual(@as(u8, 12), ym4.month());

    // Test modifying both
    const ym5 = try init(2024, 6, null);
    const ym6 = try ym5.with(.{ .year = 2025, .month = 1 });
    try std.testing.expectEqual(@as(i32, 2025), ym6.year());
    try std.testing.expectEqual(@as(u8, 1), ym6.month());
}

test toLocaleString {
    const ym = try init(2024, 6, null);
    const str = try ym.toLocaleString(std.testing.allocator);
    defer std.testing.allocator.free(str);
    try std.testing.expect(str.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, str, "2024") != null);
}

test "props" {
    const ym = try from("2021-07-01[u-ca=gregory]");

    const cal_id = try ym.calendarId(std.testing.allocator);
    defer std.testing.allocator.free(cal_id);
    try std.testing.expectEqualStrings("gregory", cal_id);

    try std.testing.expectEqual(@as(i32, 2021), ym.year());
    try std.testing.expectEqual(@as(u8, 7), ym.month());

    const month_code = try ym.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(month_code);
    try std.testing.expectEqualStrings("M07", month_code);
    try std.testing.expectEqual(@as(u16, 31), ym.daysInMonth());
    try std.testing.expectEqual(@as(u16, 365), ym.daysInYear());
    try std.testing.expectEqual(@as(u16, 12), ym.monthsInYear());
    try std.testing.expect(ym.inLeapYear() == false);

    const eraa = try ym.era(std.testing.allocator);
    if (eraa) |e| {
        defer std.testing.allocator.free(e);
        try std.testing.expectEqualStrings("ce", e);
    } else {
        try std.testing.expect(false);
    }

    const era_year = ym.eraYear();
    if (era_year) |ey| {
        try std.testing.expectEqual(@as(i32, 2021), ey);
    } else {
        try std.testing.expect(false);
    }
}
