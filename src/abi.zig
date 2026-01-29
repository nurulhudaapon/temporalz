const std = @import("std");

pub const c = @cImport({
    @cInclude("AnyCalendarKind.h");
    @cInclude("Calendar.h");
    @cInclude("Duration.h");
    @cInclude("ErrorKind.h");
    @cInclude("I128Nanoseconds.h");
    @cInclude("Instant.h");
    @cInclude("OwnedRelativeTo.h");
    @cInclude("ParsedDate.h");
    @cInclude("ParsedDateTime.h");
    @cInclude("ParsedZonedDateTime.h");
    @cInclude("PlainDate.h");
    @cInclude("PlainDateTime.h");
    @cInclude("PlainMonthDay.h");
    @cInclude("PlainTime.h");
    @cInclude("PlainYearMonth.h");
    @cInclude("RelativeTo.h");
    @cInclude("TimeZone.h");
    @cInclude("ZonedDateTime.h");
});

pub const to_string_rounding_options_auto: c.ToStringRoundingOptions = .{
    .precision = .{ .is_minute = false, .precision = toOption(c.OptionU8, null) },
    .smallest_unit = toUnitOption(null),
    .rounding_mode = toRoundingModeOption(null),
};

const u64_high_bit_mask: u64 = 1 << 63;

/// Covert a Rust `I128Nanoseconds` struct to a Zig `i128`.
///
/// Ported from temporal_rs's [`From<ffi::I128Nanoseconds>`](https://github.com/boa-dev/temporal/blob/89bfca1f5b918d00a19354664e1da11da51305ee/temporal_capi/src/instant.rs#L172-L186) trait for `i128`.
pub fn fromI128Nanoseconds(ns: c.I128Nanoseconds) i128 {
    const is_neg = (ns.high & u64_high_bit_mask) != 0;
    const ns_high: u128 = @intCast((ns.high & ~u64_high_bit_mask));
    const total: i128 = @intCast((ns_high << 64) + ns.low);
    return if (is_neg) -total else total;
}

/// Covert a Zig `i128` to a Rust `I128Nanoseconds` struct.
///
/// Ported from temporal_rs's [`From<i128>`](https://github.com/boa-dev/temporal/blob/89bfca1f5b918d00a19354664e1da11da51305ee/temporal_capi/src/instant.rs#L188-L207) trait for `ffi::I128Nanoseconds`.
pub fn toI128Nanoseconds(ns: i128) c.I128Nanoseconds {
    std.debug.assert(ns != std.math.minInt(i128));
    const is_neg = ns < 0;
    const ns_abs = @abs(ns);
    const high: u64 = @intCast(ns_abs >> 64);
    const low: u64 = @truncate(ns_abs);
    return .{ .high = if (is_neg) high | u64_high_bit_mask else high, .low = low };
}

/// Convert a Rust `DiplomatStringView` to a Zig slice.
pub fn fromDiplomatStringView(sv: c.DiplomatStringView) []const u8 {
    return sv.data[0..sv.len];
}

/// Convert a Zig slice to a Rust `DiplomatStringView`.
pub fn toDiplomatStringView(s: []const u8) c.DiplomatStringView {
    return .{ .data = s.ptr, .len = s.len };
}

/// Convert a Zig slice to a Rust `DiplomatString16View`.
pub fn toDiplomatString16View(s: []const u16) c.DiplomatString16View {
    return .{ .data = s.ptr, .len = s.len };
}

/// Convert a Rust `Option<T>` to a Zig `?T`.
pub fn fromOption(value: anytype) ?Success(@TypeOf(value)) {
    return success(value);
}

/// Convert a Zig `?T` to a Rust `Option<T>`.
pub fn toOption(comptime T: type, maybe_value: ?Success(T)) T {
    return if (maybe_value) |value|
        .{ .is_ok = true, .unnamed_0 = .{ .ok = value } }
    else
        .{ .is_ok = false };
}

/// Convert a Zig `?ArithmeticOverflow` to a Rust `Option<ArithmeticOverflow>`.
pub fn toArithmeticOverflowOption(maybe_value: ?c.RoundingMode) c.ArithmeticOverflow_option {
    return toOption(c.ArithmeticOverflow_option, maybe_value);
}

