const std = @import("std");
const abi = @import("abi.zig");
const temporal_types = @import("temporal.zig");

const PlainMonthDay = @This();
const PlainDate = @import("PlainDate.zig");

_inner: *abi.c.PlainMonthDay,
calendar_id: []const u8,

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
    month_code: ?[]const u8 = null,
    day: ?u8 = null,
};

// Helper to wrap PlainMonthDay pointer
fn wrapPlainMonthDay(result: anytype) !PlainMonthDay {
    const ptr = (abi.success(result) orelse return error.TemporalError) orelse return error.TemporalError;

    const calendar_ptr = abi.c.temporal_rs_PlainMonthDay_calendar(ptr) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);

    const allocator = std.heap.page_allocator;
    const cal_id = allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]) catch "iso8601";

    return .{ ._inner = ptr, .calendar_id = cal_id };
}

// Constructor
pub fn init(month_val: u8, day_val: u8, calendar: ?[]const u8) !PlainMonthDay {
    const cal_kind = if (calendar) |cal| blk: {
        const cal_view = abi.toDiplomatStringView(cal);
        const cal_result = abi.c.temporal_rs_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
        break :blk abi.success(cal_result) orelse return error.TemporalError;
    } else abi.c.AnyCalendarKind_Iso;

    const overflow = abi.c.ArithmeticOverflow_Constrain;
    const ref_year = abi.c.OptionI32{ .is_ok = false };

    return wrapPlainMonthDay(abi.c.temporal_rs_PlainMonthDay_try_new_with_overflow(
        month_val,
        day_val,
        cal_kind,
        overflow,
        ref_year,
    ));
}

// Parse from string
pub fn from(s: []const u8) !PlainMonthDay {
    return fromUtf8(s);
}

fn fromUtf8(utf8: []const u8) !PlainMonthDay {
    const view = abi.toDiplomatStringView(utf8);
    return wrapPlainMonthDay(abi.c.temporal_rs_PlainMonthDay_from_utf8(view));
}

fn fromUtf16(utf16: []const u16) !PlainMonthDay {
    const view = abi.toDiplomatString16View(utf16);
    return wrapPlainMonthDay(abi.c.temporal_rs_PlainMonthDay_from_utf16(view));
}

// Comparison
pub fn equals(self: PlainMonthDay, other: PlainMonthDay) bool {
    return abi.c.temporal_rs_PlainMonthDay_equals(self._inner, other._inner);
}

// Property accessors
pub fn calendarId(self: PlainMonthDay) []const u8 {
    return self.calendar_id;
}

pub fn day(self: PlainMonthDay) u8 {
    return abi.c.temporal_rs_PlainMonthDay_day(self._inner);
}

pub fn monthCode(self: PlainMonthDay, allocator: std.mem.Allocator) ![]const u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_rs_PlainMonthDay_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

// Modification
pub fn with(self: PlainMonthDay, options: WithOptions) !PlainMonthDay {
    // Build month_code view
    const month_code_view = if (options.month_code) |mc|
        abi.toDiplomatStringView(mc)
    else
        abi.c.DiplomatStringView{ .data = null, .len = 0 };

    // Build partial date with only the fields we want to modify
    const partial_date = abi.c.PartialDate{
        .year = .{ .is_ok = false },
        .month = .{ .is_ok = false },
        .day = if (options.day) |d| abi.toOption(abi.c.OptionU8, d) else .{ .is_ok = false },
        .month_code = month_code_view,
        .era = .{ .data = null, .len = 0 },
        .era_year = .{ .is_ok = false },
        .calendar = abi.c.AnyCalendarKind_Iso,
    };

    const overflow = abi.c.ArithmeticOverflow_option{
        .is_ok = true,
        .unnamed_0 = .{ .ok = abi.c.ArithmeticOverflow_Constrain },
    };

    return wrapPlainMonthDay(abi.c.temporal_rs_PlainMonthDay_with(
        self._inner,
        partial_date,
        overflow,
    ));
}

