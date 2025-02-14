const c = @import("c");
const options = @import("tracy-options");

pub inline fn allocSrcLoc(line: u32, source: [:0]const u8, function: [:0]const u8, oName: ?[:0]const u8, color: u32) u64 {
    return if (oName) |name|
        c.___tracy_alloc_srcloc_name(line, source, source.len, function, function.len, name, name.len, color)
    else
        c.___tracy_alloc_srcloc(line, source, source.len, function, function.len, color);
}

pub const GPU = struct {
    pub const ContextType = enum(u8) {
        Invalid,
        OpenGl,
        Vulkan,
        OpenCL,
        Direct3D12,
        Direct3D11,
        Metal,
        Custom,
    };

    pub const ContextFlags = enum(u8) {
        ContextCalibration = 1 << 0,

        pub fn toInt(flags: []const ContextFlags) u8 {
            var result: u8 = 0;
            for (flags) |flag| {
                result |= @intFromEnum(flag);
            }
            return result;
        }
    };

    pub inline fn beginZone(src_loc: u64, query_id: u16, context: u8) void {
        if (!options.tracy_enable) return;
        if (!options.tracy_no_callstack) {
            if (options.tracy_callstack) |depth| {
                return c.___tracy_emit_gpu_zone_begin_alloc_callstack(c.struct____tracy_gpu_zone_begin_callstack_data{
                    .srcloc = src_loc,
                    .depth = depth,
                    .queryId = query_id,
                    .context = context,
                });
            }
        }

        return c.___tracy_emit_gpu_zone_begin_alloc(c.struct____tracy_gpu_zone_begin_data{
            .srcloc = src_loc,
            .queryId = query_id,
            .context = context,
        });
    }

    pub inline fn endZone(query_id: u16, context: u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_gpu_zone_end(c.struct____tracy_gpu_zone_end_data{
            .queryId = query_id,
            .context = context,
        });
    }

    pub inline fn time(gpu_time: i64, query_id: u16, context: u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_gpu_time(c.struct____tracy_gpu_time_data{
            .gpuTime = gpu_time,
            .queryId = query_id,
            .context = context,
        });
    }

    pub inline fn newContext(gpu_time: i64, period: f32, context: u8, flags: []const ContextFlags, @"type": ContextType) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_gpu_new_context(c.struct____tracy_gpu_new_context_data{
            .gpuTime = gpu_time,
            .period = period,
            .context = context,
            .flags = ContextFlags.toInt(flags),
            .type = @intFromEnum(@"type"),
        });
    }

    pub inline fn calibration(gpu_time: i64, cpu_delta: i64, context: u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_gpu_calibration(c.struct____tracy_gpu_calibration_data{
            .gpuTime = gpu_time,
            .cpuDelta = cpu_delta,
            .context = context,
        });
    }

    pub inline fn timeSync(gpu_time: i64, context: u8) void {
        if (!options.tracy_enable) return;
        c.___tracy_emit_gpu_time_sync(c.struct____tracy_gpu_time_sync_data{
            .gpuTime = gpu_time,
            .context = context,
        });
    }
};
