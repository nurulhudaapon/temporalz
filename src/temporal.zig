const abi = @import("abi.zig");
const c = abi.c;

/// Time unit for Temporal operations.
/// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal
pub const Unit = enum {
    auto,
    nanosecond,
    microsecond,
    millisecond,
    second,
    minute,
    hour,
    day,
    week,
    month,
    year,

    pub fn toCApi(self: Unit) c_uint {
        return switch (self) {
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
};

/// Rounding mode for Temporal operations.
/// See: https://tc39.es/ecma402/#table-sanctioned-single-unit-identifiers
pub const RoundingMode = enum {
    /// Round toward positive infinity
    ceil,
    /// Round toward negative infinity
    floor,
    /// Round away from zero
    expand,
    /// Round toward zero (truncate)
    trunc,
    /// Round half toward positive infinity
    half_ceil,
    /// Round half toward negative infinity
    half_floor,
    /// Round half away from zero
    half_expand,
    /// Round half toward zero
    half_trunc,
    /// Round half to even (banker's rounding)
    half_even,

    pub fn toCApi(self: RoundingMode) c_uint {
        return switch (self) {
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
};

/// Sign of a duration or time value.
pub const Sign = enum {
    positive,
    zero,
    negative,

    pub fn toCApi(self: Sign) c_int {
        return switch (self) {
            .positive => c.Sign_Positive,
            .zero => c.Sign_Zero,
            .negative => c.Sign_Negative,
        };
    }

    pub fn fromCApi(value: c_int) Sign {
        return switch (value) {
            c.Sign_Positive => .positive,
            c.Sign_Zero => .zero,
            c.Sign_Negative => .negative,
            else => .zero,
        };
    }
};

/// Options for rounding operations (Instant.round, Duration.round, etc.).
/// MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/round
pub const RoundingOptions = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,

    pub fn toCApi(self: RoundingOptions) c.RoundingOptions {
        return .{
            .largest_unit = abi.toUnitOption(toCUnit(self.largest_unit)),
            .smallest_unit = abi.toUnitOption(toCUnit(self.smallest_unit)),
            .rounding_mode = abi.toRoundingModeOption(toCRoundingMode(self.rounding_mode)),
            .increment = abi.toOption(c.OptionU32, self.rounding_increment),
        };
    }
};

/// Options for computing differences between instants.
/// MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Instant/until
pub const DifferenceSettings = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,

    pub fn toCApi(self: DifferenceSettings) c.DifferenceSettings {
        return .{
            .largest_unit = abi.toUnitOption(toCUnit(self.largest_unit)),
            .smallest_unit = abi.toUnitOption(toCUnit(self.smallest_unit)),
            .rounding_mode = abi.toRoundingModeOption(toCRoundingMode(self.rounding_mode)),
            .increment = abi.toOption(c.OptionU32, self.rounding_increment),
        };
    }
};

/// Options for Duration.toString() formatting.
/// MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toString
pub const ToStringRoundingOptions = struct {
    fractional_second_digits: ?u8 = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,

    pub fn toCApi(self: ToStringRoundingOptions) c.ToStringRoundingOptions {
        const precision: c.Precision = if (self.fractional_second_digits) |fsd|
            .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, fsd) }
        else if (self.smallest_unit) |su|
            switch (su) {
                .second => .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, 0) },
                .millisecond => .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, 3) },
                .microsecond => .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, 6) },
                .nanosecond => .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, 9) },
                else => .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, null) },
            }
        else
            .{ .is_minute = false, .precision = abi.toOption(c.OptionU8, null) };

        return .{
            .precision = precision,
            .smallest_unit = abi.toUnitOption(toCUnit(self.smallest_unit)),
            .rounding_mode = abi.toRoundingModeOption(toCRoundingMode(self.rounding_mode)),
        };
    }
};

pub fn toCUnit(opt: ?Unit) ?c.Unit {
    return if (opt) |u| @as(c.Unit, @intCast(u.toCApi())) else null;
}

pub fn toCRoundingMode(opt: ?RoundingMode) ?c.RoundingMode {
    return if (opt) |m| @as(c.RoundingMode, @intCast(m.toCApi())) else null;
}
