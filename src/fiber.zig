const c = @import("c");
const options = @import("tracy-options");

/// `fiber` MUST NOT be deallocated!
pub inline fn fiberEnter(fiber: [:0]const u8) void {
    if (!options.tracy_enable or !options.tracy_fibers) return;

    c.___tracy_fiber_enter(fiber);
}

pub inline fn fiberLeave() void {
    if (!options.tracy_enable or !options.tracy_fibers) return;

    c.___tracy_fiber_leave();
}