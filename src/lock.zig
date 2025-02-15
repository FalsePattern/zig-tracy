const std = @import("std");

const c = @import("c");
pub const TracyLockableContextData = c.__tracy_lockable_context_data;
const options = @import("tracy-options");

const zone = @import("zone.zig");
const TracySourceLocationData = zone.TracySourceLocationData;
const ZoneOptions = zone.ZoneOptions;
const createSourceLocation = zone.createSourceLocation;

pub inline fn announceLockable(comptime src: std.builtin.SourceLocation, comptime opts: ZoneOptions) !*LockableContext {
    if (!options.tracy_enable) return undefined;
    return try announceLockableRaw(createSourceLocation(src, opts));
}

/// src_loc MUST NOT be deallocated
pub inline fn announceLockableRaw(src_loc: *const TracySourceLocationData) !*LockableContext {
    if (!options.tracy_enable) return undefined;
    const raw = c.___tracy_announce_lockable_ctx(src_loc) orelse return error.LockInitFailed;
    return @ptrCast(raw);
}

pub const LockableContext = if (options.tracy_enable) opaque {
    pub inline fn deinit(lockable: *LockableContext) void {
        c.___tracy_terminate_lockable_ctx(@ptrCast(lockable));
    }
    pub inline fn beforeLock(lockable: *LockableContext) void {
        _ = c.___tracy_before_lock_lockable_ctx(@ptrCast(lockable));
    }
    pub inline fn afterLock(lockable: *LockableContext) void {
        c.___tracy_after_lock_lockable_ctx(@ptrCast(lockable));
    }
    pub inline fn afterUnlock(lockable: *LockableContext) void {
        c.___tracy_after_unlock_lockable_ctx(@ptrCast(lockable));
    }
    pub inline fn afterTryLock(lockable: *LockableContext, acquired: bool) void {
        c.___tracy_after_try_lock_lockable_ctx(@ptrCast(lockable), @intFromBool(acquired));
    }
    pub inline fn mark(lockable: *LockableContext, comptime src: std.builtin.SourceLocation, comptime opts: ZoneOptions) void {
        markRaw(lockable, createSourceLocation(src, opts));
    }
    /// src_loc MUST NOT be deallocated
    pub inline fn markRaw(lockable: *LockableContext, src_loc: *const TracySourceLocationData) void {
        c.___tracy_mark_lockable_ctx(@ptrCast(lockable), src_loc);
    }
    /// name MUST NOT be deallocated
    pub inline fn customName(lockable: *LockableContext, name: [:0]const u8) void {
        c.___tracy_custom_name_lockable_ctx(@ptrCast(lockable), name.ptr, name.len);
    }
} else opaque {
    pub inline fn deinit(_: *LockableContext) void {}
    pub inline fn beforeLock(_: *LockableContext) void {}
    pub inline fn afterLock(_: *LockableContext) void {}
    pub inline fn afterUnlock(_: *LockableContext) void {}
    pub inline fn afterTryLock(_: *LockableContext, _: bool) void {}
    pub inline fn mark(_: *LockableContext, comptime _: std.builtin.SourceLocation, comptime _: ZoneOptions) void {}
    pub inline fn markRaw(_: *LockableContext, _: *const TracySourceLocationData) void {}
    pub inline fn customName(_: *LockableContext, _: [:0]const u8) void {}
};

pub fn WrappedLock(comptime T: type) type {
    return struct {
        wrapped_lock: T,
        context: *LockableContext,

        const Self = @This();

        pub fn init(wrapped_lock: T, comptime src: std.builtin.SourceLocation, comptime opts: ZoneOptions) !Self {
            return .{
                .wrapped_lock = wrapped_lock,
                .context = try announceLockable(src, opts),
            };
        }

        pub fn deinit(self: *Self) void {
            self.context.deinit();
        }

        pub inline fn tryLock(self: *Self) bool {
            const result = self.wrapped_lock.tryLock();
            self.context.afterTryLock(result);
            return result;
        }

        pub inline fn lock(self: *Self) void {
            self.context.beforeLock();
            self.wrapped_lock.lock();
            self.context.afterLock();
        }

        pub inline fn unlock(self: *Self) void {
            self.wrapped_lock.unlock();
            self.context.afterUnlock();
        }
    };
}