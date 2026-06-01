// Thin polyfill: all real logic lives in the Zig WASM module. JS only handles
// ECMAScript-spec coercion rules (which the host language must enforce) and
// surface plumbing (brand checks, prototypes, descriptors, error mapping).
(function () {
    if (!globalThis.__TEMPORALZ_WASM_BYTES__) {
        throw new Error("WASM bytes not injected into test context");
    }

    const wasmModule = new WebAssembly.Module(globalThis.__TEMPORALZ_WASM_BYTES__);
    const wasmInstance = new WebAssembly.Instance(wasmModule, {
        env: { console: (ptr, len) => globalThis.console.log(decodeUtf8(memory.buffer, ptr, len)) },
    });

    const x = wasmInstance.exports;
    const memory = x.memory;

    // --- utf8 codec (vm.Script context has no TextEncoder) -----------------
    function encodeUtf8(str) {
        const buf = [];
        for (let i = 0; i < str.length; i++) {
            const c = str.charCodeAt(i);
            if (c < 0x80) buf.push(c);
            else if (c < 0x800) buf.push(0xc0 | (c >> 6), 0x80 | (c & 0x3f));
            else if (c < 0xd800 || c >= 0xe000) buf.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
            else {
                const c2 = str.charCodeAt(++i);
                const cp = 0x10000 + (((c & 0x3ff) << 10) | (c2 & 0x3ff));
                buf.push(0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3f), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f));
            }
        }
        return new Uint8Array(buf);
    }
    function decodeUtf8(buf, ptr, len) {
        const bytes = new Uint8Array(buf, ptr, len);
        let s = "";
        for (let i = 0; i < bytes.length; i++) {
            const b = bytes[i];
            if (b < 0x80) s += String.fromCharCode(b);
            else if ((b & 0xe0) === 0xc0) s += String.fromCharCode(((b & 0x1f) << 6) | (bytes[++i] & 0x3f));
            else if ((b & 0xf0) === 0xe0) s += String.fromCharCode(((b & 0x0f) << 12) | ((bytes[++i] & 0x3f) << 6) | (bytes[++i] & 0x3f));
            else {
                const cp = ((b & 0x07) << 18) | ((bytes[++i] & 0x3f) << 12) | ((bytes[++i] & 0x3f) << 6) | (bytes[++i] & 0x3f);
                const hi = ((cp - 0x10000) >> 10) + 0xd800;
                const lo = ((cp - 0x10000) & 0x3ff) + 0xdc00;
                s += String.fromCharCode(hi, lo);
            }
        }
        return s;
    }

    // --- error mapping using Zig's reported error kind ---------------------
    function lastError() {
        const kind = Number(x.temporalz_last_error_kind());
        const ptr = Number(x.temporalz_last_error_ptr());
        const len = Number(x.temporalz_last_error_len());
        const msg = ptr && len ? decodeUtf8(memory.buffer, ptr, len) : "temporalz error";
        x.temporalz_last_error_clear();
        switch (kind) {
            case 2: return new TypeError(msg);
            case 3: return new RangeError(msg);
            case 4: return new SyntaxError(msg);
            default: return new RangeError(msg);
        }
    }
    function need(h) {
        if (!h) throw lastError();
        return Number(h);
    }
    function takeString(packed) {
        if (!packed) throw lastError();
        const v = BigInt(packed);
        const ptr = Number(v >> 32n);
        const len = Number(v & 0xffffffffn);
        const text = decodeUtf8(memory.buffer, ptr, len);
        x.temporalz_string_free(ptr, len);
        return text;
    }
    function withCString(str, fn) {
        const bytes = encodeUtf8(str);
        const ptr = Number(x.temporalz_alloc(bytes.length));
        if (!ptr && bytes.length) throw lastError();
        if (bytes.length) new Uint8Array(memory.buffer, ptr, bytes.length).set(bytes);
        try { return fn(ptr, bytes.length); }
        finally { if (bytes.length) x.temporalz_free(ptr, bytes.length); }
    }

    // --- enums (must match wasm.zig codes) ---------------------------------
    const UNIT_CODES = {
        nanosecond: 1, nanoseconds: 1,
        microsecond: 2, microseconds: 2,
        millisecond: 3, milliseconds: 3,
        second: 4, seconds: 4,
        minute: 5, minutes: 5,
        hour: 6, hours: 6,
        day: 7, days: 7,
        week: 8, weeks: 8,
        month: 9, months: 9,
        year: 10, years: 10,
        auto: 11,
    };
    const ROUNDING_MODE_CODES = { ceil: 1, floor: 2, expand: 3, trunc: 4, halfCeil: 5, halfFloor: 6, halfExpand: 7, halfTrunc: 8, halfEven: 9 };

    function toStringOrThrow(v, name) {
        if (typeof v === "symbol") throw new TypeError(`Cannot convert symbol to string for ${name}`);
        return String(v);
    }
    function unitCode(value) {
        if (value === undefined) return 255;
        const s = toStringOrThrow(value, "unit");
        const c = UNIT_CODES[s];
        if (c === undefined) throw new RangeError(`Invalid unit: ${s}`);
        return c;
    }
    function roundingModeCode(value) {
        if (value === undefined) return 255;
        const s = toStringOrThrow(value, "roundingMode");
        const c = ROUNDING_MODE_CODES[s];
        if (c === undefined) throw new RangeError(`Invalid roundingMode: ${s}`);
        return c;
    }
    function roundingIncrementValue(opts) {
        if (!opts || opts.roundingIncrement === undefined) return 0;
        const v = opts.roundingIncrement;
        if (typeof v === "bigint") throw new TypeError("Cannot convert BigInt to number for roundingIncrement");
        const n = Number(v);
        if (!Number.isFinite(n)) throw new RangeError("Invalid roundingIncrement");
        const i = Math.trunc(n);
        if (i < 1 || i > 1e9) throw new RangeError("Invalid roundingIncrement");
        return i;
    }
    function requireOptionsObject(o, name) {
        if (o === undefined) return {};
        if (o === null) throw new TypeError(`${name} options cannot be null`);
        if (typeof o !== "object" && typeof o !== "function") {
            throw new TypeError(`${name} options must be an object`);
        }
        return o;
    }

    // --- BigInt i128 split for the wasm boundary ---------------------------
    function splitI128(value) {
        const v = typeof value === "bigint" ? value : BigInt(value);
        return { hi: v >> 64n, lo: v & 0xffffffffffffffffn };
    }
    function joinI128(hi, lo) {
        return (BigInt(hi) << 64n) | (BigInt(lo) & 0xffffffffffffffffn);
    }

    // --- brand-check helpers -----------------------------------------------
    const HANDLE = Symbol("temporalz.handle");
    function brand(obj, klass, name) {
        if (typeof obj !== "object" || obj === null || !klass.prototype.isPrototypeOf(obj)) {
            throw new TypeError(`this is not a ${name}`);
        }
        const h = obj[HANDLE];
        if (h === undefined) throw new TypeError(`this is not a ${name} (missing brand)`);
        return h;
    }

    function defineMethods(proto, methods) {
        for (const name of Object.keys(methods)) {
            Object.defineProperty(proto, name, {
                value: methods[name],
                writable: true,
                enumerable: false,
                configurable: true,
            });
        }
    }
    function defineGetters(proto, getters) {
        for (const name of Object.keys(getters)) {
            Object.defineProperty(proto, name, {
                get: getters[name],
                enumerable: false,
                configurable: true,
            });
        }
    }

    // =======================================================================
    // Instant
    // =======================================================================
    const NS_LIMIT = 8_640_000_000_000_000_000_000n;
    function Instant(epochNanoseconds) {
        if (!new.target) throw new TypeError("Instant must be called with new");
        if (typeof epochNanoseconds !== "bigint") {
            throw new TypeError("epochNanoseconds must be a BigInt");
        }
        if (epochNanoseconds > NS_LIMIT || epochNanoseconds < -NS_LIMIT) {
            throw new RangeError("epochNanoseconds out of range");
        }
        const { hi, lo } = splitI128(epochNanoseconds);
        const handle = need(x.temporalz_instant_from_epoch_nanoseconds_parts(hi, lo));
        Object.defineProperty(this, HANDLE, { value: handle });
    }
    function instantFromHandle(handle) {
        const obj = Object.create(Instant.prototype);
        Object.defineProperty(obj, HANDLE, { value: handle });
        return obj;
    }
    function isInstant(v) {
        return typeof v === "object" && v !== null && Instant.prototype.isPrototypeOf(v) && v[HANDLE] !== undefined;
    }

    // Static methods
    Object.defineProperty(Instant, "from", {
        value: { from(item) {
            if (isInstant(item)) return new Instant(getInstantEpochNs(item));
            return parseInstantString(coerceToInstantString(item));
        } }.from,
        writable: true, enumerable: false, configurable: true,
    });
    Object.defineProperty(Instant, "fromEpochMilliseconds", {
        value: { fromEpochMilliseconds(epochMilliseconds) {
            if (typeof epochMilliseconds === "bigint") throw new TypeError("epochMilliseconds must not be BigInt");
            const n = Number(epochMilliseconds);
            if (!Number.isFinite(n)) throw new RangeError("epochMilliseconds must be a finite integer");
            if (!Number.isInteger(n)) throw new RangeError("epochMilliseconds must be an integer");
            const MAX = 8.64e15;
            if (n > MAX || n < -MAX) throw new RangeError("epochMilliseconds out of range");
            return instantFromHandle(need(x.temporalz_instant_from_epoch_milliseconds(BigInt(n))));
        } }.fromEpochMilliseconds,
        writable: true, enumerable: false, configurable: true,
    });
    Object.defineProperty(Instant, "fromEpochNanoseconds", {
        value: { fromEpochNanoseconds(epochNanoseconds) {
            if (typeof epochNanoseconds !== "bigint") throw new TypeError("epochNanoseconds must be a BigInt");
            const MAX = 8_640_000_000_000_000_000_000n;
            if (epochNanoseconds > MAX || epochNanoseconds < -MAX) throw new RangeError("epochNanoseconds out of range");
            const { hi, lo } = splitI128(epochNanoseconds);
            return instantFromHandle(need(x.temporalz_instant_from_epoch_nanoseconds_parts(hi, lo)));
        } }.fromEpochNanoseconds,
        writable: true, enumerable: false, configurable: true,
    });
    Object.defineProperty(Instant, "compare", {
        value: { compare(a, b) {
            const ha = toInstantHandle(a);
            const hb = toInstantHandle(b);
            return Number(x.temporalz_instant_compare(ha, hb));
        } }.compare,
        writable: true, enumerable: false, configurable: true,
    });

    function parseInstantString(str) {
        return withCString(str, (ptr, len) => instantFromHandle(need(x.temporalz_instant_from_utf8(ptr, len))));
    }
    // Spec: ToTemporalInstant. If Instant, copy. Else, ToPrimitive(string-hint) then
    // parse as ISO string. bigint/symbol/Temporal.Instant.prototype branding fail → TypeError.
    function coerceToInstantString(value) {
        if (value === undefined || value === null) throw new TypeError("Instant argument is required");
        if (typeof value === "boolean") throw new TypeError("Boolean is not a valid Instant");
        if (typeof value === "number") throw new TypeError("Number is not a valid Instant");
        if (typeof value === "bigint") throw new TypeError("BigInt is not a valid Instant");
        if (typeof value === "symbol") throw new TypeError("Symbol is not a valid Instant");
        if (typeof value === "string") return value;
        // Object case: must not be an Instant.prototype (brand fails) — but ordinary object → ToString → "[object Object]" parsed → RangeError
        if (value === Instant.prototype) throw new TypeError("Instant.prototype is not a valid Instant");
        return String(value);
    }
    function toInstantHandle(value) {
        if (isInstant(value)) return value[HANDLE];
        const str = coerceToInstantString(value);
        return withCString(str, (ptr, len) => need(x.temporalz_instant_from_utf8(ptr, len)));
    }
    function getInstantEpochNs(inst) {
        const h = inst[HANDLE];
        const hi = x.temporalz_instant_epoch_nanoseconds_hi(h);
        const lo = x.temporalz_instant_epoch_nanoseconds_lo(h);
        return joinI128(hi, lo);
    }

    defineGetters(Instant.prototype, {
        epochMilliseconds() {
            const h = brand(this, Instant, "Temporal.Instant");
            return Number(x.temporalz_instant_epoch_milliseconds(h));
        },
        epochNanoseconds() {
            const h = brand(this, Instant, "Temporal.Instant");
            const hi = x.temporalz_instant_epoch_nanoseconds_hi(h);
            const lo = x.temporalz_instant_epoch_nanoseconds_lo(h);
            return joinI128(hi, lo);
        },
    });

    defineMethods(Instant.prototype, {
        add(durationLike) {
            const h = brand(this, Instant, "Temporal.Instant");
            const dh = toDurationHandle(durationLike);
            return instantFromHandle(need(x.temporalz_instant_add(h, dh)));
        },
        subtract(durationLike) {
            const h = brand(this, Instant, "Temporal.Instant");
            const dh = toDurationHandle(durationLike);
            return instantFromHandle(need(x.temporalz_instant_subtract(h, dh)));
        },
        until(other, options) {
            const h = brand(this, Instant, "Temporal.Instant");
            const oh = toInstantHandle(other);
            const o = requireOptionsObject(options, "until");
            return durationFromHandle(need(x.temporalz_instant_until(
                h, oh,
                unitCode(o.largestUnit),
                unitCode(o.smallestUnit),
                roundingModeCode(o.roundingMode),
                roundingIncrementValue(o),
            )));
        },
        since(other, options) {
            const h = brand(this, Instant, "Temporal.Instant");
            const oh = toInstantHandle(other);
            const o = requireOptionsObject(options, "since");
            return durationFromHandle(need(x.temporalz_instant_since(
                h, oh,
                unitCode(o.largestUnit),
                unitCode(o.smallestUnit),
                roundingModeCode(o.roundingMode),
                roundingIncrementValue(o),
            )));
        },
        round(options) {
            const h = brand(this, Instant, "Temporal.Instant");
            let o;
            if (typeof options === "string") o = { smallestUnit: options };
            else if (options === undefined) throw new TypeError("round options required");
            else o = requireOptionsObject(options, "round");
            const su = unitCode(o.smallestUnit);
            if (su === 255) throw new RangeError("smallestUnit is required");
            return instantFromHandle(need(x.temporalz_instant_round(
                h, su, roundingModeCode(o.roundingMode), roundingIncrementValue(o),
            )));
        },
        equals(other) {
            const h = brand(this, Instant, "Temporal.Instant");
            const oh = toInstantHandle(other);
            return x.temporalz_instant_equals(h, oh) === 1;
        },
        toString(options) {
            const h = brand(this, Instant, "Temporal.Instant");
            const o = requireOptionsObject(options, "toString");
            const su = unitCode(o.smallestUnit);
            const rm = roundingModeCode(o.roundingMode);
            let fd = -1;
            if (o.fractionalSecondDigits !== undefined) {
                const v = o.fractionalSecondDigits;
                if (typeof v === "symbol") throw new TypeError("Cannot convert Symbol to fractionalSecondDigits");
                if (typeof v === "bigint") throw new TypeError("Cannot convert BigInt to number for fractionalSecondDigits");
                if (typeof v === "number") {
                    if (!Number.isFinite(v)) throw new RangeError("Invalid fractionalSecondDigits");
                    const i = Math.floor(v);
                    if (i < 0 || i > 9) throw new RangeError("Invalid fractionalSecondDigits");
                    fd = i;
                } else {
                    // ToString path; only "auto" is acceptable
                    const s = String(v);
                    if (s !== "auto") throw new RangeError("Invalid fractionalSecondDigits");
                    fd = -1;
                }
            }
            let tzPtr = 0, tzLen = 0;
            const tz = o.timeZone;
            if (tz !== undefined) {
                if (typeof tz !== "string") {
                    // primitive bool/number/bigint convert to a string but won't be a valid time zone → RangeError
                    // null/symbol/object → TypeError per spec
                    if (tz === null) throw new TypeError("timeZone must be a string");
                    if (typeof tz === "object") throw new TypeError("timeZone must be a string");
                    if (typeof tz === "symbol") throw new TypeError("Cannot convert Symbol to string for timeZone");
                    // boolean/number/bigint → string conversion, then range check happens via Zig parse
                }
                const tzStr = typeof tz === "string" ? tz : String(tz);
                const bytes = encodeUtf8(tzStr);
                tzPtr = Number(x.temporalz_alloc(bytes.length));
                if (!tzPtr && bytes.length) throw lastError();
                if (bytes.length) new Uint8Array(memory.buffer, tzPtr, bytes.length).set(bytes);
                tzLen = bytes.length;
            }
            try {
                return takeString(x.temporalz_instant_to_string_with(h, su, rm, fd, tzPtr, tzLen));
            } finally {
                if (tzLen) x.temporalz_free(tzPtr, tzLen);
            }
        },
        toJSON() {
            const h = brand(this, Instant, "Temporal.Instant");
            return takeString(x.temporalz_instant_to_string(h));
        },
        toLocaleString() {
            const h = brand(this, Instant, "Temporal.Instant");
            return takeString(x.temporalz_instant_to_string(h));
        },
        valueOf() {
            throw new TypeError("Cannot convert Temporal.Instant to a primitive value");
        },
        toZonedDateTimeISO(timeZone) {
            const h = brand(this, Instant, "Temporal.Instant");
            if (typeof timeZone !== "string") throw new TypeError("timeZone must be a string");
            return withCString(timeZone, (ptr, len) => {
                const zh = need(x.temporalz_instant_to_zoned_date_time_iso(h, ptr, len));
                return zonedDateTimeFromHandle(zh);
            });
        },
    });

    Object.defineProperty(Instant.prototype, Symbol.toStringTag, {
        value: "Temporal.Instant", writable: false, enumerable: false, configurable: true,
    });
    Object.defineProperty(Instant, "prototype", { writable: false, enumerable: false, configurable: false });

    // =======================================================================
    // ZonedDateTime (minimal: only what Instant.toZonedDateTimeISO returns)
    // =======================================================================
    function ZonedDateTime() {
        throw new TypeError("Use Temporal.Instant.prototype.toZonedDateTimeISO instead");
    }
    function zonedDateTimeFromHandle(handle) {
        const obj = Object.create(ZonedDateTime.prototype);
        Object.defineProperty(obj, HANDLE, { value: handle });
        return obj;
    }
    defineGetters(ZonedDateTime.prototype, {
        epochNanoseconds() {
            const h = brand(this, ZonedDateTime, "Temporal.ZonedDateTime");
            const hi = x.temporalz_zoned_date_time_epoch_nanoseconds_hi(h);
            const lo = x.temporalz_zoned_date_time_epoch_nanoseconds_lo(h);
            return joinI128(hi, lo);
        },
    });
    Object.defineProperty(ZonedDateTime.prototype, Symbol.toStringTag, {
        value: "Temporal.ZonedDateTime", writable: false, enumerable: false, configurable: true,
    });

    // =======================================================================
    // Duration
    // =======================================================================
    function Duration(years, months, weeks, days, hours, minutes, seconds, ms, us, ns) {
        if (!new.target) throw new TypeError("Duration must be called with new");
        const Y = intArg(years, "years");
        const Mo = intArg(months, "months");
        const W = intArg(weeks, "weeks");
        const D = intArg(days, "days");
        const H = intArg(hours, "hours");
        const Mi = intArg(minutes, "minutes");
        const S = intArg(seconds, "seconds");
        const MS = intArg(ms, "milliseconds");
        const US = numArg(us, "microseconds");
        const NS = numArg(ns, "nanoseconds");
        const handle = need(x.temporalz_duration_init(Y, Mo, W, D, H, Mi, S, MS, US, NS));
        Object.defineProperty(this, HANDLE, { value: handle });
    }
    function intArg(v, name) {
        if (v === undefined) return 0n;
        if (typeof v === "bigint") return v;
        const n = Number(v);
        if (!Number.isFinite(n)) throw new RangeError(`${name} must be finite`);
        if (!Number.isInteger(n)) throw new RangeError(`${name} must be an integer`);
        return BigInt(n);
    }
    function numArg(v, name) {
        if (v === undefined) return 0;
        const n = Number(v);
        if (!Number.isFinite(n)) throw new RangeError(`${name} must be finite`);
        if (!Number.isInteger(n)) throw new RangeError(`${name} must be an integer`);
        return n;
    }
    function durationFromHandle(handle) {
        const obj = Object.create(Duration.prototype);
        Object.defineProperty(obj, HANDLE, { value: handle });
        return obj;
    }
    function isDuration(v) {
        return typeof v === "object" && v !== null && Duration.prototype.isPrototypeOf(v) && v[HANDLE] !== undefined;
    }
    function toDurationHandle(value) {
        if (isDuration(value)) return value[HANDLE];
        if (typeof value === "string") {
            return withCString(value, (ptr, len) => need(x.temporalz_duration_from_utf8(ptr, len)));
        }
        if (value === null || typeof value !== "object") {
            throw new TypeError("expected a Duration, string, or object");
        }
        // Wasm-side parts order (matches mask bits): years, months, weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds
        const wireOrder = ["years","months","weeks","days","hours","minutes","seconds","milliseconds","microseconds","nanoseconds"];
        // Spec: properties are read in alphabetical order.
        const readOrder = ["days","hours","microseconds","milliseconds","minutes","months","nanoseconds","seconds","weeks","years"];
        const vals = [0n,0n,0n,0n,0n,0n,0n,0n,0,0];
        let mask = 0;
        let any = false;
        for (const f of readOrder) {
            const raw = value[f];
            if (raw === undefined) continue;
            any = true;
            const i = wireOrder.indexOf(f);
            mask |= 1 << i;
            vals[i] = (f === "microseconds" || f === "nanoseconds") ? numArg(raw, f) : intArg(raw, f);
        }
        if (!any) throw new TypeError("Duration object must have at least one duration field");
        return need(x.temporalz_duration_from_parts(mask, vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], vals[8], vals[9]));
    }
    Object.defineProperty(Duration, "from", {
        value: function from(value) {
            if (isDuration(value)) return durationFromHandle(need(x.temporalz_duration_init(
                x.temporalz_duration_years(value[HANDLE]),
                x.temporalz_duration_months(value[HANDLE]),
                x.temporalz_duration_weeks(value[HANDLE]),
                x.temporalz_duration_days(value[HANDLE]),
                x.temporalz_duration_hours(value[HANDLE]),
                x.temporalz_duration_minutes(value[HANDLE]),
                x.temporalz_duration_seconds(value[HANDLE]),
                x.temporalz_duration_milliseconds(value[HANDLE]),
                x.temporalz_duration_microseconds(value[HANDLE]),
                x.temporalz_duration_nanoseconds(value[HANDLE]),
            )));
            return durationFromHandle(toDurationHandle(value));
        },
        writable: true, enumerable: false, configurable: true,
    });
    Object.defineProperty(Duration, "compare", {
        value: function compare(a, b, options) {
            const ah = toDurationHandle(a);
            const bh = toDurationHandle(b);
            const relativeTo = options && options.relativeTo;
            if (relativeTo !== undefined && relativeTo !== null) {
                const date = plainDateFromAny(relativeTo);
                return Number(x.temporalz_duration_compare_plain_date(ah, bh, date[HANDLE]));
            }
            return Number(x.temporalz_duration_compare(ah, bh));
        },
        writable: true, enumerable: false, configurable: true,
    });

    defineGetters(Duration.prototype, {
        years()        { return Number(x.temporalz_duration_years(brand(this, Duration, "Temporal.Duration"))); },
        months()       { return Number(x.temporalz_duration_months(brand(this, Duration, "Temporal.Duration"))); },
        weeks()        { return Number(x.temporalz_duration_weeks(brand(this, Duration, "Temporal.Duration"))); },
        days()         { return Number(x.temporalz_duration_days(brand(this, Duration, "Temporal.Duration"))); },
        hours()        { return Number(x.temporalz_duration_hours(brand(this, Duration, "Temporal.Duration"))); },
        minutes()      { return Number(x.temporalz_duration_minutes(brand(this, Duration, "Temporal.Duration"))); },
        seconds()      { return Number(x.temporalz_duration_seconds(brand(this, Duration, "Temporal.Duration"))); },
        milliseconds() { return Number(x.temporalz_duration_milliseconds(brand(this, Duration, "Temporal.Duration"))); },
        microseconds() { return Number(x.temporalz_duration_microseconds(brand(this, Duration, "Temporal.Duration"))); },
        nanoseconds()  { return Number(x.temporalz_duration_nanoseconds(brand(this, Duration, "Temporal.Duration"))); },
        sign()         { return Number(x.temporalz_duration_sign(brand(this, Duration, "Temporal.Duration"))); },
        blank()        { return x.temporalz_duration_blank(brand(this, Duration, "Temporal.Duration")) === 1; },
    });

    defineMethods(Duration.prototype, {
        add(other) {
            const h = brand(this, Duration, "Temporal.Duration");
            return durationFromHandle(need(x.temporalz_duration_add(h, toDurationHandle(other))));
        },
        subtract(other) {
            const h = brand(this, Duration, "Temporal.Duration");
            return durationFromHandle(need(x.temporalz_duration_subtract(h, toDurationHandle(other))));
        },
        abs() {
            const h = brand(this, Duration, "Temporal.Duration");
            return durationFromHandle(need(x.temporalz_duration_abs(h)));
        },
        negated() {
            const h = brand(this, Duration, "Temporal.Duration");
            return durationFromHandle(need(x.temporalz_duration_negated(h)));
        },
        round(options) {
            const h = brand(this, Duration, "Temporal.Duration");
            const o = options ?? {};
            if (o === null || typeof o !== "object") throw new TypeError("round options must be an object");
            const relativeTo = o.relativeTo;
            if (relativeTo !== undefined && relativeTo !== null) {
                const date = plainDateFromAny(relativeTo);
                return durationFromHandle(need(x.temporalz_duration_round_plain_date(
                    h, unitCode(o.smallestUnit), unitCode(o.largestUnit), roundingModeCode(o.roundingMode), roundingIncrementValue(o), date[HANDLE],
                )));
            }
            return durationFromHandle(need(x.temporalz_duration_round(
                h, unitCode(o.smallestUnit), unitCode(o.largestUnit), roundingModeCode(o.roundingMode), roundingIncrementValue(o),
            )));
        },
        total(options) {
            const h = brand(this, Duration, "Temporal.Duration");
            if (!options || typeof options !== "object") throw new TypeError("total options must be an object");
            const unit = unitCode(options.unit);
            if (unit === 255) throw new RangeError("unit is required");
            const relativeTo = options.relativeTo;
            if (relativeTo !== undefined && relativeTo !== null) {
                const date = plainDateFromAny(relativeTo);
                return x.temporalz_duration_total_plain_date(h, unit, date[HANDLE]);
            }
            return x.temporalz_duration_total(h, unit);
        },
        toString() {
            return takeString(x.temporalz_duration_to_string(brand(this, Duration, "Temporal.Duration")));
        },
        toJSON() {
            return takeString(x.temporalz_duration_to_string(brand(this, Duration, "Temporal.Duration")));
        },
        toLocaleString() {
            return takeString(x.temporalz_duration_to_string(brand(this, Duration, "Temporal.Duration")));
        },
        valueOf() {
            throw new TypeError("Cannot convert Temporal.Duration to a primitive value");
        },
    });

    Object.defineProperty(Duration.prototype, Symbol.toStringTag, {
        value: "Temporal.Duration", writable: false, enumerable: false, configurable: true,
    });
    Object.defineProperty(Duration, "prototype", { writable: false, enumerable: false, configurable: false });

    // =======================================================================
    // PlainDate (minimal — used as relativeTo for Duration)
    // =======================================================================
    function PlainDate(year, month, day) {
        if (!new.target) throw new TypeError("PlainDate must be called with new");
        const Y = Number(year), M = Number(month), D = Number(day);
        if (!Number.isInteger(Y) || !Number.isInteger(M) || !Number.isInteger(D)) {
            throw new RangeError("PlainDate fields must be integers");
        }
        const handle = need(x.temporalz_plain_date_init(Y, M, D));
        Object.defineProperty(this, HANDLE, { value: handle });
    }
    function plainDateFromHandle(handle) {
        const obj = Object.create(PlainDate.prototype);
        Object.defineProperty(obj, HANDLE, { value: handle });
        return obj;
    }
    function isPlainDate(v) {
        return typeof v === "object" && v !== null && PlainDate.prototype.isPrototypeOf(v) && v[HANDLE] !== undefined;
    }
    function plainDateFromAny(value) {
        if (isPlainDate(value)) return value;
        if (typeof value === "string") {
            return withCString(value, (ptr, len) => plainDateFromHandle(need(x.temporalz_plain_date_from_utf8(ptr, len))));
        }
        if (value === null || typeof value !== "object") throw new TypeError("Invalid relativeTo");
        const Y = Number(value.year), M = Number(value.month), D = Number(value.day);
        if (!Number.isInteger(Y) || !Number.isInteger(M) || !Number.isInteger(D)) {
            throw new RangeError("Invalid relativeTo fields");
        }
        return plainDateFromHandle(need(x.temporalz_plain_date_init(Y, M, D)));
    }
    Object.defineProperty(PlainDate, "from", {
        value: function from(value) { return plainDateFromAny(value); },
        writable: true, enumerable: false, configurable: true,
    });
    defineMethods(PlainDate.prototype, {
        toString() { return takeString(x.temporalz_plain_date_to_string(brand(this, PlainDate, "Temporal.PlainDate"))); },
    });
    Object.defineProperty(PlainDate.prototype, Symbol.toStringTag, {
        value: "Temporal.PlainDate", writable: false, enumerable: false, configurable: true,
    });

    // =======================================================================
    // Unimplemented stubs
    // =======================================================================
    function notImplemented(name) {
        return function () { throw new Error(`${name} is not implemented`); };
    }

    const TemporalNow = {};
    defineMethods(TemporalNow, {
        instant() {
            // Delegate creation semantics to the Zig-backed Instant constructor path.
            return Instant.fromEpochMilliseconds(Date.now());
        },
        plainDateISO() {
            throw new Error("Temporal.Now.plainDateISO is not implemented");
        },
        plainDateTimeISO() {
            throw new Error("Temporal.Now.plainDateTimeISO is not implemented");
        },
        plainTimeISO() {
            throw new Error("Temporal.Now.plainTimeISO is not implemented");
        },
        timeZoneId() {
            // Keep this deterministic for now; Zig Now.zig currently returns UTC too.
            return "UTC";
        },
        zonedDateTimeISO() {
            const tz = arguments.length === 0 || arguments[0] === undefined ? TemporalNow.timeZoneId() : arguments[0];
            if (tz === null) throw new TypeError("timeZone must be a string");
            if (typeof tz === "symbol") throw new TypeError("Cannot convert Symbol to string for timeZone");
            return TemporalNow.instant().toZonedDateTimeISO(String(tz));
        },
    });
    Object.defineProperty(TemporalNow, Symbol.toStringTag, {
        value: "Temporal.Now", writable: false, enumerable: false, configurable: true,
    });

    const Temporal = {
        Instant,
        Duration,
        PlainDate,
        ZonedDateTime,
        PlainTime: notImplemented("Temporal.PlainTime"),
        PlainDateTime: notImplemented("Temporal.PlainDateTime"),
        PlainYearMonth: notImplemented("Temporal.PlainYearMonth"),
        PlainMonthDay: notImplemented("Temporal.PlainMonthDay"),
        Now: TemporalNow,
    };

    Object.defineProperty(Temporal, Symbol.toStringTag, {
        value: "Temporal", writable: false, enumerable: false, configurable: true,
    });

    // Ensure constructors have non-enumerable descriptors expected by prop-desc tests
    for (const [name, ctor] of Object.entries({ Instant, Duration, PlainDate, ZonedDateTime, Now: TemporalNow })) {
        Object.defineProperty(Temporal, name, {
            value: ctor, writable: true, enumerable: false, configurable: true,
        });
    }

    globalThis.Temporal = Temporal;
})();