// Conversion
pub fn toPlainDate(self: PlainMonthDay, year: i32) !PlainDate {
    const partial_date = abi.c.PartialDate_option{
        .is_ok = true,
        .unnamed_0 = .{
            .ok = .{
                .year = abi.toOption(abi.c.OptionI32, year),
                .month = .{ .is_ok = false },
                .day = .{ .is_ok = false },
                .month_code = .{ .data = null, .len = 0 },
                .era = .{ .data = null, .len = 0 },
                .era_year = .{ .is_ok = false },
                .calendar = abi.c.AnyCalendarKind_Iso,
            },
        },
    };

    const result = abi.c.temporal_rs_PlainMonthDay_to_plain_date(self._inner, partial_date);
    const ptr = (abi.success(result) orelse return error.TemporalError) orelse return error.TemporalError;

    const calendar_ptr = abi.c.temporal_rs_PlainDate_calendar(ptr) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_rs_Calendar_identifier(calendar_ptr);

    const allocator = std.heap.page_allocator;
    const cal_id = allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]) catch "iso8601";

    return PlainDate{ ._inner = ptr, .calendar_id = cal_id };
}

// String conversions
pub fn toString(self: PlainMonthDay, allocator: std.mem.Allocator) ![]u8 {
    return toStringWithOptions(self, allocator, .{});
}

fn toStringWithOptions(self: PlainMonthDay, allocator: std.mem.Allocator, options: ToStringOptions) ![]u8 {
    _ = options;
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const display = abi.c.DisplayCalendar_Auto;
    abi.c.temporal_rs_PlainMonthDay_to_ixdtf_string(self._inner, display, &write.inner);

    return try write.toOwnedSlice();
}

pub fn toJSON(self: PlainMonthDay, allocator: std.mem.Allocator) ![]u8 {
    return toString(self, allocator);
}

pub fn toLocaleString(self: PlainMonthDay, allocator: std.mem.Allocator) ![]u8 {
    return toString(self, allocator);
}

pub fn valueOf(self: PlainMonthDay) !void {
    _ = self;
    return error.ValueError;
}

// ---------- Tests ---------------------

test init {
    const md = try init(12, 25, null);
    try std.testing.expectEqual(@as(u8, 25), md.day());
    const month_code = try md.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(month_code);
    try std.testing.expect(month_code.len > 0);
}

test from {
    const md = try from("12-25");
    try std.testing.expectEqual(@as(u8, 25), md.day());
}

test equals {
    {
        const md1 = try init(12, 25, null);
        const md2 = try init(12, 25, null);
        try std.testing.expect(md1.equals(md2));
    }

    {
        const md1 = try init(12, 25, null);
        const md2 = try init(12, 24, null);
        try std.testing.expect(!md1.equals(md2));
    }
}

test toPlainDate {
    const md = try init(12, 25, null);
    const date = try md.toPlainDate(2024);
    try std.testing.expectEqual(@as(i32, 2024), date.year());
    try std.testing.expectEqual(@as(u8, 25), date.day());
}

test toString {
    const md = try init(12, 25, null);
    const str = try md.toString(std.testing.allocator);
    defer std.testing.allocator.free(str);

    try std.testing.expect(str.len > 0);
}

test toJSON {
    const md = try init(12, 25, null);
    const str = try md.toJSON(std.testing.allocator);
    defer std.testing.allocator.free(str);

    try std.testing.expect(str.len > 0);
}

test with {
    // Test modifying day
    const md1 = try init(12, 25, null);
    const md2 = try md1.with(.{ .day = 31 });
    try std.testing.expectEqual(@as(u8, 31), md2.day());

    // Test modifying month_code
    const md3 = try init(12, 25, null);
    const md4 = try md3.with(.{ .month_code = "M01" });
    const month_code = try md4.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(month_code);
    try std.testing.expectEqualStrings("M01", month_code);
    try std.testing.expectEqual(@as(u8, 25), md4.day());

    // Test modifying both
    const md5 = try init(6, 15, null);
    const md6 = try md5.with(.{ .month_code = "M12", .day = 1 });
    const month_code2 = try md6.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(month_code2);
    try std.testing.expectEqualStrings("M12", month_code2);
    try std.testing.expectEqual(@as(u8, 1), md6.day());
}

test toLocaleString {
    const md = try init(12, 25, null);
    const str = try md.toLocaleString(std.testing.allocator);
    defer std.testing.allocator.free(str);
    try std.testing.expect(str.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, str, "12") != null or std.mem.indexOf(u8, str, "25") != null);
}