/// Convert a Zig `?Disambiguation` to a Rust `Option<Disambiguation>`.
pub fn toDisambiguationOption(maybe_value: ?c.Disambiguation) c.Disambiguation_option {
    return toOption(c.Disambiguation_option, maybe_value);
}

/// Convert a Zig `?OffsetDisambiguation` to a Rust `Option<OffsetDisambiguation>`.
pub fn toOffsetDisambiguationOption(maybe_value: ?c.OffsetDisambiguation) c.OffsetDisambiguation_option {
    return toOption(c.OffsetDisambiguation_option, maybe_value);
}

/// Convert a Zig `?PartialDate` to a Rust `Option<PartialDate>`.
pub fn toPartialDateOption(maybe_value: ?c.PartialDate) c.PartialDate_option {
    return toOption(c.PartialDate_option, maybe_value);
}

/// Convert a Zig `?RoundingMode` to a Rust `Option<RoundingMode>`.
pub fn toRoundingModeOption(maybe_value: ?c.RoundingMode) c.RoundingMode_option {
    return toOption(c.RoundingMode_option, maybe_value);
}

/// Convert a Zig `?TimeZone` to a Rust `Option<TimeZone>`.
pub fn toTimeZoneOption(maybe_value: ?c.TimeZone) c.TimeZone_option {
    return toOption(c.TimeZone_option, maybe_value);
}

/// Convert a Zig `?Unit` to a Rust `Option<Unit>`.
pub fn toUnitOption(maybe_value: ?c.Unit) c.Unit_option {
    return toOption(c.Unit_option, maybe_value);
}

// Wraps values from a `c.RelativeTo` or `c.OwnedRelativeTo`.
pub const RelativeTo = union(enum) {
    none,
    owned_plain_date: *c.PlainDate,
    owned_zoned_date_time: *c.ZonedDateTime,
    borrowed_plain_date: *const c.PlainDate,
    borrowed_zoned_date_time: *const c.ZonedDateTime,

    pub fn fromOwned(owned: c.OwnedRelativeTo) RelativeTo {
        if (owned.date) |plain_date| {
            return .{ .owned_plain_date = plain_date };
        } else if (owned.zoned) |zoned_date_time| {
            return .{ .owned_zoned_date_time = zoned_date_time };
        } else {
            return .none;
        }
    }

    pub fn toRust(self: RelativeTo) c.RelativeTo {
        return switch (self) {
            .none => .{ .date = null, .zoned = null },
            .owned_plain_date => |plain_date| .{ .date = plain_date, .zoned = null },
            .owned_zoned_date_time => |zoned_date_time| .{ .date = null, .zoned = zoned_date_time },
            .borrowed_plain_date => |plain_date| .{ .date = plain_date, .zoned = null },
            .borrowed_zoned_date_time => |zoned_date_time| .{ .date = null, .zoned = zoned_date_time },
        };
    }

    pub fn deinit(self: RelativeTo) void {
        switch (self) {
            .owned_plain_date => |plain_date| c.temporal_rs_PlainDate_destroy(plain_date),
            .owned_zoned_date_time => |zoned_date_time| c.temporal_rs_ZonedDateTime_destroy(zoned_date_time),
            else => {},
        }
    }
};

pub const DiplomatWrite = struct {
    gpa: std.mem.Allocator,
    array_list: std.ArrayList(u8),
    inner: c.DiplomatWrite,

    pub fn init(gpa: std.mem.Allocator) DiplomatWrite {
        return .{
            .gpa = gpa,
            .array_list = .empty,
            .inner = .{
                // NOTE: We use `@fieldParentPtr()` on the `inner` struct field to get to the other
                //       fields instead of creating a context externally and storing a pointer.
                .context = null,
                .buf = undefined,
                .len = 0,
                .cap = 0,
                .grow_failed = false,
                .flush = flush,
                .grow = grow,
            },
        };
    }

    pub fn deinit(self: *DiplomatWrite) void {
        self.array_list.deinit(self.gpa);
    }

    pub fn toOwnedSlice(self: *DiplomatWrite) std.mem.Allocator.Error![]u8 {
        if (self.inner.grow_failed) return error.OutOfMemory;
        self.inner = undefined; // Invalidate the inner struct to prevent further writes
        return self.array_list.toOwnedSlice(self.gpa);
    }

    fn flush(inner: ?*c.DiplomatWrite) callconv(.c) void {
        const self: *DiplomatWrite = @fieldParentPtr("inner", inner.?);
        self.array_list.items.len = inner.?.len;
    }

    fn grow(inner: ?*c.DiplomatWrite, size: usize) callconv(.c) bool {
        const self: *DiplomatWrite = @fieldParentPtr("inner", inner.?);
        self.array_list.ensureTotalCapacity(self.gpa, size) catch return false;
        inner.?.buf = self.array_list.items.ptr;
        inner.?.cap = self.array_list.capacity;
        return true;
    }
};

