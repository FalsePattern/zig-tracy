const std = @import("std");

const c = @import("c");
const options = @import("tracy-options");

pub inline fn init(parent_allocator: std.mem.Allocator) TracingAllocatorInternal(false, false) {
    return initWithCallstack(false, parent_allocator);
}

pub inline fn initWithCallstack(comptime callstack: bool, parent_allocator: std.mem.Allocator) TracingAllocatorInternal(callstack, false) {
    return .{
        .parent_allocator = parent_allocator,
        .pool_name = {},
    };
}

/// pool_name MUST NOT be deallocated!
pub inline fn initNamed(pool_name: [:0]const u8, parent_allocator: std.mem.Allocator) TracingAllocatorInternal(false, true) {
    return initNamedWithCallstack(false, pool_name, parent_allocator);
}

/// pool_name MUST NOT be deallocated!
pub inline fn initNamedWithCallstack(comptime callstack: bool, pool_name: [:0]const u8, parent_allocator: std.mem.Allocator) TracingAllocatorInternal(callstack, true) {
    return .{
        .parent_allocator = parent_allocator,
        .pool_name = pool_name,
    };
}

fn TracingAllocatorInternal(comptime callstack: bool, comptime named: bool) type {
    if (!options.tracy_enable) {
        return struct {
            parent_allocator: std.mem.Allocator,
            pool_name: if (named) [:0]const u8 else void,

            const Self = @This();

            pub fn allocator(self: *Self) std.mem.Allocator {
                return self.parent_allocator;
            }
        };
    }
    const depth_opt: ?u8 = if (!callstack or options.tracy_no_callstack)
        null
    else if (options.tracy_callstack) |depth| depth else null;
    const Wrapper = if (depth_opt) |depth|
        if (named) struct {
            pub inline fn emitMemoryAlloc(ptr: ?*const anyopaque, size: usize, secure: c_int, name: [*c]const u8) void {
                c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, secure, name);
            }
            pub inline fn emitMemoryFree(ptr: ?*const anyopaque, secure: c_int, name: [*c]const u8) void {
                c.___tracy_emit_memory_free_callstack_named(ptr, depth, secure, name);
            }
        } else struct {
            pub inline fn emitMemoryAlloc(ptr: ?*const anyopaque, size: usize, secure: c_int, _: void) void {
                c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, secure);
            }
            pub inline fn emitMemoryFree(ptr: ?*const anyopaque, secure: c_int, _: void) void {
                c.___tracy_emit_memory_free_callstack(ptr, depth, secure);
            }
        }
    else if (named) struct {
        const emitMemoryAlloc = c.___tracy_emit_memory_alloc_named;
        const emitMemoryFree = c.___tracy_emit_memory_free_named;
    } else struct {
        pub inline fn emitMemoryAlloc(ptr: ?*const anyopaque, size: usize, secure: c_int, _: void) void {
            c.___tracy_emit_memory_alloc(ptr, size, secure);
        }

        pub inline fn emitMemoryFree(ptr: ?*const anyopaque, secure: c_int, _: void) void {
            c.___tracy_emit_memory_free(ptr, secure);
        }
    };
    return struct {
        parent_allocator: std.mem.Allocator,
        pool_name: if (named) [:0]const u8 else void,

        const Self = @This();

        pub fn allocator(self: *Self) std.mem.Allocator {
            return .{
                .ptr = self,
                .vtable = &.{
                    .alloc = alloc,
                    .resize = resize,
                    .remap = remap,
                    .free = free,
                },
            };
        }

        inline fn poolName(self: Self) if (named) [*:0]const u8 else void {
            return if (named) self.pool_name.ptr else {};
        }

        fn alloc(
            ctx: *anyopaque,
            len: usize,
            alignment: std.mem.Alignment,
            ret_addr: usize,
        ) ?[*]u8 {
            const self: *Self = @ptrCast(@alignCast(ctx));
            const result = self.parent_allocator.rawAlloc(len, alignment, ret_addr);

            if (result == null) return null;

            Wrapper.emitMemoryAlloc(result, len, 0, self.poolName());

            return result;
        }

        fn resize(
            ctx: *anyopaque,
            memory: []u8,
            alignment: std.mem.Alignment,
            new_len: usize,
            ret_addr: usize,
        ) bool {
            const self: *Self = @ptrCast(@alignCast(ctx));
            const result = self.parent_allocator.rawResize(memory, alignment, new_len, ret_addr);

            if (!result) return false;

            const name = self.poolName();
            Wrapper.emitMemoryFree(memory.ptr, 0, name);
            Wrapper.emitMemoryAlloc(memory.ptr, new_len, 0, name);

            return result;
        }

        fn remap(
            ctx: *anyopaque,
            memory: []u8,
            alignment: std.mem.Alignment,
            new_len: usize,
            ret_addr: usize,
        ) ?[*]u8 {
            const self: *Self = @ptrCast(@alignCast(ctx));
            const result = self.parent_allocator.rawRemap(memory, alignment, new_len, ret_addr);

            if (result == null) return null;

            Wrapper.emitMemoryFree(memory.ptr, 0, self.poolName());
            Wrapper.emitMemoryAlloc(memory.ptr, new_len, 0, self.poolName());

            return result;
        }

        fn free(
            ctx: *anyopaque,
            memory: []u8,
            alignment: std.mem.Alignment,
            ret_addr: usize,
        ) void {
            const self: *Self = @ptrCast(@alignCast(ctx));

            self.parent_allocator.rawFree(memory, alignment, ret_addr);

            Wrapper.emitMemoryFree(memory.ptr, 0, self.poolName());
        }
    };
}
