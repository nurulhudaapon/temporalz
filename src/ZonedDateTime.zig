const std = @import("std");

const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const Duration = @import("Duration.zig");

const ZonedDateTime = @This();

calendar_id: []const u8,
day: i64,
day_of_week: i64,
day_of_year: i64,
days_in_month: i64,
days_in_week: i64,
days_in_year: i64,
epoch_milliseconds: i64,
epoch_nanoseconds: i128,
era: []const u8,
era_year: i64,
hour: i64,
hours_in_day: i64,
in_leap_year: bool,
microsecond: i64,
millisecond: i64,
minute: i64,
month: i64,
month_code: []const u8,
months_in_year: i64,
nanosecond: i64,
offset: []const u8,
offset_nanoseconds: i64,
second: i64,
time_zone_id: []const u8,
week_of_year: i64,
year: i64,
year_of_week: i64,

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

// ---------- Tests ---------------------
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