test DiplomatWrite {
    const gpa = std.testing.allocator;
    var write = DiplomatWrite.init(gpa);
    defer write.deinit();

    const WriteImpl = struct {
        inner: *c.DiplomatWrite,

        // https://github.com/rust-diplomat/diplomat/blob/2b903255187976779798fc89df3fee7298641c80/runtime/src/write.rs#L70-L73
        pub fn flush(self: @This()) void {
            self.inner.flush.?(self.inner);
        }

        // https://github.com/rust-diplomat/diplomat/blob/2b903255187976779798fc89df3fee7298641c80/runtime/src/write.rs#L76-L94
        pub fn writeStr(self: @This(), s: []const u8) void {
            if (self.inner.grow_failed) {
                return;
            }
            const needed_len = self.inner.len + s.len;
            if (needed_len > self.inner.cap) {
                const success_ = self.inner.grow.?(self.inner, needed_len);
                if (!success_) {
                    self.inner.grow_failed = true;
                    return;
                }
            }
            std.debug.assert(needed_len <= self.inner.cap);
            @memcpy(self.inner.buf[self.inner.len..][0..s.len], s);
            self.inner.len = needed_len;
        }
    };

    var write_impl: WriteImpl = .{ .inner = &write.inner };
    write_impl.writeStr("Hello World");
    write_impl.flush();

    try std.testing.expectEqual(write.array_list.items.ptr, write.inner.buf);
    try std.testing.expectEqual(write.array_list.items.len, write.inner.len);
    try std.testing.expectEqual(write.array_list.capacity, write.inner.cap);
    try std.testing.expectEqual(false, write.inner.grow_failed);
    try std.testing.expectEqualSlices(u8, "Hello World", write.array_list.items);

    const slice = try write.toOwnedSlice();
    defer gpa.free(slice);
    try std.testing.expectEqualSlices(u8, "Hello World", slice);
    try std.testing.expectEqualSlices(u8, &.{}, write.array_list.items);
}

/// Converts a "result" value to its "success" type, or returns `null` if the value is an error.
/// This is `inline` to prevent binary bloat, because each instantiation is expected to be called
/// only once.
pub inline fn success(result: anytype) ?Success(@TypeOf(result)) {
    if (!result.is_ok) return null;
    if (Success(@TypeOf(result)) == void) return;
    return result.unnamed_0.ok;
}

/// Given the C API representation of a `Result<T, E>`, returns the type 'T'.
pub fn Success(comptime Result: type) type {
    const Union = @FieldType(Result, "unnamed_0");
    if (!@hasField(Union, "ok")) return void;
    return @FieldType(Union, "ok");
}

/// Temporal error set mapping to C API error kinds
pub const TemporalError = error{
    /// Generic temporal error
    Generic,
    /// Type error (invalid type or conversion)
    TypeError,
    /// Range error (value out of valid range)
    RangeError,
    /// Syntax error (invalid format or parsing)
    SyntaxError,
    /// Assertion failed (should not happen)
    AssertionFailed,
    /// Other unspecified error
    Unknown,
};

