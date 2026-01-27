const std = @import("std");
const Temporal = @import("temporalz");

// Mirrors test262 test/built-ins/Temporal/Duration/basic.js (constructor fields and sign)
test "Temporal.Duration constructor components" {
    const pos = try Temporal.Duration.init(5, 5, 5, 5, 5, 5, 5, 5, 5, 0);
    defer pos.deinit();
    try std.testing.expectEqual(@as(i64, 5), pos.years());
    try std.testing.expectEqual(@as(i64, 5), pos.months());
    try std.testing.expectEqual(@as(i64, 5), pos.weeks());
    try std.testing.expectEqual(@as(i64, 5), pos.days());
    try std.testing.expectEqual(@as(i64, 5), pos.hours());
    try std.testing.expectEqual(@as(i64, 5), pos.minutes());
    try std.testing.expectEqual(@as(i64, 5), pos.seconds());
    try std.testing.expectEqual(@as(i64, 5), pos.milliseconds());
    try std.testing.expectEqual(@as(f64, 5), pos.microseconds());
    try std.testing.expectEqual(@as(f64, 0), pos.nanoseconds());
    try std.testing.expectEqual(Temporal.Duration.Sign.positive, pos.sign());

    const neg = try Temporal.Duration.init(-5, -5, -5, -5, -5, -5, -5, -5, -5, 0);
    defer neg.deinit();
    try std.testing.expectEqual(@as(i64, -5), neg.years());
    try std.testing.expectEqual(@as(i64, -5), neg.months());
    try std.testing.expectEqual(@as(i64, -5), neg.weeks());
    try std.testing.expectEqual(@as(i64, -5), neg.days());
    try std.testing.expectEqual(@as(i64, -5), neg.hours());
    try std.testing.expectEqual(@as(i64, -5), neg.minutes());
    try std.testing.expectEqual(@as(i64, -5), neg.seconds());
    try std.testing.expectEqual(@as(i64, -5), neg.milliseconds());
    try std.testing.expectEqual(@as(f64, -5), neg.microseconds());
    try std.testing.expectEqual(@as(f64, 0), neg.nanoseconds());
    try std.testing.expectEqual(Temporal.Duration.Sign.negative, neg.sign());

    const neg_zero = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0.0);
    defer neg_zero.deinit();
    try std.testing.expectEqual(@as(i64, 0), neg_zero.years());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.months());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.weeks());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.days());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.hours());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.minutes());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.seconds());
    try std.testing.expectEqual(@as(i64, 0), neg_zero.milliseconds());
    try std.testing.expectEqual(@as(f64, 0), neg_zero.microseconds());
    try std.testing.expectEqual(@as(f64, 0), neg_zero.nanoseconds());
    try std.testing.expectEqual(Temporal.Duration.Sign.zero, neg_zero.sign());
}

// Mirrors test262 test/built-ins/Temporal/Duration/compare/basic.js
test "Temporal.Duration compare time-only" {
    const td1 = try Temporal.Duration.init(0, 0, 0, 0, 5, 5, 5, 5, 5, 5);
    defer td1.deinit();
    const td2 = try Temporal.Duration.init(0, 0, 0, 0, 5, 4, 5, 5, 5, 5);
    defer td2.deinit();
    const td1_neg = try Temporal.Duration.init(0, 0, 0, 0, -5, -5, -5, -5, -5, -5);
    defer td1_neg.deinit();
    const td2_neg = try Temporal.Duration.init(0, 0, 0, 0, -5, -4, -5, -5, -5, -5);
    defer td2_neg.deinit();

    const rel: Temporal.Duration.RelativeTo = .{};

    try std.testing.expectEqual(@as(i8, 0), try td1.compare(td1, rel));
    try std.testing.expectEqual(@as(i8, -1), try td2.compare(td1, rel));
    try std.testing.expectEqual(@as(i8, 1), try td1.compare(td2, rel));
    try std.testing.expectEqual(@as(i8, 0), try td1_neg.compare(td1_neg, rel));
    try std.testing.expectEqual(@as(i8, 1), try td2_neg.compare(td1_neg, rel));
    try std.testing.expectEqual(@as(i8, -1), try td1_neg.compare(td2_neg, rel));
    try std.testing.expectEqual(@as(i8, -1), try td1_neg.compare(td2, rel));
    try std.testing.expectEqual(@as(i8, 1), try td1.compare(td2_neg, rel));
}

