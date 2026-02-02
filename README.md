# Temporalz

[![CI](https://github.com/nurulhudaapon/temporalz/actions/workflows/ci.yml/badge.svg)](https://github.com/nurulhudaapon/temporalz/actions/workflows/ci.yml)

A Zig library for working with temporal types based on the [Temporal Standard](https://tc39.es/proposal-temporal/).

Temporalz provides Zig bindings to the Rust-based [temporal_rs](https://github.com/boa-dev/temporal) library for handling dates, times, and durations with proper timezone support.


## Installation

#### Prerequisites

- Zig 0.15.2
- Rust toolchain (only required if [prebuilt staticlibs](#prebuilt) are not available for your platform)

#### Add as a Dependency

```bash
zig fetch --save https://github.com/nurulhudaapon/temporalz/archive/main.tar.gz
```

#### Use in build.zig

Add temporalz to your executable in `build.zig`:

```zig
const temporalz = b.dependency("temporalz", .{
    .target = target,
    .optimize = optimize,
});

const exe = b.addExecutable(.{...});

exe.root_module.addImport("temporalz", temporalz.module("temporalz"));
```


## Checklist ([Test262](https://github.com/tc39/test262/tree/main/test/built-ins/Temporal))

- [x] Instant
- [x] Duration
- [x] PlainDate
- [x] PlainTime
- [x] PlainDateTime
- [x] PlainYearMonth
- [x] PlainMonthDay
- [x] ZonedDateTime

## Prebuilt

Prebuilt libraries are included for the following platforms:

- `aarch64-macos`
- `x86_64-macos`
- `aarch64-linux-gnu`
- `x86_64-linux-gnu`
- `x86_64-windows-gnu`
- `aarch64-windows-gnu`

For other platforms, the library will build from source; you need the Rust toolchain installed.

## Development

#### Clone the Repository

```bash
git clone https://github.com/nurulhudaapon/temporalz.git
cd temporalz
```

#### Build and Run

```bash
zig build run
```

#### Run Tests

```bash
zig build test
```

## License

MIT

