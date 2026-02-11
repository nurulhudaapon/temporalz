// This polyfill is executed in a vm.Script context by test262-runner,
// so it must be synchronous and self-contained.
// The wasm bytes are injected as global.__TEMPORALZ_WASM_BYTES__ by the runner.
(function () {
    if (!globalThis.__TEMPORALZ_WASM_BYTES__) {
        throw new Error("WASM bytes not injected into test context");
    }

    const wasmBinary = globalThis.__TEMPORALZ_WASM_BYTES__;
    const wasmModule = new WebAssembly.Module(wasmBinary);
    const wasmInstance = new WebAssembly.Instance(wasmModule, {
        env: {
            console(ptr, len) {
                const bytes = new Uint8Array(memory.buffer, ptr, len);
                globalThis.console.log(decoder.decode(bytes));
            },
        },
    });

    const exports = wasmInstance.exports;
    const memory = exports.memory;

    const encoder = {
        encode(str) {
            const buf = [];
            for (let i = 0; i < str.length; i++) {
                const code = str.charCodeAt(i);
                if (code < 0x80) {
                    buf.push(code);
                } else if (code < 0x800) {
                    buf.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
                } else if (code < 0xd800 || code >= 0xe000) {
                    buf.push(0xe0 | (code >> 12), 0x80 | ((code >> 6) & 0x3f), 0x80 | (code & 0x3f));
                } else {
                    const code2 = str.charCodeAt(++i);
                    const codePoint = 0x10000 + (((code & 0x3ff) << 10) | (code2 & 0x3ff));
                    buf.push(
                        0xf0 | (codePoint >> 18),
                        0x80 | ((codePoint >> 12) & 0x3f),
                        0x80 | ((codePoint >> 6) & 0x3f),
                        0x80 | (codePoint & 0x3f)
                    );
                }
            }
            return new Uint8Array(buf);
        },
    };

    const decoder = {
        decode(bytes) {
            let str = "";
            for (let i = 0; i < bytes.length; i++) {
                const byte = bytes[i];
                if (byte < 0x80) {
                    str += String.fromCharCode(byte);
                } else if ((byte & 0xe0) === 0xc0) {
                    str += String.fromCharCode(((byte & 0x1f) << 6) | (bytes[++i] & 0x3f));
                } else if ((byte & 0xf0) === 0xe0) {
                    str += String.fromCharCode(
                        ((byte & 0x0f) << 12) | ((bytes[++i] & 0x3f) << 6) | (bytes[++i] & 0x3f)
                    );
                } else if ((byte & 0xf8) === 0xf0) {
                    const codePoint =
                        ((byte & 0x07) << 18) |
                        ((bytes[++i] & 0x3f) << 12) |
                        ((bytes[++i] & 0x3f) << 6) |
                        (bytes[++i] & 0x3f);
                    const high = ((codePoint - 0x10000) >> 10) + 0xd800;
                    const low = ((codePoint - 0x10000) & 0x3ff) + 0xdc00;
                    str += String.fromCharCode(high, low);
                }
            }
            return str;
        },
    };

    function readString(ptr, len) {
        return decoder.decode(new Uint8Array(memory.buffer, ptr, len));
    }

    function lastError() {
        const ptr = exports.temporalz_last_error_ptr();
        const len = exports.temporalz_last_error_len();
        if (!ptr || !len) return new Error("temporalz error");
        const msg = readString(ptr, len);
        exports.temporalz_last_error_clear();
        if (msg.includes("Range")) return new RangeError(msg);
        if (msg.includes("Type")) return new TypeError(msg);
        return new Error(msg);
    }

    function requireHandle(handle) {
        if (!handle) throw lastError();
        return handle;
    }

    function allocString(text) {
        const bytes = encoder.encode(text);
        const ptr = exports.temporalz_alloc(bytes.length);
        if (!ptr) throw lastError();
        new Uint8Array(memory.buffer, ptr, bytes.length).set(bytes);
        return { ptr, len: bytes.length };
    }

    function takeString(packed) {
        if (!packed) throw lastError();
        const value = BigInt(packed);
        const ptr = Number(value >> 32n);
        const len = Number(value & 0xffffffffn);
        const text = readString(ptr, len);
        exports.temporalz_string_free(ptr, len);
        return text;
    }

    function splitI128(value) {
        const v = typeof value === "bigint" ? value : BigInt(value);
        const mask = (1n << 64n) - 1n;
        return { hi: v >> 64n, lo: v & mask };
    }

    function joinI128(hi, lo) {
        const mask = (1n << 64n) - 1n;
        return (BigInt(hi) << 64n) | (BigInt(lo) & mask);
    }

    const unitCodes = {
        nanosecond: 1,
        microsecond: 2,
        millisecond: 3,
        second: 4,
        minute: 5,
        hour: 6,
        day: 7,
        week: 8,
        month: 9,
        year: 10,
        auto: 11,
    };

    const roundingModeCodes = {
        ceil: 1,
        floor: 2,
        expand: 3,
        trunc: 4,
        halfCeil: 5,
        halfFloor: 6,
        halfExpand: 7,
        halfTrunc: 8,
        halfEven: 9,
    };

    function toUnitCode(value, name) {
        if (value === undefined || value === null) return 255;
        const code = unitCodes[value];
        if (!code) throw new RangeError(`Invalid ${name}`);
        return code;
    }

    function toRoundingModeCode(value) {
        if (value === undefined || value === null) return 255;
        const code = roundingModeCodes[value];
        if (!code) throw new RangeError("Invalid roundingMode");
        return code;
    }

    function toIntegerBigInt(value, name) {
        if (typeof value === "bigint") return value;
        const number = Number(value);
        if (!isFiniteNumber(number)) throw new RangeError(`${name} must be finite`);
        if (!Number.isInteger(number)) throw new RangeError(`${name} must be an integer`);
        return BigInt(number);
    }

    function toNumber(value, name) {
        const number = Number(value);
        if (!isFiniteNumber(number)) throw new RangeError(`${name} must be finite`);
        return number;
    }

    function toInteger(value, name) {
        const number = Number(value);
        if (!isFiniteNumber(number)) throw new RangeError(`${name} must be finite`);
        if (!Number.isInteger(number)) throw new RangeError(`${name} must be an integer`);
        return number;
    }

    function isFiniteNumber(value) {
        return value === value && value !== Infinity && value !== -Infinity;
    }

    function unimplemented(name) {
        return function () {
            throw new Error(`${name} is not implemented yet`);
        };
    }

    class Instant {
        constructor(handle) {
            this._handle = handle;
        }

        static _fromHandle(handle) {
            return new Instant(handle);
        }

        static fromEpochMilliseconds(epochMs) {
            const number = Number(epochMs);
            if (!isFiniteNumber(number)) throw new RangeError("epochMilliseconds must be finite");
            const handle = exports.temporalz_instant_from_epoch_milliseconds(number);
            return Instant._fromHandle(requireHandle(handle));
        }

        static fromEpochNanoseconds(epochNs) {
            const parts = splitI128(epochNs);
            const handle = exports.temporalz_instant_from_epoch_nanoseconds_parts(
                parts.hi,
                parts.lo
            );
            return Instant._fromHandle(requireHandle(handle));
        }

        static from(value) {
            if (value instanceof Instant) return value;
            if (typeof value === "string") {
                const text = allocString(value);
                const handle = exports.temporalz_instant_from_utf8(text.ptr, text.len);
                exports.temporalz_free(text.ptr, text.len);
                return Instant._fromHandle(requireHandle(handle));
            }
            if (value && typeof value === "object") {
                if (value.epochNanoseconds !== undefined) {
                    return Instant.fromEpochNanoseconds(value.epochNanoseconds);
                }
                if (value.epochMilliseconds !== undefined) {
                    return Instant.fromEpochMilliseconds(value.epochMilliseconds);
                }
            }
            throw new TypeError("Instant.from expects a string or object");
        }

        get epochMilliseconds() {
            return exports.temporalz_instant_epoch_milliseconds(this._handle);
        }

        get epochNanoseconds() {
            const hi = exports.temporalz_instant_epoch_nanoseconds_hi(this._handle);
            const lo = exports.temporalz_instant_epoch_nanoseconds_lo(this._handle);
            return joinI128(hi, lo);
        }

        toString() {
            return takeString(exports.temporalz_instant_to_string(this._handle));
        }

        toJSON() {
            return this.toString();
        }

        add(durationLike) {
            const dur = Duration.from(durationLike);
            const handle = exports.temporalz_instant_add(this._handle, dur._handle);
            return Instant._fromHandle(requireHandle(handle));
        }

        subtract(durationLike) {
            const dur = Duration.from(durationLike);
            const handle = exports.temporalz_instant_subtract(this._handle, dur._handle);
            return Instant._fromHandle(requireHandle(handle));
        }

        round(options) {
            if (!options || typeof options !== "object") {
                throw new TypeError("round options must be an object");
            }
            const smallestUnit = toUnitCode(options.smallestUnit, "smallestUnit");
            if (smallestUnit === 255) throw new RangeError("smallestUnit is required");
            const roundingMode = toRoundingModeCode(options.roundingMode);

            let roundingIncrement = 0;
            if (options.roundingIncrement !== undefined) {
                const inc = Number(options.roundingIncrement);
                if (!isFiniteNumber(inc) || !Number.isInteger(inc) || inc <= 0) {
                    throw new RangeError("Invalid roundingIncrement");
                }
                roundingIncrement = inc;
            }

            const handle = exports.temporalz_instant_round(
                this._handle,
                smallestUnit,
                roundingMode,
                roundingIncrement
            );
            return Instant._fromHandle(requireHandle(handle));
        }

        equals(other) {
            const rhs = Instant.from(other);
            return exports.temporalz_instant_equals(this._handle, rhs._handle) === 1;
        }

        toLocaleString() {
            return this.toString();
        }

        valueOf() {
            throw new TypeError("Cannot convert Temporal.Instant to a number");
        }

        static compare(a, b) {
            const left = Instant.from(a);
            const right = Instant.from(b);
            return Number(exports.temporalz_instant_compare(left._handle, right._handle));
        }
    }

    const plainDateHandleToken = Symbol("PlainDateHandle");

    class PlainDate {
        constructor(year, month, day) {
            if (year === plainDateHandleToken) {
                this._handle = month;
                return;
            }

            const yearValue = toInteger(year ?? 0, "year");
            const monthValue = toInteger(month ?? 0, "month");
            const dayValue = toInteger(day ?? 0, "day");
            const handle = exports.temporalz_plain_date_init(yearValue, monthValue, dayValue);
            this._handle = requireHandle(handle);
        }

        static _fromHandle(handle) {
            return new PlainDate(plainDateHandleToken, handle);
        }

        static from(value) {
            if (value instanceof PlainDate) return value;
            if (typeof value === "string") {
                const text = allocString(value);
                const handle = exports.temporalz_plain_date_from_utf8(text.ptr, text.len);
                exports.temporalz_free(text.ptr, text.len);
                return PlainDate._fromHandle(requireHandle(handle));
            }
            if (value === null || typeof value !== "object") {
                throw new TypeError("PlainDate.from expects a string or object");
            }

            const year = toInteger(value.year, "year");
            const month = toInteger(value.month, "month");
            const day = toInteger(value.day, "day");
            const handle = exports.temporalz_plain_date_init(year, month, day);
            return PlainDate._fromHandle(requireHandle(handle));
        }

        toString() {
            return takeString(exports.temporalz_plain_date_to_string(this._handle));
        }
    }

    const durationHandleToken = Symbol("DurationHandle");

    class Duration {
        constructor(
            years,
            months,
            weeks,
            days,
            hours,
            minutes,
            seconds,
            milliseconds,
            microseconds,
            nanoseconds
        ) {
            if (years === durationHandleToken) {
                this._handle = months;
                return;
            }

            const yearsValue = toIntegerBigInt(years ?? 0, "years");
            const monthsValue = toIntegerBigInt(months ?? 0, "months");
            const weeksValue = toIntegerBigInt(weeks ?? 0, "weeks");
            const daysValue = toIntegerBigInt(days ?? 0, "days");
            const hoursValue = toIntegerBigInt(hours ?? 0, "hours");
            const minutesValue = toIntegerBigInt(minutes ?? 0, "minutes");
            const secondsValue = toIntegerBigInt(seconds ?? 0, "seconds");
            const millisecondsValue = toIntegerBigInt(milliseconds ?? 0, "milliseconds");
            const microsecondsValue = toNumber(microseconds ?? 0, "microseconds");
            const nanosecondsValue = toNumber(nanoseconds ?? 0, "nanoseconds");

            const created = exports.temporalz_duration_init(
                yearsValue,
                monthsValue,
                weeksValue,
                daysValue,
                hoursValue,
                minutesValue,
                secondsValue,
                millisecondsValue,
                microsecondsValue,
                nanosecondsValue
            );
            this._handle = requireHandle(created);
        }

        static _fromHandle(handle) {
            return new Duration(durationHandleToken, handle);
        }

        static from(value) {
            if (value instanceof Duration) return value;
            if (typeof value === "string") {
                const text = allocString(value);
                const handle = exports.temporalz_duration_from_utf8(text.ptr, text.len);
                exports.temporalz_free(text.ptr, text.len);
                return Duration._fromHandle(requireHandle(handle));
            }
            if (value === null || typeof value !== "object") {
                throw new TypeError("Duration.from expects a string or object");
            }

            const fields = [
                "years",
                "months",
                "weeks",
                "days",
                "hours",
                "minutes",
                "seconds",
                "milliseconds",
                "microseconds",
                "nanoseconds",
            ];

            let mask = 0;
            const values = [0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0, 0];

            fields.forEach((field, index) => {
                if (value[field] !== undefined) {
                    mask |= 1 << index;
                    if (field === "microseconds" || field === "nanoseconds") {
                        values[index] = toNumber(value[field], field);
                    } else {
                        values[index] = toIntegerBigInt(value[field], field);
                    }
                }
            });

            const handle = exports.temporalz_duration_from_parts(
                mask,
                values[0],
                values[1],
                values[2],
                values[3],
                values[4],
                values[5],
                values[6],
                values[7],
                values[8],
                values[9]
            );
            return Duration._fromHandle(requireHandle(handle));
        }

        static compare(a, b, options) {
            const left = Duration.from(a);
            const right = Duration.from(b);
            return Duration.compareWithOptions(left, right, options);
        }

        static compareWithOptions(left, right, options) {
            if (options !== undefined && (options === null || typeof options !== "object")) {
                throw new TypeError("options must be an object");
            }
            const relativeTo = toRelativeTo(options);
            if (!relativeTo && (hasYearMonthWeek(left) || hasYearMonthWeek(right))) {
                throw new RangeError("relativeTo is required for calendar units");
            }
            if (relativeTo) {
                return Number(
                    exports.temporalz_duration_compare_plain_date(
                        left._handle,
                        right._handle,
                        relativeTo._handle
                    )
                );
            }
            return Number(exports.temporalz_duration_compare(left._handle, right._handle));
        }

        add(other) {
            const rhs = Duration.from(other);
            const handle = exports.temporalz_duration_add(this._handle, rhs._handle);
            return Duration._fromHandle(requireHandle(handle));
        }

        subtract(other) {
            const rhs = Duration.from(other);
            const handle = exports.temporalz_duration_subtract(this._handle, rhs._handle);
            return Duration._fromHandle(requireHandle(handle));
        }

        abs() {
            const handle = exports.temporalz_duration_abs(this._handle);
            return Duration._fromHandle(requireHandle(handle));
        }

        negated() {
            const handle = exports.temporalz_duration_negated(this._handle);
            return Duration._fromHandle(requireHandle(handle));
        }

        round(options = {}) {
            if (options === undefined) options = {};
            if (options === null || typeof options !== "object") {
                throw new TypeError("round options must be an object");
            }
            const relativeTo = toRelativeTo(options);
            if (!relativeTo && hasCalendarUnits(this)) {
                throw new RangeError("relativeTo is required for calendar units");
            }
            const smallestUnit = toUnitCode(options.smallestUnit, "smallestUnit");
            const largestUnit = toUnitCode(options.largestUnit, "largestUnit");
            const roundingMode = toRoundingModeCode(options.roundingMode);

            let roundingIncrement = 0;
            if (options.roundingIncrement !== undefined) {
                const inc = Number(options.roundingIncrement);
                if (!Number.isFinite(inc) || !Number.isInteger(inc) || inc <= 0) {
                    throw new RangeError("Invalid roundingIncrement");
                }
                roundingIncrement = inc;
            }

            const handle = relativeTo
                ? exports.temporalz_duration_round_plain_date(
                    this._handle,
                    smallestUnit,
                    largestUnit,
                    roundingMode,
                    roundingIncrement,
                    relativeTo._handle
                )
                : exports.temporalz_duration_round(
                    this._handle,
                    smallestUnit,
                    largestUnit,
                    roundingMode,
                    roundingIncrement
                );
            return Duration._fromHandle(requireHandle(handle));
        }

        total(options) {
            if (!options || typeof options !== "object") {
                throw new TypeError("total options must be an object");
            }
            const relativeTo = toRelativeTo(options);
            if (!relativeTo && hasCalendarUnits(this)) {
                throw new RangeError("relativeTo is required for calendar units");
            }
            const unit = toUnitCode(options.unit, "unit");
            if (unit === 255) throw new RangeError("Invalid unit");
            const result = relativeTo
                ? exports.temporalz_duration_total_plain_date(
                    this._handle,
                    unit,
                    relativeTo._handle
                )
                : exports.temporalz_duration_total(this._handle, unit);
            if (!Number.isFinite(result)) throw lastError();
            return result;
        }

        get sign() {
            return Number(exports.temporalz_duration_sign(this._handle));
        }

        get blank() {
            return exports.temporalz_duration_blank(this._handle) === 1;
        }

        toString() {
            return takeString(exports.temporalz_duration_to_string(this._handle));
        }

        toJSON() {
            return this.toString();
        }

        toLocaleString() {
            return this.toString();
        }

        valueOf() {
            throw new TypeError("Cannot convert Temporal.Duration to a number");
        }

        get years() {
            return Number(exports.temporalz_duration_years(this._handle));
        }

        get months() {
            return Number(exports.temporalz_duration_months(this._handle));
        }

        get weeks() {
            return Number(exports.temporalz_duration_weeks(this._handle));
        }

        get days() {
            return Number(exports.temporalz_duration_days(this._handle));
        }

        get hours() {
            return Number(exports.temporalz_duration_hours(this._handle));
        }

        get minutes() {
            return Number(exports.temporalz_duration_minutes(this._handle));
        }

        get seconds() {
            return Number(exports.temporalz_duration_seconds(this._handle));
        }

        get milliseconds() {
            return Number(exports.temporalz_duration_milliseconds(this._handle));
        }

        get microseconds() {
            return Number(exports.temporalz_duration_microseconds(this._handle));
        }

        get nanoseconds() {
            return Number(exports.temporalz_duration_nanoseconds(this._handle));
        }
    }

    function hasCalendarUnits(duration) {
        return (
            duration.years !== 0 ||
            duration.months !== 0 ||
            duration.weeks !== 0 ||
            duration.days !== 0
        );
    }

    function hasYearMonthWeek(duration) {
        return duration.years !== 0 || duration.months !== 0 || duration.weeks !== 0;
    }

    function toRelativeTo(options) {
        if (!options || options.relativeTo === undefined) return null;
        const rel = options.relativeTo;
        if (rel instanceof PlainDate) return rel;
        if (typeof rel === "string") return PlainDate.from(rel);
        if (rel && typeof rel === "object") return PlainDate.from(rel);
        throw new TypeError("Invalid relativeTo");
    }

    const Temporal = {
        Instant,
        Duration,
        Now: {
            instant: unimplemented("Temporal.Now.instant"),
            plainDateISO: unimplemented("Temporal.Now.plainDateISO"),
            plainDateTimeISO: unimplemented("Temporal.Now.plainDateTimeISO"),
            plainTimeISO: unimplemented("Temporal.Now.plainTimeISO"),
            timeZoneId: unimplemented("Temporal.Now.timeZoneId"),
            zonedDateTimeISO: unimplemented("Temporal.Now.zonedDateTimeISO"),
        },
        PlainDate,
        PlainTime: unimplemented("Temporal.PlainTime"),
        PlainDateTime: unimplemented("Temporal.PlainDateTime"),
        PlainYearMonth: unimplemented("Temporal.PlainYearMonth"),
        PlainMonthDay: unimplemented("Temporal.PlainMonthDay"),
        ZonedDateTime: unimplemented("Temporal.ZonedDateTime"),
    };

    globalThis.Temporal = Temporal;
})();
