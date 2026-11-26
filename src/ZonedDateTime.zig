const std = @import("std");
const abi = @import("abi.zig");
const t = @import("Temporal.zig");

const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const Duration = @import("Duration.zig");

const ZonedDateTime = @This();

_inner: *abi.c.ZonedDateTime,

/// The unit of time used for rounding and difference calculations.
pub const Unit = t.Unit;

/// The rounding mode used for rounding operations.
pub const RoundingMode = t.RoundingMode;

/// The sign of a duration or difference.
pub const Sign = t.Sign;

/// Options for difference calculations between ZonedDateTime instances.
pub const DifferenceSettings = t.DifferenceSettings;

/// Options for rounding ZonedDateTime instances.
pub const RoundOptions = t.RoundingOptions;

/// Represents a time zone, identified by an IANA time zone identifier or a fixed offset.
pub const TimeZone = t.TimeZone;

/// Disambiguation options for resolving ambiguous local times (e.g., during DST transitions).
pub const Disambiguation = enum {
    compatible,
    earlier,
    later,
    reject,
};

/// Options for resolving offset ambiguity when parsing ZonedDateTime from a string.
pub const OffsetDisambiguation = enum {
    use_offset,
    prefer_offset,
    ignore_offset,
    reject,
};

/// Controls how the calendar is displayed in string output.
pub const CalendarDisplay = enum {
    auto,
    always,
    never,
    critical,
};

/// Controls how the offset is displayed in string output.
pub const DisplayOffset = enum {
    auto,
    never,
};

/// Controls how the time zone is displayed in string output.
pub const DisplayTimeZone = enum {
    auto,
    never,
    critical,
};

/// Options for formatting ZonedDateTime as a string.
///
/// See: [Temporal.ZonedDateTime.toString](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toString#parameters)
pub const ToStringOptions = struct {
    fractional_second_digits: ?u8 = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    calendar_display: CalendarDisplay = .auto,
    offset_display: DisplayOffset = .auto,
    time_zone_name: DisplayTimeZone = .auto,
};

/// Options for `with()` method.
///
/// See: [Temporal.ZonedDateTime.with](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/with#parameters)
pub const WithOptions = struct {
    year: ?i32 = null,
    month: ?u8 = null,
    month_code: ?[]const u8 = null,
    day: ?u8 = null,
    era: ?[]const u8 = null,
    era_year: ?i32 = null,
    hour: ?u8 = null,
    minute: ?u8 = null,
    second: ?u8 = null,
    millisecond: ?u16 = null,
    microsecond: ?u16 = null,
    nanosecond: ?u16 = null,
    offset: ?[]const u8 = null,
    time_zone: ?TimeZone = null,
    /// How out-of-range values are handled. Defaults to `constrain`.
    overflow: ?Overflow = null,
    /// How ambiguous local times are resolved. Defaults to `compatible`.
    disambiguation: ?Disambiguation = null,
    /// How a conflicting `offset` is resolved. Defaults to `prefer`.
    offset_disambiguation: ?OffsetDisambiguation = null,
};

pub const Overflow = t.Overflow;
pub const ArithmeticOptions = t.ArithmeticOptions;

/// Fields accepted by `from()` (the spec's property-bag form).
///
/// See: [Temporal.ZonedDateTime.from](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/from)
pub const Fields = struct {
    year: ?i32 = null,
    month: ?u8 = null,
    month_code: ?[]const u8 = null,
    day: ?u8 = null,
    era: ?[]const u8 = null,
    era_year: ?i32 = null,
    hour: ?u8 = null,
    minute: ?u8 = null,
    second: ?u8 = null,
    millisecond: ?u16 = null,
    microsecond: ?u16 = null,
    nanosecond: ?u16 = null,
    /// UTC offset string, e.g. "+05:30".
    offset: ?[]const u8 = null,
    /// Required unless passed as the `time_zone` argument of `from()`.
    time_zone: ?TimeZone = null,
    /// Calendar identifier (e.g. "iso8601", "gregory"). Defaults to ISO 8601.
    calendar: ?[]const u8 = null,
    /// How out-of-range values are handled. Defaults to `constrain`.
    overflow: ?Overflow = null,
};

/// Creates a new ZonedDateTime from the given epoch nanoseconds and time zone.
/// Equivalent to the Temporal.ZonedDateTime constructor.
///
/// See: [Temporal.ZonedDateTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/ZonedDateTime)
pub fn init(epoch_ns: i128, time_zone: TimeZone) !ZonedDateTime {
    const ns_parts = abi.toI128Nanoseconds(epoch_ns);
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_from_epoch_nanoseconds(ns_parts, abi.to.toTimeZone(time_zone)));
}

/// Creates a new ZonedDateTime from the given epoch milliseconds and time zone.
pub fn fromEpochMilliseconds(epoch_ms: i64, time_zone: TimeZone) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_from_epoch_milliseconds(epoch_ms, abi.to.toTimeZone(time_zone)));
}

/// Creates a new ZonedDateTime from the given epoch nanoseconds and time zone.
pub fn fromEpochNanoseconds(epoch_ns: i128, time_zone: TimeZone) !ZonedDateTime {
    const ns_parts = abi.toI128Nanoseconds(epoch_ns);
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_from_epoch_nanoseconds(ns_parts, abi.to.toTimeZone(time_zone)));
}

