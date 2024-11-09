const std = @import("std");
const log = @import("../../root.zig").core_log;
const api = @import("renderer.zig").api;

pub const ShaderDataType = enum {
    const Self = @This();
    // zig fmt: off
    none,
    float, float2, float3, float4,
    mat3, mat4,
    int, int2, int3, int4,
    bool,
    // zig fmt: on

    pub fn size(self: Self) u32 {
        return switch (self) {
            .none => err: {
                // if we are not in debug mode
                // - we want to crash and cause a panic
                // otherwise we just want to print an err and hope its ok
                if (@import("builtin").mode == .Debug) {
                    std.debug.panic("Unknown ShaderDataType", .{});
                }

                log.err("Unknow ShaderDataType", .{});
                break :err 0;
            },
            .float => @sizeOf(f32),
            .float2 => @sizeOf(f32) * 2,
            .float3 => @sizeOf(f32) * 3,
            .float4 => @sizeOf(f32) * 4,
            .mat3 => @sizeOf(f32) * 3 * 3,
            .mat4 => @sizeOf(f32) * 4 * 4,
            .int => @sizeOf(i32),
            .int2 => @sizeOf(i32) * 2,
            .int3 => @sizeOf(i32) * 3,
            .int4 => @sizeOf(i32) * 4,
            .bool => @sizeOf(bool),
        };
    }

    pub fn count(self: Self) u32 {
        return switch (self) {
            .float2, .int2 => 2,
            .float3, .int3 => 3,
            .float4, .int4 => 4,
            .mat3 => 3 * 3,
            .mat4 => 4 * 4,
            else => 1,
        };
    }
};

pub const Shader = switch (api) {
    .None => struct {},
    .OpenGL => @import("OpenGL/Shader.zig"),
    else => @compileError("selected API is not supported"),
};