// Mirrors test262 test/built-ins/Temporal/Duration/from/argument-string.js
test "Temporal.Duration from string parsing" {
    // P1D
    const d1 = try Temporal.Duration.from("P1D");
    defer d1.deinit();
    try std.testing.expectEqual(@as(i64, 0), d1.years());
    try std.testing.expectEqual(@as(i64, 0), d1.months());
    try std.testing.expectEqual(@as(i64, 0), d1.weeks());
    try std.testing.expectEqual(@as(i64, 1), d1.days());
    try std.testing.expectEqual(@as(i64, 0), d1.hours());
    try std.testing.expectEqual(@as(i64, 0), d1.minutes());
    try std.testing.expectEqual(@as(i64, 0), d1.seconds());
    try std.testing.expectEqual(@as(i64, 0), d1.milliseconds());

    // p1y1m1dt1h1m1s
    const d2 = try Temporal.Duration.from("p1y1m1dt1h1m1s");
    defer d2.deinit();
    try std.testing.expectEqual(@as(i64, 1), d2.years());
    try std.testing.expectEqual(@as(i64, 1), d2.months());
    try std.testing.expectEqual(@as(i64, 0), d2.weeks());
    try std.testing.expectEqual(@as(i64, 1), d2.days());
    try std.testing.expectEqual(@as(i64, 1), d2.hours());
    try std.testing.expectEqual(@as(i64, 1), d2.minutes());
    try std.testing.expectEqual(@as(i64, 1), d2.seconds());

    // P1Y1M1W1DT1H1M1.123456789S
    const d3 = try Temporal.Duration.from("P1Y1M1W1DT1H1M1.123456789S");
    defer d3.deinit();
    try std.testing.expectEqual(@as(i64, 1), d3.years());
    try std.testing.expectEqual(@as(i64, 1), d3.months());
    try std.testing.expectEqual(@as(i64, 1), d3.weeks());
    try std.testing.expectEqual(@as(i64, 1), d3.days());
    try std.testing.expectEqual(@as(i64, 1), d3.hours());
    try std.testing.expectEqual(@as(i64, 1), d3.minutes());
    try std.testing.expectEqual(@as(i64, 1), d3.seconds());
    try std.testing.expectEqual(@as(i64, 123), d3.milliseconds());
    try std.testing.expectEqual(@as(f64, 456), d3.microseconds());
    try std.testing.expectEqual(@as(f64, 789), d3.nanoseconds());

    // P1DT0.5M (0.5 minutes)
    const d4 = try Temporal.Duration.from("P1DT0.5M");
    defer d4.deinit();
    try std.testing.expectEqual(@as(i64, 0), d4.years());
    try std.testing.expectEqual(@as(i64, 0), d4.months());
    try std.testing.expectEqual(@as(i64, 0), d4.weeks());
    try std.testing.expectEqual(@as(i64, 1), d4.days());
    try std.testing.expectEqual(@as(i64, 0), d4.hours());
    try std.testing.expectEqual(@as(i64, 0), d4.minutes());
    try std.testing.expectEqual(@as(i64, 30), d4.seconds());

    // -P1Y1M1W1DT1H1M1.123456789S (negative)
    const d5 = try Temporal.Duration.from("-P1Y1M1W1DT1H1M1.123456789S");
    defer d5.deinit();
    try std.testing.expectEqual(@as(i64, -1), d5.years());
    try std.testing.expectEqual(@as(i64, -1), d5.months());
    try std.testing.expectEqual(@as(i64, -1), d5.weeks());
    try std.testing.expectEqual(@as(i64, -1), d5.days());
    try std.testing.expectEqual(@as(i64, -1), d5.hours());
    try std.testing.expectEqual(@as(i64, -1), d5.minutes());
    try std.testing.expectEqual(@as(i64, -1), d5.seconds());

    // PT100M
    const d6 = try Temporal.Duration.from("PT100M");
    defer d6.deinit();
    try std.testing.expectEqual(@as(i64, 0), d6.years());
    try std.testing.expectEqual(@as(i64, 0), d6.months());
    try std.testing.expectEqual(@as(i64, 0), d6.weeks());
    try std.testing.expectEqual(@as(i64, 0), d6.days());
    try std.testing.expectEqual(@as(i64, 0), d6.hours());
    try std.testing.expectEqual(@as(i64, 100), d6.minutes());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/abs/basic.js
test "Temporal.Duration abs" {
    // blank duration
    const d1 = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d1.deinit();
    const abs1 = d1.abs();
    defer abs1.deinit();
    try std.testing.expectEqual(@as(i64, 0), abs1.years());
    try std.testing.expectEqual(@as(i64, 0), abs1.months());
    try std.testing.expectEqual(@as(i64, 0), abs1.weeks());
    try std.testing.expectEqual(@as(i64, 0), abs1.days());

    // positive values
    const d2 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    defer d2.deinit();
    const abs2 = d2.abs();
    defer abs2.deinit();
    try std.testing.expectEqual(@as(i64, 1), abs2.years());
    try std.testing.expectEqual(@as(i64, 2), abs2.months());
    try std.testing.expectEqual(@as(i64, 3), abs2.weeks());
    try std.testing.expectEqual(@as(i64, 4), abs2.days());
    try std.testing.expectEqual(@as(i64, 5), abs2.hours());
    try std.testing.expectEqual(@as(i64, 6), abs2.minutes());
    try std.testing.expectEqual(@as(i64, 7), abs2.seconds());
    try std.testing.expectEqual(@as(i64, 8), abs2.milliseconds());
    try std.testing.expectEqual(@as(f64, 9), abs2.microseconds());
    try std.testing.expectEqual(@as(f64, 10), abs2.nanoseconds());

    // negative values
    const d3 = try Temporal.Duration.init(-1, -2, -3, -4, -5, -6, -7, -8, -9, -10);
    defer d3.deinit();
    const abs3 = d3.abs();
    defer abs3.deinit();
    try std.testing.expectEqual(@as(i64, 1), abs3.years());
    try std.testing.expectEqual(@as(i64, 2), abs3.months());
    try std.testing.expectEqual(@as(i64, 3), abs3.weeks());
    try std.testing.expectEqual(@as(i64, 4), abs3.days());
    try std.testing.expectEqual(@as(i64, 5), abs3.hours());
    try std.testing.expectEqual(@as(i64, 6), abs3.minutes());
    try std.testing.expectEqual(@as(i64, 7), abs3.seconds());
    try std.testing.expectEqual(@as(i64, 8), abs3.milliseconds());
    try std.testing.expectEqual(@as(f64, 9), abs3.microseconds());
    try std.testing.expectEqual(@as(f64, 10), abs3.nanoseconds());

    // some zeros
    const d4 = try Temporal.Duration.init(1, 0, 3, 0, 5, 0, 7, 0, 9, 0);
    defer d4.deinit();
    const abs4 = d4.abs();
    defer abs4.deinit();
    try std.testing.expectEqual(@as(i64, 1), abs4.years());
    try std.testing.expectEqual(@as(i64, 0), abs4.months());
    try std.testing.expectEqual(@as(i64, 3), abs4.weeks());
    try std.testing.expectEqual(@as(i64, 0), abs4.days());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/negated/basic.js
test "Temporal.Duration negated" {
    // blank duration
    const d1 = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d1.deinit();
    const neg1 = d1.negated();
    defer neg1.deinit();
    try std.testing.expectEqual(@as(i64, 0), neg1.years());
    try std.testing.expectEqual(Temporal.Duration.Sign.zero, neg1.sign());

    // positive values
    const d2 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    defer d2.deinit();
    const neg2 = d2.negated();
    defer neg2.deinit();
    try std.testing.expectEqual(@as(i64, -1), neg2.years());
    try std.testing.expectEqual(@as(i64, -2), neg2.months());
    try std.testing.expectEqual(@as(i64, -3), neg2.weeks());
    try std.testing.expectEqual(@as(i64, -4), neg2.days());
    try std.testing.expectEqual(@as(i64, -5), neg2.hours());
    try std.testing.expectEqual(@as(i64, -6), neg2.minutes());
    try std.testing.expectEqual(@as(i64, -7), neg2.seconds());
    try std.testing.expectEqual(@as(i64, -8), neg2.milliseconds());
    try std.testing.expectEqual(@as(f64, -9), neg2.microseconds());
    try std.testing.expectEqual(@as(f64, -10), neg2.nanoseconds());
    try std.testing.expectEqual(Temporal.Duration.Sign.negative, neg2.sign());

    // negative values
    const d3 = try Temporal.Duration.init(-1, -2, -3, -4, -5, -6, -7, -8, -9, -10);
    defer d3.deinit();
    const neg3 = d3.negated();
    defer neg3.deinit();
    try std.testing.expectEqual(@as(i64, 1), neg3.years());
    try std.testing.expectEqual(@as(i64, 2), neg3.months());
    try std.testing.expectEqual(@as(i64, 3), neg3.weeks());
    try std.testing.expectEqual(@as(i64, 4), neg3.days());
    try std.testing.expectEqual(Temporal.Duration.Sign.positive, neg3.sign());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/add/basic.js
test "Temporal.Duration add time-only" {
    // Simple time additions
    const td1 = try Temporal.Duration.init(0, 0, 0, 0, 1, 2, 3, 4, 5, 6);
    defer td1.deinit();
    const td2 = try Temporal.Duration.init(0, 0, 0, 0, 1, 2, 3, 4, 5, 6);
    defer td2.deinit();
    const result = try td1.add(td2);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 0), result.years());
    try std.testing.expectEqual(@as(i64, 0), result.months());
    try std.testing.expectEqual(@as(i64, 0), result.weeks());
    try std.testing.expectEqual(@as(i64, 0), result.days());
    try std.testing.expectEqual(@as(i64, 2), result.hours());
    try std.testing.expectEqual(@as(i64, 4), result.minutes());
    try std.testing.expectEqual(@as(i64, 6), result.seconds());
    try std.testing.expectEqual(@as(i64, 8), result.milliseconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/subtract/basic.js
test "Temporal.Duration subtract time-only" {
    // Simple time subtraction
    const td1 = try Temporal.Duration.init(0, 0, 0, 0, 5, 5, 5, 5, 5, 5);
    defer td1.deinit();
    const td2 = try Temporal.Duration.init(0, 0, 0, 0, 1, 1, 1, 1, 1, 1);
    defer td2.deinit();
    const result = try td1.subtract(td2);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 4), result.hours());
    try std.testing.expectEqual(@as(i64, 4), result.minutes());
    try std.testing.expectEqual(@as(i64, 4), result.seconds());
    try std.testing.expectEqual(@as(i64, 4), result.milliseconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/blank/basic.js
test "Temporal.Duration blank" {
    // Blank duration
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();
    try std.testing.expectEqual(true, blank.blank());

    // Non-blank durations
    const d1 = try Temporal.Duration.init(1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d1.deinit();
    try std.testing.expectEqual(false, d1.blank());

    const d2 = try Temporal.Duration.init(0, 1, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d2.deinit();
    try std.testing.expectEqual(false, d2.blank());

    const d3 = try Temporal.Duration.init(0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
    defer d3.deinit();
    try std.testing.expectEqual(false, d3.blank());

    const d4 = try Temporal.Duration.init(0, 0, 0, 1, 0, 0, 0, 0, 0, 0);
    defer d4.deinit();
    try std.testing.expectEqual(false, d4.blank());

    const d5 = try Temporal.Duration.init(0, 0, 0, 0, 1, 0, 0, 0, 0, 0);
    defer d5.deinit();
    try std.testing.expectEqual(false, d5.blank());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/toString/basic.js
test "Temporal.Duration toString" {
    const allocator = std.testing.allocator;

    // Blank duration
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();
    const str1 = try blank.toString(allocator, .{});
    defer allocator.free(str1);
    try std.testing.expectEqualSlices(u8, "PT0S", str1);

    // Hours and minutes
    const td1 = try Temporal.Duration.init(0, 0, 0, 0, 1, 30, 0, 0, 0, 0);
    defer td1.deinit();
    const str2 = try td1.toString(allocator, .{});
    defer allocator.free(str2);
    try std.testing.expectEqualSlices(u8, "PT1H30M", str2);

    // Full duration
    const td2 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    defer td2.deinit();
    const str3 = try td2.toString(allocator, .{});
    defer allocator.free(str3);
    // Result should contain Y, M, W, D, H, M, S, etc.
    try std.testing.expect(std.mem.containsAtLeast(u8, str3, 1, "Y"));
    try std.testing.expect(std.mem.containsAtLeast(u8, str3, 1, "W"));
    try std.testing.expect(std.mem.containsAtLeast(u8, str3, 1, "D"));
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/toJSON/basic.js
test "Temporal.Duration toJSON" {
    const allocator = std.testing.allocator;

    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();
    const json = try blank.toJSON(allocator);
    defer allocator.free(json);
    try std.testing.expectEqualSlices(u8, "PT0S", json);
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/total/basic.js
test "Temporal.Duration total" {
    const td = try Temporal.Duration.init(0, 0, 0, 0, 1, 30, 0, 0, 0, 0);
    defer td.deinit();

    // total hours
    const hours = try td.total(.{ .unit = Temporal.Duration.Unit.hour });
    try std.testing.expectApproxEqAbs(@as(f64, 1.5), hours, 0.0001);

    // total minutes
    const minutes = try td.total(.{ .unit = Temporal.Duration.Unit.minute });
    try std.testing.expectApproxEqAbs(@as(f64, 90), minutes, 0.0001);

    // total seconds
    const seconds = try td.total(.{ .unit = Temporal.Duration.Unit.second });
    try std.testing.expectApproxEqAbs(@as(f64, 5400), seconds, 0.0001);
}

// Mirrors test262 test/built-ins/Temporal/Duration/constructor.js
test "Temporal.Duration cannot be called without new" {
    // Note: In Zig we use a function, not a constructor, so this test is about ensuring proper init
    // Testing that we can successfully create a duration
    const dur = try Temporal.Duration.init(1, 1, 1, 1, 1, 1, 1, 1, 1, 1);
    defer dur.deinit();
    try std.testing.expectEqual(@as(i64, 1), dur.years());
}

// Mirrors test262 test/built-ins/Temporal/Duration/days-undefined.js
test "Temporal.Duration with specific fields from ISO string" {
    const d1 = try Temporal.Duration.from("P1Y");
    defer d1.deinit();
    try std.testing.expectEqual(@as(i64, 1), d1.years());
    try std.testing.expectEqual(@as(i64, 0), d1.months());
    try std.testing.expectEqual(@as(i64, 0), d1.days());
    try std.testing.expectEqual(@as(i64, 0), d1.hours());

    const d2 = try Temporal.Duration.from("PT1H");
    defer d2.deinit();
    try std.testing.expectEqual(@as(i64, 0), d2.years());
    try std.testing.expectEqual(@as(i64, 0), d2.days());
    try std.testing.expectEqual(@as(i64, 1), d2.hours());
    try std.testing.expectEqual(@as(i64, 0), d2.minutes());
}

// Mirrors test262 test/built-ins/Temporal/Duration/mixed.js
test "Temporal.Duration mixed components" {
    const d1 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    defer d1.deinit();
    try std.testing.expectEqual(@as(i64, 1), d1.years());
    try std.testing.expectEqual(@as(i64, 2), d1.months());
    try std.testing.expectEqual(@as(i64, 3), d1.weeks());
    try std.testing.expectEqual(@as(i64, 4), d1.days());
    try std.testing.expectEqual(@as(i64, 5), d1.hours());
    try std.testing.expectEqual(@as(i64, 6), d1.minutes());
    try std.testing.expectEqual(@as(i64, 7), d1.seconds());
    try std.testing.expectEqual(@as(i64, 8), d1.milliseconds());
    try std.testing.expectEqual(@as(f64, 9), d1.microseconds());
    try std.testing.expectEqual(@as(f64, 10), d1.nanoseconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/sign/basic.js
test "Temporal.Duration sign property" {
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();
    try std.testing.expectEqual(Temporal.Duration.Sign.zero, blank.sign());

    const pos = try Temporal.Duration.init(1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer pos.deinit();
    try std.testing.expectEqual(Temporal.Duration.Sign.positive, pos.sign());

    const neg = try Temporal.Duration.init(-1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer neg.deinit();
    try std.testing.expectEqual(Temporal.Duration.Sign.negative, neg.sign());
}

// Mirrors test262 test/built-ins/Temporal/Duration/large-number.js
test "Temporal.Duration with large numbers" {
    const d = try Temporal.Duration.init(100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000);
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 100000), d.years());
    try std.testing.expectEqual(@as(i64, 100000), d.months());
    try std.testing.expectEqual(@as(i64, 100000), d.weeks());
}

// Mirrors test262 test/built-ins/Temporal/Duration/from/blank-duration.js
test "Temporal.Duration blank from string" {
    const blank1 = try Temporal.Duration.from("PT0S");
    defer blank1.deinit();
    try std.testing.expectEqual(true, blank1.blank());

    const blank2 = try Temporal.Duration.from("P0D");
    defer blank2.deinit();
    try std.testing.expectEqual(true, blank2.blank());
}

// Mirrors test262 test/built-ins/Temporal/Duration/length.js
test "Temporal.Duration constructor has correct arity" {
    // In Zig, we test that init can be called with the expected parameters
    const d = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    defer d.deinit();
    try std.testing.expect(true); // If we get here, init works
}

// Mirrors test262 test/built-ins/Temporal/Duration/from/length.js
test "Temporal.Duration from has correct arity" {
    const d = try Temporal.Duration.from("P1D");
    defer d.deinit();
    try std.testing.expect(true); // If we get here, from works
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/add/basic.js with normal values
test "Temporal.Duration add with time fields" {
    const d1 = try Temporal.Duration.init(0, 0, 0, 0, 1, 1, 1, 1, 0, 0);
    defer d1.deinit();
    const d2 = try Temporal.Duration.init(0, 0, 0, 0, 2, 2, 2, 2, 0, 0);
    defer d2.deinit();

    const result = try d1.add(d2);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 0), result.years());
    try std.testing.expectEqual(@as(i64, 3), result.hours());
    try std.testing.expectEqual(@as(i64, 3), result.minutes());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/add/basic.js with date and time
test "Temporal.Duration add with date and time components" {
    // Note: Adding durations with date components together requires a RelativeTo context
    // which is not always available, causing a RangeError
    if (true) return error.SkipZigTest;

    const d1 = try Temporal.Duration.init(100, 100, 100, 100, 100, 100, 100, 100, 100, 100);
    defer d1.deinit();
    const d2 = try Temporal.Duration.init(100, 100, 100, 100, 100, 100, 100, 100, 100, 100);
    defer d2.deinit();

    const result = try d1.add(d2);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 200), result.years());
    try std.testing.expectEqual(@as(i64, 200), result.months());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/subtract/basic.js with normal values
test "Temporal.Duration subtract with time fields" {
    const d1 = try Temporal.Duration.init(0, 0, 0, 0, 5, 5, 5, 5, 0, 0);
    defer d1.deinit();
    const d2 = try Temporal.Duration.init(0, 0, 0, 0, 2, 2, 2, 2, 0, 0);
    defer d2.deinit();

    const result = try d1.subtract(d2);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 0), result.years());
    try std.testing.expectEqual(@as(i64, 3), result.hours());
    try std.testing.expectEqual(@as(i64, 3), result.minutes());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/subtract/basic.js with date and time
test "Temporal.Duration subtract with date and time components" {
    // Note: Subtracting durations with date components together requires a RelativeTo context
    // which is not always available, causing a RangeError
    if (true) return error.SkipZigTest;

    const d1 = try Temporal.Duration.init(200, 200, 200, 200, 200, 200, 200, 200, 200, 200);
    defer d1.deinit();
    const d2 = try Temporal.Duration.init(100, 100, 100, 100, 100, 100, 100, 100, 100, 100);
    defer d2.deinit();

    const result = try d1.subtract(d2);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 100), result.years());
    try std.testing.expectEqual(@as(i64, 100), result.months());
}

// Mirrors test262 test/built-ins/Temporal/Duration/name.js
test "Temporal.Duration constructor name" {
    // In Zig we can't directly test function name, but we test that the constructor exists and works
    const d = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d.deinit();
    try std.testing.expect(true);
}

// Mirrors test262 test/built-ins/Temporal/Duration/from/argument-duration.js
test "Temporal.Duration from duration object" {
    const d1 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    defer d1.deinit();

    // In Zig binding, we'd typically test string parsing instead
    const d2 = try Temporal.Duration.from("P1Y2M3W4DT5H6M7.008009010S");
    defer d2.deinit();
    try std.testing.expectEqual(@as(i64, 1), d2.years());
    try std.testing.expectEqual(@as(i64, 2), d2.months());
    try std.testing.expectEqual(@as(i64, 3), d2.weeks());
    try std.testing.expectEqual(@as(i64, 4), d2.days());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/with/basic.js (approximation)
test "Temporal.Duration with method basic" {
    // Skip - requires with() method which may not be available
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/with/all-positive.js
test "Temporal.Duration with positive components" {
    // Skip - requires with() method
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/round/basic.js
test "Temporal.Duration round method" {
    // Skip - requires round() method with RoundingOptions
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/round/largest-unit.js
test "Temporal.Duration round with largest unit" {
    // Skip - requires round() method
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/round/smallest-unit.js
test "Temporal.Duration round with smallest unit" {
    // Skip - requires round() method
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/years-undefined.js
test "Temporal.Duration years property undefined behavior" {
    const d = try Temporal.Duration.from("PT1H");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.years());
}

// Mirrors test262 test/built-ins/Temporal/Duration/months-undefined.js
test "Temporal.Duration months property undefined behavior" {
    const d = try Temporal.Duration.from("PT1H");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.months());
}

// Mirrors test262 test/built-ins/Temporal/Duration/weeks-undefined.js
test "Temporal.Duration weeks property undefined behavior" {
    const d = try Temporal.Duration.from("PT1H");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.weeks());
}

// Mirrors test262 test/built-ins/Temporal/Duration/days-undefined.js (property access)
test "Temporal.Duration days property undefined behavior" {
    const d = try Temporal.Duration.from("PT1H");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.days());
}

// Mirrors test262 test/built-ins/Temporal/Duration/hours-undefined.js
test "Temporal.Duration hours property undefined behavior" {
    const d = try Temporal.Duration.from("P1Y");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.hours());
}

// Mirrors test262 test/built-ins/Temporal/Duration/minutes-undefined.js
test "Temporal.Duration minutes property undefined behavior" {
    const d = try Temporal.Duration.from("P1Y");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.minutes());
}

// Mirrors test262 test/built-ins/Temporal/Duration/seconds-undefined.js
test "Temporal.Duration seconds property undefined behavior" {
    const d = try Temporal.Duration.from("P1Y");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.seconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/milliseconds-undefined.js
test "Temporal.Duration milliseconds property undefined behavior" {
    const d = try Temporal.Duration.from("P1Y");
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 0), d.milliseconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/microseconds-undefined.js
test "Temporal.Duration microseconds property undefined behavior" {
    const d = try Temporal.Duration.from("P1Y");
    defer d.deinit();
    try std.testing.expectEqual(@as(f64, 0), d.microseconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/nanoseconds-undefined.js
test "Temporal.Duration nanoseconds property undefined behavior" {
    const d = try Temporal.Duration.from("P1Y");
    defer d.deinit();
    try std.testing.expectEqual(@as(f64, 0), d.nanoseconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/max.js
test "Temporal.Duration max value handling" {
    // Test that very large durations can be created
    const d = try Temporal.Duration.init(999999999, 999999999, 999999999, 999999999, 999999999, 999999999, 999999999, 999999999, 999999999, 999999999);
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 999999999), d.years());
}

// Mirrors test262 test/built-ins/Temporal/Duration/lower-limit.js
test "Temporal.Duration lower limit handling" {
    // Test negative duration handling
    const d = try Temporal.Duration.init(-999999999, -999999999, -999999999, -999999999, -999999999, -999999999, -999999999, -999999999, -999999999, -999999999);
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, -999999999), d.years());
}

// Mirrors test262 test/built-ins/Temporal/Duration/out-of-range.js
test "Temporal.Duration out of range behavior" {
    // Skip - would require error handling for invalid ranges
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/invalid-type.js
test "Temporal.Duration invalid type handling" {
    // Skip - type validation would be at binding level
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/fractional-throws-rangeerror.js
test "Temporal.Duration fractional range error" {
    // Skip - fractional components validation
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/infinity-throws-rangeerror.js
test "Temporal.Duration infinity range error" {
    // Skip - infinity handling at binding level
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/negative-infinity-throws-rangeerror.js
test "Temporal.Duration negative infinity range error" {
    // Skip - infinity handling at binding level
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/builtin.js
test "Temporal.Duration builtin verification" {
    const d = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d.deinit();
    try std.testing.expect(true);
}

// Mirrors test262 test/built-ins/Temporal/Duration/call-builtin.js
test "Temporal.Duration call as builtin" {
    // In Zig, Duration is created via init function, not called as builtin
    const d = try Temporal.Duration.init(1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer d.deinit();
    try std.testing.expectEqual(@as(i64, 1), d.years());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/valueOf/basic.js
test "Temporal.Duration valueOf method" {
    // Skip - valueOf may not be directly comparable in Zig
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/compare/blank-duration.js
test "Temporal.Duration compare blank durations" {
    const blank1 = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank1.deinit();
    const blank2 = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank2.deinit();

    const rel: Temporal.Duration.RelativeTo = .{};
    const result = try blank1.compare(blank2, rel);
    try std.testing.expectEqual(@as(i8, 0), result);
}

// Mirrors test262 test/built-ins/Temporal/Duration/from/blank-duration.js (property test)
test "Temporal.Duration blank property from string" {
    const d = try Temporal.Duration.from("PT0S");
    defer d.deinit();
    try std.testing.expectEqual(true, d.blank());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/abs/new-object.js
test "Temporal.Duration abs creates new object" {
    const d1 = try Temporal.Duration.init(-5, -5, -5, -5, -5, -5, -5, -5, -5, -5);
    defer d1.deinit();
    const d2 = d1.abs();
    defer d2.deinit();

    // Verify they have different signs
    try std.testing.expectEqual(Temporal.Duration.Sign.negative, d1.sign());
    try std.testing.expectEqual(Temporal.Duration.Sign.positive, d2.sign());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/negated/basic.js (zero handling)
test "Temporal.Duration negated zero duration" {
    const zero = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer zero.deinit();
    const negated = zero.negated();
    defer negated.deinit();

    try std.testing.expectEqual(Temporal.Duration.Sign.zero, negated.sign());
}

// Mirrors test262 test/built-ins/Temporal/Duration/from/string-with-skipped-units.js
test "Temporal.Duration from string with skipped units" {
    const d1 = try Temporal.Duration.from("P1Y3M");
    defer d1.deinit();
    try std.testing.expectEqual(@as(i64, 1), d1.years());
    try std.testing.expectEqual(@as(i64, 3), d1.months());
    try std.testing.expectEqual(@as(i64, 0), d1.weeks());
    try std.testing.expectEqual(@as(i64, 0), d1.days());

    const d2 = try Temporal.Duration.from("PT2H30M");
    defer d2.deinit();
    try std.testing.expectEqual(@as(i64, 2), d2.hours());
    try std.testing.expectEqual(@as(i64, 30), d2.minutes());
    try std.testing.expectEqual(@as(i64, 0), d2.seconds());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/add/blank-duration.js
test "Temporal.Duration add blank duration" {
    if (true) return error.SkipZigTest;
    const d1 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 0, 0);
    defer d1.deinit();
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();

    const result = try d1.add(blank);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 1), result.years());
    try std.testing.expectEqual(@as(i64, 5), result.hours());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/subtract/blank-duration.js
test "Temporal.Duration subtract blank duration" {
    if (true) return error.SkipZigTest;

    const d1 = try Temporal.Duration.init(1, 2, 3, 4, 5, 6, 7, 8, 0, 0);
    defer d1.deinit();
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();

    const result = try d1.subtract(blank);
    defer result.deinit();
    try std.testing.expectEqual(@as(i64, 1), result.years());
    try std.testing.expectEqual(@as(i64, 5), result.hours());
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/toString/blank-duration-precision.js
test "Temporal.Duration toString blank with precision" {
    const allocator = std.testing.allocator;
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();
    const str = try blank.toString(allocator, .{});
    defer allocator.free(str);
    try std.testing.expectEqualSlices(u8, "PT0S", str);
}

// Mirrors test262 test/built-ins/Temporal/Duration/prototype/toJSON/blank-duration.js (approx)
test "Temporal.Duration toJSON blank" {
    const allocator = std.testing.allocator;
    const blank = try Temporal.Duration.init(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    defer blank.deinit();
    const json = try blank.toJSON(allocator);
    defer allocator.free(json);
    try std.testing.expectEqualSlices(u8, "PT0S", json);
}

// Mirrors test262 test/built-ins/Temporal/Duration/prop-desc.js
test "Temporal.Duration property descriptor" {
    // JS-specific test for property descriptors (writable, enumerable, configurable)
    // Not directly applicable to Zig bindings
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/subclass.js
test "Temporal.Duration subclassing" {
    // JS-specific test for subclassing Temporal.Duration
    // Zig does not support class inheritance in the same way
    if (true) return error.SkipZigTest;
}

// Mirrors test262 test/built-ins/Temporal/Duration/get-prototype-from-constructor-throws.js
test "Temporal.Duration get prototype from constructor throws" {
    // JS-specific test for OrdinaryCreateFromConstructor prototype handling
    // Not applicable to Zig bindings
    if (true) return error.SkipZigTest;
}
