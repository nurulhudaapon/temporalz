const Instant = @import("Instant.zig");
const PlainDate = @import("PlainDate.zig");
const PlainDateTime = @import("PlainDateTime.zig");
const PlainTime = @import("PlainTime.zig");
const ZonedDateTime = @import("ZonedDateTime.zig");

const Now = @This();

pub fn instant() error{Todo}!Instant {
    return error.Todo;
}

pub fn plainDateISO() error{Todo}!PlainDate {
    return error.Todo;
}

pub fn plainDateTimeISO() error{Todo}!PlainDateTime {
    return error.Todo;
}

pub fn plainTimeISO() error{Todo}!PlainTime {
    return error.Todo;
}

pub fn timeZoneId() error{Todo}![]const u8 {
    return error.Todo;
}

pub fn zonedDateTimeISO() error{Todo}!ZonedDateTime {
    return error.Todo;
}

// ---------- Tests ---------------------
test instant {
    if (true) return error.Todo;
}

test plainDateISO {
    if (true) return error.Todo;
}
test plainDateTimeISO {
    if (true) return error.Todo;
}
test plainTimeISO {
    if (true) return error.Todo;
}
test timeZoneId {
    if (true) return error.Todo;
}
test zonedDateTimeISO {
    if (true) return error.Todo;
}
