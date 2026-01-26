# Temporalz

A Zig library for working with temporal types based on the [Temporal Standard](https://tc39.es/proposal-temporal/).

Temporalz provides Zig bindings to the Rust-based [temporal_rs](https://github.com/boa-dev/temporal) library for handling dates, times, and durations with proper timezone support.

## Features

- [x] Instant - Exact moment in time
- [x] Duration - Length of time
- [ ] PlainDate - Date without time or timezone
- [ ] PlainTime - Time without date or timezone
- [ ] PlainDateTime - Date and time without timezone
- [ ] PlainYearMonth - Year and month
- [ ] PlainMonthDay - Month and day
- [ ] ZonedDateTime - Date, time, and timezone

## Installation

### Prerequisites

- Zig 0.15.2 or later
- Rust toolchain (only required if prebuilt binaries are not available for your platform)

### Add as a Dependency

```bash
zig fetch --save=temporalz https://github.com/nurulhudaapon/temporalz/archive/refs/tags/v0.1.2.tar.gz
```

### Use in build.zig

Add temporalz to your executable in `build.zig`:

```zig
const temporalz_dep = b.dependency("temporalz", .{ .target = target, .optimize = optimize });

const exe = b.addExecutable(.{
    .name = "my_app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "temporalz", .module = temporalz_dep.module("temporalz") },
        },
    }),
});
```

## Supported Platforms

Prebuilt binaries are available for:

- `aarch64-macos`
- `x86_64-macos`
- `aarch64-linux-gnu`
- `x86_64-linux-gnu`
- `x86_64-windows-gnu`
- `aarch64-windows-gnu`

For unsupported platforms, the library will automatically build from source if the Rust toolchain is installed.

## Development

### Clone the Repository

```bash
git clone https://github.com/nurulhudaapon/temporalz.git
cd temporalz
```

### Build and Run

```bash
zig build
zig build run
```

### Run Tests

```bash
zig build test
```

## License

MIT