/// Extract result from C API, mapping errors to specific Zig error types.
pub inline fn extractResult(result: anytype) TemporalError!Success(@TypeOf(result)) {
    if (success(result)) |value| return value;

    // Handle the error - check if the union has an 'err' field
    const Union = @FieldType(@TypeOf(result), "unnamed_0");
    if (@hasField(Union, "err")) {
        const err = result.unnamed_0.err;
        // const message = if (fromOption(err.msg)) |sv|
        //     fromDiplomatStringView(sv)
        // else
        //     "(no error message)";

        return switch (err.kind) {
            c.ErrorKind_Generic => TemporalError.Generic,
            c.ErrorKind_Type => TemporalError.TypeError,
            c.ErrorKind_Range => TemporalError.RangeError,
            c.ErrorKind_Syntax => TemporalError.SyntaxError,
            c.ErrorKind_Assert => @panic("temporal_rs assertion failed"),
            else => TemporalError.Unknown,
        };
    }

    // Fallback for result types without detailed error information
    return TemporalError.Generic;
}

const t = @import("temporal.zig");
const dur = @import("Duration.zig");
const ins = @import("Instant.zig");

pub const to = struct {
        pub fn toTimeZone(val: anytype) c.TimeZone {
            return val._inner;
        }

        pub fn toDisambiguation(d: anytype) c.Disambiguation {
            return switch (d) {
                .compatible => c.Disambiguation_Compatible,
                .earlier => c.Disambiguation_Earlier,
                .later => c.Disambiguation_Later,
                .reject => c.Disambiguation_Reject,
            };
        }

        pub fn toOffsetDisambiguation(o: anytype) c.OffsetDisambiguation {
            return switch (o) {
                .use_offset => c.OffsetDisambiguation_Use,
                .prefer_offset => c.OffsetDisambiguation_Prefer,
                .ignore_offset => c.OffsetDisambiguation_Ignore,
                .reject => c.OffsetDisambiguation_Reject,
            };
        }

        pub fn calendarDisplay(cd: anytype) c.DisplayCalendar {
            return switch (cd) {
                .auto => c.DisplayCalendar_Auto,
                .always => c.DisplayCalendar_Always,
                .never => c.DisplayCalendar_Never,
                .critical => c.DisplayCalendar_Critical,
            };
        }

        pub fn displayOffset(o: anytype) c.DisplayOffset {
            return switch (o) {
                .auto => c.DisplayOffset_Auto,
                .never => c.DisplayOffset_Never,
            };
        }

        pub fn toDisplayTimeZone(val: anytype) c.DisplayTimeZone {
            return switch (val) {
                .auto => c.DisplayTimeZone_Auto,
                .never => c.DisplayTimeZone_Never,
                .critical => c.DisplayTimeZone_Critical,
            };
        }
    pub fn unit(opt: ?t.Unit) ?c.Unit {
        return if (opt) |u| @as(c.Unit, @intCast(to.unitToCApi(u))) else null;
    }

    fn unitToCApi(u: t.Unit) c_uint {
        return switch (u) {
            .auto => c.Unit_Auto,
            .nanosecond => c.Unit_Nanosecond,
            .microsecond => c.Unit_Microsecond,
            .millisecond => c.Unit_Millisecond,
            .second => c.Unit_Second,
            .minute => c.Unit_Minute,
            .hour => c.Unit_Hour,
            .day => c.Unit_Day,
            .week => c.Unit_Week,
            .month => c.Unit_Month,
            .year => c.Unit_Year,
        };
    }

    pub fn roundingMode(opt: ?t.RoundingMode) ?c.RoundingMode {
        return if (opt) |m| @as(c.RoundingMode, @intCast(to.roundingModeToCApi(m))) else null;
    }

    fn roundingModeToCApi(m: t.RoundingMode) c_uint {
        return switch (m) {
            .ceil => c.RoundingMode_Ceil,
            .floor => c.RoundingMode_Floor,
            .expand => c.RoundingMode_Expand,
            .trunc => c.RoundingMode_Trunc,
            .half_ceil => c.RoundingMode_HalfCeil,
            .half_floor => c.RoundingMode_HalfFloor,
            .half_expand => c.RoundingMode_HalfExpand,
            .half_trunc => c.RoundingMode_HalfTrunc,
            .half_even => c.RoundingMode_HalfEven,
        };
    }

    pub fn sign(opt: ?t.Sign) ?c.Sign {
        return if (opt) |s| @as(c.Sign, @intCast(to.signToCApi(s))) else null;
    }

    fn signToCApi(s: t.Sign) c_int {
        return switch (s) {
            .positive => c.Sign_Positive,
            .zero => c.Sign_Zero,
            .negative => c.Sign_Negative,
        };
    }

    pub fn strRoundingOpts(self: t.ToStringRoundingOptions) c.ToStringRoundingOptions {
        const precision: c.Precision = if (self.fractional_second_digits) |fsd|
            .{ .is_minute = false, .precision = toOption(c.OptionU8, fsd) }
        else if (self.smallest_unit) |su|
            switch (su) {
                .second => .{ .is_minute = false, .precision = toOption(c.OptionU8, 0) },
                .millisecond => .{ .is_minute = false, .precision = toOption(c.OptionU8, 3) },
                .microsecond => .{ .is_minute = false, .precision = toOption(c.OptionU8, 6) },
                .nanosecond => .{ .is_minute = false, .precision = toOption(c.OptionU8, 9) },
                else => .{ .is_minute = false, .precision = toOption(c.OptionU8, null) },
            }
        else
            .{ .is_minute = false, .precision = toOption(c.OptionU8, null) };

        return .{
            .precision = precision,
            .smallest_unit = toUnitOption(unit(self.smallest_unit)),
            .rounding_mode = toRoundingModeOption(roundingMode(self.rounding_mode)),
        };
    }

    pub fn durRoundingOpts(self: dur.RoundingOptions) c.RoundingOptions {
        return .{
            .largest_unit = toUnitOption(unit(self.largest_unit)),
            .smallest_unit = toUnitOption(unit(self.smallest_unit)),
            .rounding_mode = toRoundingModeOption(roundingMode(self.rounding_mode)),
            .increment = toOption(c.OptionU32, self.rounding_increment),
        };
    }

    pub fn tz(self: ins.TimeZone) c.TimeZone {
        return self._inner;
    }

    pub fn partialdur(self: dur.PartialDuration) c.PartialDuration {
        return .{
            .years = toOption(c.OptionI64, self.years),
            .months = toOption(c.OptionI64, self.months),
            .weeks = toOption(c.OptionI64, self.weeks),
            .days = toOption(c.OptionI64, self.days),
            .hours = toOption(c.OptionI64, self.hours),
            .minutes = toOption(c.OptionI64, self.minutes),
            .seconds = toOption(c.OptionI64, self.seconds),
            .milliseconds = toOption(c.OptionI64, self.milliseconds),
            .microseconds = toOption(c.OptionF64, self.microseconds),
            .nanoseconds = toOption(c.OptionF64, self.nanoseconds),
        };
    }

    pub fn durRelativeTo(self: dur.RelativeTo) c.RelativeTo {
        switch (self) {
            .plain_date => |pd| return .{ .date = pd._inner },
            .zoned_date_time => |zdt| return .{ .zoned = zdt._inner },
            .plain_date_time => |pdt| return .{ .date = (pdt.toPlainDate() catch unreachable)._inner },
        }
    }

    pub fn roundingOpts(self: t.RoundingOptions) c.RoundingOptions {
        return .{
            .largest_unit = toUnitOption(to.unit(self.largest_unit)),
            .smallest_unit = toUnitOption(to.unit(self.smallest_unit)),
            .rounding_mode = toRoundingModeOption(to.roundingMode(self.rounding_mode)),
            .increment = toOption(c.OptionU32, self.rounding_increment),
        };
    }

    pub fn diffsettings(self: t.DifferenceSettings) c.DifferenceSettings {
        return .{
            .largest_unit = toUnitOption(to.unit(self.largest_unit)),
            .smallest_unit = toUnitOption(to.unit(self.smallest_unit)),
            .rounding_mode = toRoundingModeOption(to.roundingMode(self.rounding_mode)),
            .increment = toOption(c.OptionU32, self.rounding_increment),
        };
    }
};

pub const from = struct {
    pub fn sign(value: c_int) t.Sign {
        return switch (value) {
            c.Sign_Positive => .positive,
            c.Sign_Zero => .zero,
            c.Sign_Negative => .negative,
            else => .zero,
        };
    }
};