/// Creates a ZonedDateTime from a string (the time zone is taken from the string) or
/// from a set of fields (`Fields` or an anonymous struct literal with the same field names).
/// For fields, `time_zone` is used when the fields don't contain one.
///
/// See: [Temporal.ZonedDateTime.from](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/from)
pub fn from(info: anytype, time_zone: ?TimeZone, disambiguation: Disambiguation, offset_disambiguation: OffsetDisambiguation) !ZonedDateTime {
    const T = @TypeOf(info);
    if (T == ZonedDateTime) return info.clone();

    switch (@typeInfo(T)) {
        .pointer => |ptr| {
            const Child = switch (@typeInfo(ptr.child)) {
                .array => |arr| arr.child,
                else => ptr.child,
            };
            if (Child == u8) {
                const view = abi.toDiplomatStringView(info);
                return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_from_utf8(view, abi.to.toDisambiguation(disambiguation), abi.to.toOffsetDisambiguation(offset_disambiguation)));
            }
            if (Child == u16) {
                const view = abi.toDiplomatString16View(info);
                return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_from_utf16(view, abi.to.toDisambiguation(disambiguation), abi.to.toOffsetDisambiguation(offset_disambiguation)));
            }
            @compileError("from() expects a ZonedDateTime, string, or fields struct");
        },
        .@"struct" => {
            var partial = abi.toPartialZonedDateTime(info);
            partial.date.calendar = try abi.calendarField(info);
            if (!partial.timezone.is_ok) {
                // The spec requires a time zone; temporal_capi would otherwise silently default one.
                const tz = time_zone orelse return abi.TemporalError.TypeError;
                partial.timezone = abi.toOption(abi.c.TimeZone_option, tz._inner);
            }
            return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_from_partial(
                partial,
                abi.overflowField(info),
                abi.toOption(abi.c.Disambiguation_option, abi.to.toDisambiguation(disambiguation)),
                abi.toOption(abi.c.OffsetDisambiguation_option, abi.to.toOffsetDisambiguation(offset_disambiguation)),
            ));
        },
        else => @compileError("from() expects a ZonedDateTime, string, or fields struct"),
    }
}

/// Compares two ZonedDateTime instances by their instant values.
/// Returns -1, 0, or 1 if the first is before, equal, or after the second.
///
/// See: [Temporal.ZonedDateTime.compare](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/compare)
pub fn compare(a: ZonedDateTime, b: ZonedDateTime) i8 {
    return abi.c.temporal_ZonedDateTime_compare_instant(a._inner, b._inner);
}

/// Returns a new ZonedDateTime moved forward by the given duration.
///
/// See: [Temporal.ZonedDateTime.add](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/add)
pub fn add(self: ZonedDateTime, duration: Duration) !ZonedDateTime {
    return self.addWithOptions(duration, .{});
}

/// Returns a new ZonedDateTime moved forward by the given duration, with options.
pub fn addWithOptions(self: ZonedDateTime, duration: Duration, options: ArithmeticOptions) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_add(self._inner, duration._inner, abi.toOverflowOption(options.overflow)));
}

/// Returns true if this ZonedDateTime is equal to another (same instant, time zone, and calendar).
///
/// See: [Temporal.ZonedDateTime.equals](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/equals)
pub fn equals(self: ZonedDateTime, other: ZonedDateTime) bool {
    return abi.c.temporal_ZonedDateTime_equals(self._inner, other._inner);
}

/// Returns the first instant after or before this instant at which the time zone's UTC offset changes, or null if none.
///
/// See: [Temporal.ZonedDateTime.getTimeZoneTransition](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/getTimeZoneTransition)
pub fn getTimeZoneTransition(self: ZonedDateTime, direction: enum { next, previous }) !?ZonedDateTime {
    const dir = switch (direction) {
        .next => abi.c.TransitionDirection_Next,
        .previous => abi.c.TransitionDirection_Previous,
    };
    const result = abi.c.temporal_ZonedDateTime_get_time_zone_transition(self._inner, @intCast(dir));
    const maybe_ptr = try abi.extractResult(result);
    if (maybe_ptr) |ptr| {
        return .{ ._inner = ptr };
    }
    return null;
}

/// Returns a new ZonedDateTime rounded to the given unit and options.
///
/// See: [Temporal.ZonedDateTime.round](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/round)
pub fn round(self: ZonedDateTime, options: RoundOptions) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_round(self._inner, abi.to.roundingOpts(options)));
}

/// Returns the duration from another ZonedDateTime to this one.
///
/// See: [Temporal.ZonedDateTime.since](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/since)
pub fn since(self: ZonedDateTime, other: ZonedDateTime, settings: DifferenceSettings) !Duration {
    const ptr = try abi.extractResult(abi.c.temporal_ZonedDateTime_since(self._inner, other._inner, abi.to.diffsettings(settings)));
    if (ptr == null) return error.TemporalError;
    return .{ ._inner = ptr.? };
}

/// Returns a ZonedDateTime representing the start of the day in the time zone.
///
/// See: [Temporal.ZonedDateTime.startOfDay](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/startOfDay)
pub fn startOfDay(self: ZonedDateTime) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_start_of_day(self._inner));
}

/// Returns a new ZonedDateTime moved backward by the given duration.
///
/// See: [Temporal.ZonedDateTime.subtract](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/subtract)
pub fn subtract(self: ZonedDateTime, duration: Duration) !ZonedDateTime {
    return self.subtractWithOptions(duration, .{});
}

