const c = @import("c");
const options = @import("tracy-options");

/// name MUST NOT be deallocated!
pub inline fn setThreadName(name: [:0]const u8) void {
    if (!options.tracy_enable) return;
    c.___tracy_set_thread_name(name);
}

pub inline fn startupProfiler() void {
    if (!options.tracy_enable) return;
    if (!options.tracy_manual_lifetime) return;
    c.___tracy_startup_profiler();
}

pub inline fn shutdownProfiler() void {
    if (!options.tracy_enable) return;
    if (!options.tracy_manual_lifetime) return;
    c.___tracy_shutdown_profiler();
}

pub inline fn profilerStarted() bool {
    if (!options.tracy_enable) return false;
    if (!options.tracy_manual_lifetime) return true;
    return c.___tracy_profiler_started() != 0;
}

pub inline fn isConnected() bool {
    if (!options.tracy_enable) return false;
    return c.___tracy_connected() > 0;
}
