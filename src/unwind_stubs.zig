//! Provides unwind symbols because apparently Rust still might include these when using panic=abort.
//!
//! See:
//! - https://github.com/rust-lang/rust/issues/47493
//! - https://code.videolan.org/videolan/vlc/-/merge_requests/2878

export fn _Unwind_Backtrace() void {}
export fn _Unwind_DeleteException() void {}
export fn _Unwind_GetDataRelBase() void {}
export fn _Unwind_GetIP() void {}
export fn _Unwind_GetIPInfo() void {}
export fn _Unwind_GetLanguageSpecificData() void {}
export fn _Unwind_GetRegionStart() void {}
export fn _Unwind_GetTextRelBase() void {}
export fn _Unwind_RaiseException() void {}
export fn _Unwind_Resume() void {}
export fn _Unwind_SetGR() void {}
export fn _Unwind_SetIP() void {}
// These appear when building for riscv64
export fn _Unwind_FindEnclosingFunction() void {}
export fn _Unwind_GetCFA() void {}
// These appear when building for arm
export fn _Unwind_VRS_Get() void {}
export fn _Unwind_VRS_Set() void {}
export fn __gnu_unwind_frame() void {}
// This appears when building for s390x
export fn _Unwind_GetGR() void {}
// This appears when building for x86_64-windows
export fn _GCC_specific_handler() void {}
