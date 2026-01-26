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
