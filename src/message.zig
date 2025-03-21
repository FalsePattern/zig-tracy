const std = @import("std");

const c = @import("c");
const options = @import("tracy-options");

pub inline fn message(comptime msg: [:0]const u8) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;
    c.___tracy_emit_messageL(msg, depth);
}

/// copies `msg` internally
pub inline fn messageAlloc(msg: [:0]const u8) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;
    c.___tracy_emit_message(msg, msg.len, depth);
}

pub inline fn messageColor(comptime msg: [:0]const u8, color: u32) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;
    c.___tracy_emit_messageLC(msg, color, depth);
}

/// copies `msg` internally
pub inline fn messageColorAlloc(msg: [:0]const u8, color: u32) void {
    if (!options.tracy_enable) return;
    const depth = options.tracy_callstack orelse 0;
    c.___tracy_emit_messageC(msg, msg.len, color, depth);
}

const tracy_message_buffer_size = if (options.tracy_enable) 64 * 1024 else 0;
threadlocal var tracy_message_buffer: [tracy_message_buffer_size]u8 = undefined;

pub inline fn print(comptime fmt: []const u8, args: anytype) void {
    if (!options.tracy_enable) return;

    var stream = std.io.fixedBufferStream(&tracy_message_buffer);
    stream.writer().print(fmt, args) catch {};

    const written = stream.getWritten();
    messageAlloc(written);
}

pub inline fn printColor(comptime fmt: []const u8, args: anytype, color: u32) void {
    if (!options.tracy_enable) return;

    var stream = std.io.fixedBufferStream(&tracy_message_buffer);
    stream.writer().print(fmt, args) catch {};

    const written = stream.getWritten();
    messageColorAlloc(written, color);
}

pub inline fn printAppInfo(comptime fmt: []const u8, args: anytype) void {
    if (!options.tracy_enable) return;

    var stream = std.io.fixedBufferStream(&tracy_message_buffer);
    stream.reset();
    stream.writer().print(fmt, args) catch {};

    const written = stream.getWritten();
    c.___tracy_emit_message_appinfo(written.ptr, written.len);
}
