const std = @import("std");

const c = @import("c");
pub const TracySourceLocationData = c.___tracy_source_location_data;
const options = @import("tracy-options");

pub inline fn createSourceLocation(comptime src: std.builtin.SourceLocation, comptime opts: ZoneOptions) *const TracySourceLocationData {
    const static = struct {
        var src_loc = TracySourceLocationData{
            .name = if (opts.name) |name| name.ptr else null,
            .function = src.fn_name.ptr,
            .file = src.file,
            .line = src.line,
            .color = opts.color orelse 0,
        };
    };
    return &static.src_loc;
}

pub const ZoneOptions = struct {
    active: bool = true,
    name: ?[]const u8 = null,
    color: ?u32 = null,
};

pub const ZoneContext = if (options.tracy_enable) extern struct {
    ctx: c.___tracy_c_zone_context,

    pub inline fn deinit(zone: *const ZoneContext) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_end(zone.ctx);
    }

    pub inline fn name(zone: *const ZoneContext, zone_name: []const u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_name(zone.ctx, zone_name.ptr, zone_name.len);
    }

    pub inline fn text(zone: *const ZoneContext, zone_text: []const u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_text(zone.ctx, zone_text.ptr, zone_text.len);
    }

    pub inline fn color(zone: *const ZoneContext, zone_color: u32) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_color(zone.ctx, zone_color);
    }

    pub inline fn value(zone: *const ZoneContext, zone_value: u64) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_zone_value(zone.ctx, zone_value);
    }
} else struct {
    pub inline fn deinit(_: *const ZoneContext) void {}
    pub inline fn name(_: *const ZoneContext, _: []const u8) void {}
    pub inline fn text(_: *const ZoneContext, _: []const u8) void {}
    pub inline fn color(_: *const ZoneContext, _: u32) void {}
    pub inline fn value(_: *const ZoneContext, _: u64) void {}
};

pub inline fn initZone(comptime src: std.builtin.SourceLocation, comptime opts: ZoneOptions) ZoneContext {
    if (!options.tracy_enable) return .{};

    return initZoneRaw(createSourceLocation(src, opts), opts.active);
}

/// src_loc MUST NOT be deallocated!
pub inline fn initZoneRaw(src_loc: *const TracySourceLocationData, b_active: bool) ZoneContext {
    if (!options.tracy_enable) return .{};
    const active: c_int = @intFromBool(b_active);

    if (!options.tracy_no_callstack) {
        if (options.tracy_callstack) |depth| {
            return .{
                .ctx = c.___tracy_emit_zone_begin_callstack(src_loc, depth, active),
            };
        }
    }

    return .{
        .ctx = c.___tracy_emit_zone_begin(src_loc, active),
    };
}
