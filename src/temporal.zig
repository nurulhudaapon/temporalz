/// # Temporal Types and Utilities
///
/// This file defines core types and options used throughout the Temporal API implementation.
///
/// - [MDN Temporal](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal)
/// ## Unit
/// Time unit for Temporal operations (e.g., nanosecond, second, day, year).
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
};

/// ## RoundingMode
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
};

/// ## Sign
/// Sign of a duration or time value.
pub const Sign = enum {
    positive,
    zero,
    negative,
};

/// ## RoundingOptions
/// Options for rounding operations (e.g., Instant.round, Duration.round).
///
/// - [MDN: Duration.round](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/round)
pub const RoundingOptions = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,
};

/// ## DifferenceSettings
/// Options for computing differences between instants.
///
/// - [MDN: Instant.until](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Instant/until)
pub const DifferenceSettings = struct {
    largest_unit: ?Unit = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
    rounding_increment: ?u32 = null,
};

/// ## ToStringRoundingOptions
/// Options for Duration.toString() formatting.
///
/// - [MDN: Duration.toString](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Temporal/Duration/toString)
pub const ToStringRoundingOptions = struct {
    fractional_second_digits: ?u8 = null,
    smallest_unit: ?Unit = null,
    rounding_mode: ?RoundingMode = null,
};

/// ## TimeZone
/// Time zone identifier for Temporal operations.
pub const TimeZone = struct {
    _inner: abi.c.TimeZone,

    /// Initialize a TimeZone from an identifier string.
    pub fn init(id: []const u8) TimeZone {
        const view = abi.toDiplomatStringView(id);
        return .{ ._inner = .{ .id = view } };
    }
};

const abi = @import("abi.zig");