/// Returns a new ZonedDateTime moved backward by the given duration, with options.
pub fn subtractWithOptions(self: ZonedDateTime, duration: Duration, options: ArithmeticOptions) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_subtract(self._inner, duration._inner, abi.toOverflowOption(options.overflow)));
}

/// Returns a new Instant representing the same instant as this ZonedDateTime.
///
/// See: [Temporal.ZonedDateTime.toInstant](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toInstant)
pub fn toInstant(self: ZonedDateTime) !Instant {
    const instant_ptr = abi.c.temporal_ZonedDateTime_to_instant(self._inner) orelse return error.TemporalError;
    return .{ ._inner = instant_ptr };
}

/// Returns a string representing this ZonedDateTime in RFC 9557 format (ISO 8601 with time zone).
///
/// See: [Temporal.ZonedDateTime.toJSON](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toJSON)
pub fn toJSON(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Returns a language-sensitive string representation of this ZonedDateTime.
///
/// See: [Temporal.ZonedDateTime.toLocaleString](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toLocaleString)
pub fn toLocaleString(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    return self.toString(allocator, .{});
}

/// Returns a PlainDate representing the date portion of this ZonedDateTime.
///
/// See: [Temporal.ZonedDateTime.toPlainDate](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toPlainDate)
pub fn toPlainDate(self: ZonedDateTime) !PlainDate {
    const ptr = abi.c.temporal_ZonedDateTime_to_plain_date(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Returns a PlainDateTime representing the date and time portions of this ZonedDateTime.
///
/// See: [Temporal.ZonedDateTime.toPlainDateTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toPlainDateTime)
pub fn toPlainDateTime(self: ZonedDateTime) !PlainDateTime {
    const ptr = abi.c.temporal_ZonedDateTime_to_plain_datetime(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Returns a PlainTime representing the time portion of this ZonedDateTime.
///
/// See: [Temporal.ZonedDateTime.toPlainTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toPlainTime)
pub fn toPlainTime(self: ZonedDateTime) !PlainTime {
    const ptr = abi.c.temporal_ZonedDateTime_to_plain_time(self._inner) orelse return error.TemporalError;
    return .{ ._inner = ptr };
}

/// Returns a string representing this ZonedDateTime in RFC 9557 format, with options for formatting.
///
/// See: [Temporal.ZonedDateTime.toString](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/toString)
pub fn toString(self: ZonedDateTime, allocator: std.mem.Allocator, opts: ToStringOptions) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    const result = abi.c.temporal_ZonedDateTime_to_ixdtf_string(
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

/// Returns the duration from this ZonedDateTime to another.
///
/// See: [Temporal.ZonedDateTime.until](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/until)
pub fn until(self: ZonedDateTime, other: ZonedDateTime, settings: DifferenceSettings) !Duration {
    const ptr = try abi.extractResult(abi.c.temporal_ZonedDateTime_until(self._inner, other._inner, abi.to.diffsettings(settings)));
    if (ptr == null) return error.TemporalError;
    return .{ ._inner = ptr.? };
}

/// Throws an error; valueOf() is not supported for ZonedDateTime.
///
/// See: [Temporal.ZonedDateTime.valueOf](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/valueOf)
pub fn valueOf(_: ZonedDateTime) !void {
    return error.ValueOfNotSupported;
}

/// Returns a new ZonedDateTime with some fields replaced by new values.
/// See [MDN Temporal.ZonedDateTime.prototype.with()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/with)
pub fn with(self: ZonedDateTime, allocator: std.mem.Allocator, fields: anytype) !ZonedDateTime {
    _ = allocator;
    const partial = abi.toPartialZonedDateTime(fields);
    const disambiguation_val = abi.enumField(Disambiguation, fields, "disambiguation") orelse .compatible;
    const offset_val = abi.enumField(OffsetDisambiguation, fields, "offset_disambiguation") orelse .prefer_offset;
    const disambiguation = abi.toOption(abi.c.Disambiguation_option, abi.to.toDisambiguation(disambiguation_val));
    const offset_option = abi.toOption(abi.c.OffsetDisambiguation_option, abi.to.toOffsetDisambiguation(offset_val));
    const overflow = abi.toOverflowOption(abi.enumField(Overflow, fields, "overflow") orelse .constrain);

    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_with(
        self._inner,
        partial,
        disambiguation,
        offset_option,
        overflow,
    ));
}

/// Returns a new ZonedDateTime interpreted in the new calendar system.
///
/// See: [Temporal.ZonedDateTime.withCalendar](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/withCalendar)
pub fn withCalendar(self: ZonedDateTime, calendar: []const u8) !ZonedDateTime {
    const cal_view = abi.toDiplomatStringView(calendar);
    const cal_result = abi.c.temporal_AnyCalendarKind_parse_temporal_calendar_string(cal_view);
    const cal_kind = try abi.extractResult(cal_result);
    const ptr = abi.c.temporal_ZonedDateTime_with_calendar(self._inner, cal_kind);
    if (ptr == null) return error.TemporalError;
    return .{ ._inner = ptr.? };
}

/// Returns a new ZonedDateTime with the time part replaced by the new time.
///
/// See: [Temporal.ZonedDateTime.withPlainTime](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/withPlainTime)
pub fn withPlainTime(self: ZonedDateTime, time: ?PlainTime) !ZonedDateTime {
    const time_ptr = if (time) |tt| tt._inner else null;
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_with_plain_time(self._inner, time_ptr));
}

/// Returns a new ZonedDateTime representing the same instant in a new time zone.
///
/// See: [Temporal.ZonedDateTime.withTimeZone](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/withTimeZone)
pub fn withTimeZone(self: ZonedDateTime, time_zone: TimeZone) !ZonedDateTime {
    return wrapZonedDateTime(abi.c.temporal_ZonedDateTime_with_timezone(self._inner, abi.to.toTimeZone(time_zone)));
}

// Property accessors
/// Returns the calendar identifier used to interpret the internal ISO 8601 date.
///
/// See: [Temporal.ZonedDateTime.calendarId](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/calendarId)
pub fn calendarId(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    const calendar_ptr = abi.c.temporal_ZonedDateTime_calendar(self._inner) orelse return error.TemporalError;
    const cal_id_view = abi.c.temporal_Calendar_identifier(calendar_ptr);
    return try allocator.dupe(u8, cal_id_view.data[0..cal_id_view.len]);
}

/// Returns the 1-based day index in the month of this date.
///
/// See: [Temporal.ZonedDateTime.day](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/day)
pub fn day(self: ZonedDateTime) u8 {
    return abi.c.temporal_ZonedDateTime_day(self._inner);
}

/// Returns the 1-based day index in the week of this date.
///
/// See: [Temporal.ZonedDateTime.dayOfWeek](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/dayOfWeek)
pub fn dayOfWeek(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_day_of_week(self._inner);
}

/// Returns the 1-based day index in the year of this date.
///
/// See: [Temporal.ZonedDateTime.dayOfYear](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/dayOfYear)
pub fn dayOfYear(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_day_of_year(self._inner);
}

/// Returns the number of days in the month of this date.
///
/// See: [Temporal.ZonedDateTime.daysInMonth](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/daysInMonth)
pub fn daysInMonth(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_days_in_month(self._inner);
}

/// Returns the number of days in the week of this date.
///
/// See: [Temporal.ZonedDateTime.daysInWeek](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/daysInWeek)
pub fn daysInWeek(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_days_in_week(self._inner);
}

/// Returns the number of days in the year of this date.
///
/// See: [Temporal.ZonedDateTime.daysInYear](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/daysInYear)
pub fn daysInYear(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_days_in_year(self._inner);
}

/// Returns the number of milliseconds since the Unix epoch to this instant.
///
/// See: [Temporal.ZonedDateTime.epochMilliseconds](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/epochMilliseconds)
pub fn epochMilliseconds(self: ZonedDateTime) i64 {
    return abi.c.temporal_ZonedDateTime_epoch_milliseconds(self._inner);
}

/// Returns the number of nanoseconds since the Unix epoch to this instant.
///
/// See: [Temporal.ZonedDateTime.epochNanoseconds](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/epochNanoseconds)
pub fn epochNanoseconds(self: ZonedDateTime) i128 {
    const parts = abi.c.temporal_ZonedDateTime_epoch_nanoseconds(self._inner);
    return abi.fromI128Nanoseconds(parts);
}

/// Returns the calendar-specific era of this date, or null if not applicable.
///
/// See: [Temporal.ZonedDateTime.era](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/era)
pub fn era(self: ZonedDateTime, allocator: std.mem.Allocator) !?[]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    abi.c.temporal_ZonedDateTime_era(self._inner, &write.inner);
    const result = try write.toOwnedSlice();
    if (result.len == 0) {
        allocator.free(result);
        return null;
    }
    return result;
}

/// Returns the year of this date within the era, or null if not applicable.
///
/// See: [Temporal.ZonedDateTime.eraYear](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/eraYear)
pub fn eraYear(self: ZonedDateTime) ?i32 {
    const result = abi.c.temporal_ZonedDateTime_era_year(self._inner);
    return abi.fromOption(result);
}

/// Returns the hour component of this time (0-23).
///
/// See: [Temporal.ZonedDateTime.hour](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/hour)
pub fn hour(self: ZonedDateTime) u8 {
    return abi.c.temporal_ZonedDateTime_hour(self._inner);
}

/// Returns the number of hours in the day of this date in the time zone.
///
/// See: [Temporal.ZonedDateTime.hoursInDay](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/hoursInDay)
pub fn hoursInDay(self: ZonedDateTime) !f64 {
    const result = abi.c.temporal_ZonedDateTime_hours_in_day(self._inner);
    return try abi.extractResult(result);
}

/// Returns true if this date is in a leap year.
///
/// See: [Temporal.ZonedDateTime.inLeapYear](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/inLeapYear)
pub fn inLeapYear(self: ZonedDateTime) bool {
    return abi.c.temporal_ZonedDateTime_in_leap_year(self._inner);
}

/// Returns the microsecond component of this time (0-999).
///
/// See: [Temporal.ZonedDateTime.microsecond](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/microsecond)
pub fn microsecond(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_microsecond(self._inner);
}

/// Returns the millisecond component of this time (0-999).
///
/// See: [Temporal.ZonedDateTime.millisecond](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/millisecond)
pub fn millisecond(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_millisecond(self._inner);
}

/// Returns the minute component of this time (0-59).
///
/// See: [Temporal.ZonedDateTime.minute](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/minute)
pub fn minute(self: ZonedDateTime) u8 {
    return abi.c.temporal_ZonedDateTime_minute(self._inner);
}

/// Returns the 1-based month index in the year of this date.
///
/// See: [Temporal.ZonedDateTime.month](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/month)
pub fn month(self: ZonedDateTime) u8 {
    return abi.c.temporal_ZonedDateTime_month(self._inner);
}

/// Returns the calendar-specific string representing the month of this date.
///
/// See: [Temporal.ZonedDateTime.monthCode](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/monthCode)
pub fn monthCode(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    abi.c.temporal_ZonedDateTime_month_code(self._inner, &write.inner);
    return try write.toOwnedSlice();
}

/// Returns the number of months in the year of this date.
///
/// See: [Temporal.ZonedDateTime.monthsInYear](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/monthsInYear)
pub fn monthsInYear(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_months_in_year(self._inner);
}

/// Returns the nanosecond component of this time (0-999).
///
/// See: [Temporal.ZonedDateTime.nanosecond](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/nanosecond)
pub fn nanosecond(self: ZonedDateTime) u16 {
    return abi.c.temporal_ZonedDateTime_nanosecond(self._inner);
}

/// Returns the offset used to interpret the internal instant, as a string (±HH:mm).
///
/// See: [Temporal.ZonedDateTime.offset](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/offset)
pub fn offset(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();
    const res = abi.c.temporal_ZonedDateTime_offset(self._inner, &write.inner);
    _ = try abi.extractResult(res);
    return try write.toOwnedSlice();
}

/// Returns the offset used to interpret the internal instant, as a number of nanoseconds.
///
/// See: [Temporal.ZonedDateTime.offsetNanoseconds](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/offsetNanoseconds)
pub fn offsetNanoseconds(self: ZonedDateTime) i64 {
    return abi.c.temporal_ZonedDateTime_offset_nanoseconds(self._inner);
}

/// Returns the second component of this time (0-59).
///
/// See: [Temporal.ZonedDateTime.second](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/second)
pub fn second(self: ZonedDateTime) u8 {
    return abi.c.temporal_ZonedDateTime_second(self._inner);
}

/// Returns the time zone identifier used to interpret the internal instant.
///
/// See: [Temporal.ZonedDateTime.timeZoneId](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/timeZoneId)
pub fn timeZoneId(self: ZonedDateTime, allocator: std.mem.Allocator) ![]u8 {
    const tz = abi.c.temporal_ZonedDateTime_timezone(self._inner);
    var write = abi.DiplomatWrite.init(allocator);
    defer write.deinit();

    abi.c.temporal_TimeZone_identifier(tz, &write.inner);

    return try write.toOwnedSlice();
}

/// Returns the 1-based week index in the year of this date, or null if not defined.
///
/// See: [Temporal.ZonedDateTime.weekOfYear](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/weekOfYear)
pub fn weekOfYear(self: ZonedDateTime) ?u8 {
    const result = abi.c.temporal_ZonedDateTime_week_of_year(self._inner);
    return abi.fromOption(result);
}

/// Returns the year of this date relative to the calendar's epoch.
///
/// See: [Temporal.ZonedDateTime.year](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/year)
pub fn year(self: ZonedDateTime) i32 {
    return abi.c.temporal_ZonedDateTime_year(self._inner);
}

/// Returns the year to be paired with the weekOfYear of this date, or null if not defined.
///
/// See: [Temporal.ZonedDateTime.yearOfWeek](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/ZonedDateTime/yearOfWeek)
pub fn yearOfWeek(self: ZonedDateTime) ?i32 {
    const result = abi.c.temporal_ZonedDateTime_year_of_week(self._inner);
    return abi.fromOption(result);
}

/// Returns a clone of this ZonedDateTime instance.
pub fn clone(self: ZonedDateTime) ZonedDateTime {
    const ptr = abi.c.temporal_ZonedDateTime_clone(self._inner) orelse unreachable;
    return .{ ._inner = ptr };
}

/// Frees the resources associated with this ZonedDateTime instance.
pub fn deinit(self: ZonedDateTime) void {
    abi.c.temporal_ZonedDateTime_destroy(self._inner);
}

/// Helper function to wrap a C API result into a ZonedDateTime
fn wrapZonedDateTime(result: anytype) !ZonedDateTime {
    const ptr = (try abi.extractResult(result)) orelse return abi.TemporalError.Generic;
    return .{ ._inner = ptr };
}

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
    defer abi.c.temporal_PlainTime_destroy(pt._inner);

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

test fromEpochNanoseconds {
    const tz = try TimeZone.init("UTC");
    const epoch_ns: i128 = 1609459200000000000;
    const zdt = try fromEpochNanoseconds(epoch_ns, tz);
    defer zdt.deinit();
    try std.testing.expectEqual(epoch_ns, zdt.epochNanoseconds());
}

test add {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(0, tz);
    defer zdt.deinit();

    var dur = try Duration.from("PT1H");
    defer dur.deinit();

    const result = try zdt.add(dur);
    defer result.deinit();

    try std.testing.expectEqual(@as(i64, 3_600_000), result.epochMilliseconds());
}

test getTimeZoneTransition {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    try std.testing.expectEqual(@as(?ZonedDateTime, null), try zdt.getTimeZoneTransition(.next));
    try std.testing.expectEqual(@as(?ZonedDateTime, null), try zdt.getTimeZoneTransition(.previous));
}

test round {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459245123, tz);
    defer zdt.deinit();

    const rounded = try zdt.round(.{ .smallest_unit = .second });
    defer rounded.deinit();

    try std.testing.expectEqual(@as(u16, 0), rounded.millisecond());
}

test since {
    const tz = try TimeZone.init("UTC");
    const zdt1 = try fromEpochMilliseconds(2000, tz);
    defer zdt1.deinit();
    const zdt2 = try fromEpochMilliseconds(1000, tz);
    defer zdt2.deinit();

    const dur = try zdt1.since(zdt2, .{});
    defer dur.deinit();
}

test startOfDay {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459245123, tz);
    defer zdt.deinit();

    const start = try zdt.startOfDay();
    defer start.deinit();

    try std.testing.expectEqual(@as(u8, 0), start.hour());
    try std.testing.expectEqual(@as(u8, 0), start.minute());
    try std.testing.expectEqual(@as(u8, 0), start.second());
}

test subtract {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(7200000, tz);
    defer zdt.deinit();

    var dur = try Duration.from("PT1H");
    defer dur.deinit();

    const result = try zdt.subtract(dur);
    defer result.deinit();

    try std.testing.expectEqual(@as(i64, 3_600_000), result.epochMilliseconds());
}

test toJSON {
    const zdt = try from("2021-01-01T00:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const json_str = try zdt.toJSON(std.testing.allocator);
    defer std.testing.allocator.free(json_str);

    try std.testing.expect(json_str.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, json_str, "2021") != null);
}

test toLocaleString {
    const zdt = try from("2021-01-01T00:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const locale_str = try zdt.toLocaleString(std.testing.allocator);
    defer std.testing.allocator.free(locale_str);

    try std.testing.expect(locale_str.len > 0);
}

test until {
    const tz = try TimeZone.init("UTC");
    const zdt1 = try fromEpochMilliseconds(1000, tz);
    defer zdt1.deinit();
    const zdt2 = try fromEpochMilliseconds(2000, tz);
    defer zdt2.deinit();

    const dur = try zdt1.until(zdt2, .{});
    defer dur.deinit();
}

test valueOf {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();
    try std.testing.expectError(error.ValueOfNotSupported, zdt.valueOf());
}

test with {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const result = try zdt.with(std.testing.allocator, .{ .year = 2022, .month = 2, .day = 3, .hour = 4 });
    defer result.deinit();

    try std.testing.expectEqual(@as(i32, 2022), result.year());
    try std.testing.expectEqual(@as(u8, 2), result.month());
    try std.testing.expectEqual(@as(u8, 3), result.day());
    try std.testing.expectEqual(@as(u8, 4), result.hour());
}

test withCalendar {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const result = try zdt.withCalendar("iso8601");
    defer result.deinit();

    try std.testing.expectEqual(@as(i32, 2021), result.year());
}

test withPlainTime {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const time = try PlainTime.from("14:30:45");

    const result = try zdt.withPlainTime(time);
    defer result.deinit();

    try std.testing.expectEqual(@as(u8, 14), result.hour());
    try std.testing.expectEqual(@as(u8, 30), result.minute());
}

test withTimeZone {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const utc_tz = try TimeZone.init("UTC");
    const result = try zdt.withTimeZone(utc_tz);
    defer result.deinit();

    try std.testing.expectEqual(@as(i32, 2021), result.year());
}

test calendarId {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const cal_id = try zdt.calendarId(std.testing.allocator);
    defer std.testing.allocator.free(cal_id);
    try std.testing.expect(cal_id.len > 0);
}

test day {
    const zdt = try from("2021-01-02T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u8, 2), zdt.day());
}

test dayOfWeek {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const dow = zdt.dayOfWeek();
    try std.testing.expect(dow >= 1 and dow <= 7);
}

test dayOfYear {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const doy = zdt.dayOfYear();
    try std.testing.expect(doy >= 1 and doy <= 366);
}

test daysInMonth {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const dim = zdt.daysInMonth();
    try std.testing.expectEqual(@as(u16, 31), dim);
}

test daysInWeek {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u16, 7), zdt.daysInWeek());
}

test daysInYear {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u16, 365), zdt.daysInYear());
}

