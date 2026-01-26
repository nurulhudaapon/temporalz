const std = @import("std");
const ZonedDateTime = @This();
const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const Duration = @import("Duration.zig");

pub var calendarId: []const u8 = "";
pub var day: i64 = 0;
pub var dayOfWeek: i64 = 0;
pub var dayOfYear: i64 = 0;
pub var daysInMonth: i64 = 0;
pub var daysInWeek: i64 = 0;
pub var daysInYear: i64 = 0;
pub var epochMilliseconds: i64 = 0;
pub var epochNanoseconds: i128 = 0;
pub var era: []const u8 = "";
pub var eraYear: i64 = 0;
pub var hour: i64 = 0;
pub var hoursInDay: i64 = 0;
pub var inLeapYear: bool = false;
pub var microsecond: i64 = 0;
pub var millisecond: i64 = 0;
pub var minute: i64 = 0;
pub var month: i64 = 0;
pub var monthCode: []const u8 = "";
pub var monthsInYear: i64 = 0;
pub var nanosecond: i64 = 0;
pub var offset: []const u8 = "";
pub var offsetNanoseconds: i64 = 0;
pub var second: i64 = 0;
pub var timeZoneId: []const u8 = "";
pub var weekOfYear: i64 = 0;
pub var year: i64 = 0;
pub var yearOfWeek: i64 = 0;

pub fn init() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn compare() error{Todo}!i8 {
    return error.Todo;
}

pub fn from() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn add() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn equals() error{Todo}!bool {
    return error.Todo;
}

pub fn getTimeZoneTransition() error{Todo}!?Instant {
    return error.Todo;
}

pub fn round() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn since() error{Todo}!Duration {
    return error.Todo;
}

pub fn startOfDay() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn subtract() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn toInstant() error{Todo}!Instant {
    return error.Todo;
}

pub fn toJSON() error{Todo}![]const u8 {
    return error.Todo;
}

pub fn toLocaleString() error{Todo}![]const u8 {
    return error.Todo;
}

pub fn toPlainDate() error{Todo}!PlainDate {
    return error.Todo;
}

pub fn toPlainDateTime() error{Todo}!PlainDateTime {
    return error.Todo;
}

pub fn toPlainTime() error{Todo}!PlainTime {
    return error.Todo;
}

pub fn toString() error{Todo}![]const u8 {
    return error.Todo;
}

pub fn until() error{Todo}!Duration {
    return error.Todo;
}

pub fn valueOf() error{Todo}!void {
    return error.Todo;
}

pub fn with() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn withCalendar() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn withPlainTime() error{Todo}!ZonedDateTime {
    return error.Todo;
}

pub fn withTimeZone() error{Todo}!ZonedDateTime {
    return error.Todo;
}

test compare {
    if (true) return error.Todo;
}
test from {
    if (true) return error.Todo;
}
test add {
    if (true) return error.Todo;
}
test equals {
    if (true) return error.Todo;
}
test getTimeZoneTransition {
    if (true) return error.Todo;
}
test round {
    if (true) return error.Todo;
}
test since {
    if (true) return error.Todo;
}
test startOfDay {
    if (true) return error.Todo;
}
test subtract {
    if (true) return error.Todo;
}
test toInstant {
    if (true) return error.Todo;
}
test toJSON {
    if (true) return error.Todo;
}
test toLocaleString {
    if (true) return error.Todo;
}
test toPlainDate {
    if (true) return error.Todo;
}
test toPlainDateTime {
    if (true) return error.Todo;
}
test toPlainTime {
    if (true) return error.Todo;
}
test toString {
    if (true) return error.Todo;
}
test until {
    if (true) return error.Todo;
}
test with {
    if (true) return error.Todo;
}
test withCalendar {
    if (true) return error.Todo;
}
test withPlainTime {
    if (true) return error.Todo;
}
test withTimeZone {
    if (true) return error.Todo;
}
