const std = @import("std");
const PlainYearMonth = @This();
const PlainDate = @import("PlainDate.zig");
const Duration = @import("Duration.zig");

calendar_id: []const u8,
days_in_month: i64,
days_in_year: i64,
era: []const u8,
era_year: i64,
in_leap_year: bool,
month: i64,
month_code: []const u8,
months_in_year: i64,
year: i64,

pub fn init() error{Todo}!PlainYearMonth {
    return error.Todo;
}

pub fn compare() error{Todo}!i8 {
    return error.Todo;
}

pub fn from() error{Todo}!PlainYearMonth {
    return error.Todo;
}

pub fn add() error{Todo}!PlainYearMonth {
    return error.Todo;
}

pub fn equals() error{Todo}!bool {
    return error.Todo;
}

pub fn since() error{Todo}!Duration {
    return error.Todo;
}

pub fn subtract() error{Todo}!PlainYearMonth {
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

pub fn toString() error{Todo}![]const u8 {
    return error.Todo;
}

pub fn until() error{Todo}!Duration {
    return error.Todo;
}

pub fn valueOf() error{Todo}!void {
    return error.Todo;
}

pub fn with() error{Todo}!PlainYearMonth {
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
test since {
    if (true) return error.Todo;
}
test subtract {
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
test toString {
    if (true) return error.Todo;
}
test until {
    if (true) return error.Todo;
}
test with {
    if (true) return error.Todo;
}