test epochMilliseconds {
    const tz = try TimeZone.init("UTC");
    const zdt = try fromEpochMilliseconds(1609459200000, tz);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(i64, 1609459200000), zdt.epochMilliseconds());
}

test epochNanoseconds {
    const tz = try TimeZone.init("UTC");
    const epoch_ns: i128 = 1609459200123456789;
    const zdt = try fromEpochNanoseconds(epoch_ns, tz);
    defer zdt.deinit();
    try std.testing.expectEqual(epoch_ns, zdt.epochNanoseconds());
}

test era {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const e = try zdt.era(std.testing.allocator);
    if (e) |era_val| {
        defer std.testing.allocator.free(era_val);
        try std.testing.expect(era_val.len > 0);
    }
}

test eraYear {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const ey = zdt.eraYear();
    if (ey) |y| {
        try std.testing.expect(y > 0);
    }
}

test hour {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u8, 12), zdt.hour());
}

test hoursInDay {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const hours = try zdt.hoursInDay();
    try std.testing.expect(hours > 0);
}

test inLeapYear {
    const leap = try from("2020-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer leap.deinit();
    try std.testing.expect(leap.inLeapYear());

    const non_leap = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer non_leap.deinit();
    try std.testing.expect(!non_leap.inLeapYear());
}

test microsecond {
    const zdt = try from("2021-01-01T12:00:00.123456+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const us = zdt.microsecond();
    try std.testing.expect(us >= 0 and us < 1000);
}

test millisecond {
    const zdt = try from("2021-01-01T12:00:00.123456789+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u16, 123), zdt.millisecond());
}

test minute {
    const zdt = try from("2021-01-01T12:34:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u8, 34), zdt.minute());
}

test month {
    const zdt = try from("2021-07-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u8, 7), zdt.month());
}

test monthCode {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const code = try zdt.monthCode(std.testing.allocator);
    defer std.testing.allocator.free(code);
    try std.testing.expectEqualStrings("M01", code);
}

test monthsInYear {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u16, 12), zdt.monthsInYear());
}

test nanosecond {
    const zdt = try from("2021-01-01T12:00:00.123456789+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const ns = zdt.nanosecond();
    try std.testing.expect(ns >= 0 and ns < 1000);
}

test offset {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const off = try zdt.offset(std.testing.allocator);
    defer std.testing.allocator.free(off);
    try std.testing.expectEqualStrings("+00:00", off);
}

test offsetNanoseconds {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const off_ns = zdt.offsetNanoseconds();
    try std.testing.expectEqual(@as(i64, 0), off_ns);
}

test second {
    const zdt = try from("2021-01-01T12:34:56+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(u8, 56), zdt.second());
}

test timeZoneId {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const id = try zdt.timeZoneId(std.testing.allocator);
    defer std.testing.allocator.free(id);
    try std.testing.expectEqualStrings("UTC", id);
}

test weekOfYear {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const woy = zdt.weekOfYear();
    if (woy) |week| {
        try std.testing.expect(week >= 1 and week <= 53);
    }
}

test year {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    try std.testing.expectEqual(@as(i32, 2021), zdt.year());
}

test yearOfWeek {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();
    const yow = zdt.yearOfWeek();
    if (yow) |y| {
        try std.testing.expect(y >= 2020);
    }
}

test clone {
    const zdt = try from("2021-01-01T12:00:00+00:00[UTC]", null, .compatible, .reject);
    defer zdt.deinit();

    const cloned = zdt.clone();
    defer cloned.deinit();

    try std.testing.expectEqual(zdt.epochMilliseconds(), cloned.epochMilliseconds());
}

fn expectZdtString(expected: []const u8, zdt: ZonedDateTime) !void {
    const gpa = std.testing.allocator;
    const s = try zdt.toString(gpa, .{});
    defer gpa.free(s);
    try std.testing.expectEqualStrings(expected, s);
}

test "from fields" {
    const ny = try TimeZone.init("America/New_York");

    // Time zone given in the fields.
    const zdt = try ZonedDateTime.from(.{ .year = 2024, .month = 6, .day = 1, .hour = 12, .time_zone = ny }, null, .compatible, .reject);
    defer zdt.deinit();
    try expectZdtString("2024-06-01T12:00:00-04:00[America/New_York]", zdt);

    // Time zone given as the `time_zone` argument.
    const zdt2 = try ZonedDateTime.from(Fields{ .year = 2024, .month = 6, .day = 1, .hour = 12 }, ny, .compatible, .reject);
    defer zdt2.deinit();
    try std.testing.expect(zdt.equals(zdt2));

    // Out-of-range fields: clamped by default, rejected with `.reject`.
    const constrained = try ZonedDateTime.from(.{ .year = 2024, .month = 2, .day = 30, .time_zone = ny }, null, .compatible, .reject);
    defer constrained.deinit();
    try std.testing.expectEqual(@as(u8, 29), constrained.day());
    try std.testing.expectError(error.RangeError, ZonedDateTime.from(.{ .year = 2024, .month = 2, .day = 30, .time_zone = ny, .overflow = .reject }, null, .compatible, .reject));

    // No time zone at all.
    try std.testing.expectError(error.TypeError, ZonedDateTime.from(.{ .year = 2024, .month = 6, .day = 1 }, null, .compatible, .reject));
}

test "from fields DST disambiguation" {
    const ny = try TimeZone.init("America/New_York");

    // 2024-03-10 02:30 does not exist in New York (spring-forward gap).
    const gap = .{ .year = 2024, .month = 3, .day = 10, .hour = 2, .minute = 30, .time_zone = ny };
    const compatible = try ZonedDateTime.from(gap, null, .compatible, .reject);
    defer compatible.deinit();
    try expectZdtString("2024-03-10T03:30:00-04:00[America/New_York]", compatible);
    const earlier = try ZonedDateTime.from(gap, null, .earlier, .reject);
    defer earlier.deinit();
    try expectZdtString("2024-03-10T01:30:00-05:00[America/New_York]", earlier);
    const later = try ZonedDateTime.from(gap, null, .later, .reject);
    defer later.deinit();
    try expectZdtString("2024-03-10T03:30:00-04:00[America/New_York]", later);
    try std.testing.expectError(error.RangeError, ZonedDateTime.from(gap, null, .reject, .reject));

    // 2024-11-03 01:30 happens twice in New York (fall-back overlap).
    const overlap = .{ .year = 2024, .month = 11, .day = 3, .hour = 1, .minute = 30, .time_zone = ny };
    const first_pass = try ZonedDateTime.from(overlap, null, .earlier, .reject);
    defer first_pass.deinit();
    try expectZdtString("2024-11-03T01:30:00-04:00[America/New_York]", first_pass);
    const second_pass = try ZonedDateTime.from(overlap, null, .later, .reject);
    defer second_pass.deinit();
    try expectZdtString("2024-11-03T01:30:00-05:00[America/New_York]", second_pass);
    try std.testing.expectError(error.RangeError, ZonedDateTime.from(overlap, null, .reject, .reject));

    // An explicit offset picks the matching instant.
    const by_offset = try ZonedDateTime.from(.{ .year = 2024, .month = 11, .day = 3, .hour = 1, .minute = 30, .offset = "-05:00", .time_zone = ny }, null, .compatible, .use_offset);
    defer by_offset.deinit();
    try expectZdtString("2024-11-03T01:30:00-05:00[America/New_York]", by_offset);
}

test "with options" {
    const zdt = try ZonedDateTime.from("2024-01-31T12:00:00-05:00[America/New_York]", null, .compatible, .reject);
    defer zdt.deinit();
    const gpa = std.testing.allocator;

    const constrained = try zdt.with(gpa, .{ .month = 2 });
    defer constrained.deinit();
    try std.testing.expectEqual(@as(u8, 29), constrained.day());

    try std.testing.expectError(error.RangeError, zdt.with(gpa, .{ .month = 2, .overflow = .reject }));

    // Moving into the spring-forward gap honours `disambiguation`.
    try std.testing.expectError(error.RangeError, zdt.with(gpa, .{ .month = 3, .day = 10, .hour = 2, .minute = 30, .disambiguation = .reject }));
}

test addWithOptions {
    const zdt = try ZonedDateTime.from("2024-01-31T12:00:00-05:00[America/New_York]", null, .compatible, .reject);
    defer zdt.deinit();
    const one_month = try Duration.from("P1M");
    defer one_month.deinit();

    const constrained = try zdt.addWithOptions(one_month, .{});
    defer constrained.deinit();
    try std.testing.expectEqual(@as(u8, 29), constrained.day());

    try std.testing.expectError(error.RangeError, zdt.addWithOptions(one_month, .{ .overflow = .reject }));
}

test subtractWithOptions {
    const zdt = try ZonedDateTime.from("2024-03-31T12:00:00-04:00[America/New_York]", null, .compatible, .reject);
    defer zdt.deinit();
    const one_month = try Duration.from("P1M");
    defer one_month.deinit();

    const constrained = try zdt.subtractWithOptions(one_month, .{});
    defer constrained.deinit();
    try std.testing.expectEqual(@as(u8, 29), constrained.day());

    try std.testing.expectError(error.RangeError, zdt.subtractWithOptions(one_month, .{ .overflow = .reject }));
}

// Regression (temporal v0.2.4, test262 PR 5047): a day where midnight occurs twice.
// Ported from temporal's `test_same_date_starts_twice`.
test "same date starts twice (Antarctica/Casey)" {
    const inputs = [_][]const u8{
        "2010-03-04T23:10:00+11:00[Antarctica/Casey]",
        "2010-03-05T00:45:00+11:00[Antarctica/Casey]",
        "2010-03-04T23:10:00+08:00[Antarctica/Casey]",
        "2010-03-05T00:45:00+08:00[Antarctica/Casey]",
    };
    const march4 = "2010-03-04T00:00:00+11:00[Antarctica/Casey]";
    const march5 = "2010-03-05T00:00:00+11:00[Antarctica/Casey]";
    const march6 = "2010-03-06T00:00:00+08:00[Antarctica/Casey]";

    const hours = [_]f64{ 24, 27, 24, 27 };
    const start_of_day = [_][]const u8{ march4, march5, march4, march5 };
    const round_down = start_of_day;
    const round_nearest = [_][]const u8{ march5, march5, march5, march5 };
    const round_up = [_][]const u8{ march5, march6, march5, march6 };

    for (inputs, 0..) |input, i| {
        const zdt = try ZonedDateTime.from(input, null, .compatible, .use_offset);
        defer zdt.deinit();

        try std.testing.expectEqual(hours[i], try zdt.hoursInDay());

        const sod = try zdt.startOfDay();
        defer sod.deinit();
        try expectZdtString(start_of_day[i], sod);

        inline for (.{ RoundingMode.floor, RoundingMode.trunc }) |mode| {
            const r = try zdt.round(.{ .smallest_unit = .day, .rounding_mode = mode });
            defer r.deinit();
            try expectZdtString(round_down[i], r);
        }
        inline for (.{ RoundingMode.half_ceil, RoundingMode.half_even, RoundingMode.half_expand, RoundingMode.half_floor, RoundingMode.half_trunc }) |mode| {
            const r = try zdt.round(.{ .smallest_unit = .day, .rounding_mode = mode });
            defer r.deinit();
            try expectZdtString(round_nearest[i], r);
        }
        inline for (.{ RoundingMode.ceil, RoundingMode.expand }) |mode| {
            const r = try zdt.round(.{ .smallest_unit = .day, .rounding_mode = mode });
            defer r.deinit();
            try expectZdtString(round_up[i], r);
        }
    }
}
