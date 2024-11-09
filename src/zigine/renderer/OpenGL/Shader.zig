const std = @import("std");
const gl = @import("gl");
const za = @import("zalgebra");
const ShaderDataType = @import("../shader.zig").ShaderDataType;
const Ref = @import("../../ptr.zig").Ref;

const log = std.log.scoped(.OpenGL);

const Self = @This();

renderer_id: u32 = 0,

pub const Error = error{
    CompileError,
    LinkError,
    NoMemory,
};

pub const UnifromType = union(ShaderDataType) {
    none: void,
    float: f32,
    float2: [2]f32, // or should it be za.Vec2
    float3: [3]f32,
    float4: [4]f32,
    mat3: [3][3]f32,
    mat4: [4][4]f32,
    int: i32,
    int2: [2]i32,
    int3: [3]i32,
    int4: [4]i32,
    bool: bool,

    fn set(self: UnifromType, location: i32) void {
        if (location == -1) return;
        switch (self) {
            .none => return,
            .float => |f| gl.Uniform1f(location, f),
            .float2 => |f| gl.Uniform2f(location, f[0], f[1]),
            .float3 => |f| gl.Uniform3f(location, f[0], f[1], f[2]),
            .float4 => |f| gl.Uniform4f(location, f[0], f[1], f[2], f[3]),
            .int => |i| gl.Uniform1i(location, i),
            .int2 => |i| gl.Uniform2i(location, i[0], i[1]),
            .int3 => |i| gl.Uniform3i(location, i[0], i[1], i[2]),
            .int4 => |i| gl.Uniform4i(location, i[0], i[1], i[2], i[3]),
            .bool => |b| gl.Uniform1i(location, @intFromBool(b)),
            .mat3 => |m| gl.UniformMatrix3fv(location, 1, gl.FALSE, &m[0][0]),
            .mat4 => |m| gl.UniformMatrix4fv(location, 1, gl.FALSE, &m[0][0]),
        }
    }
};

fn printInfoLog(allocator: std.mem.Allocator, comptime format: []const u8, shader_id: u32) void {
    const max_length: i32 = blk: {
        var max_length: i32 = 0;
        gl.GetShaderiv(shader_id, gl.INFO_LOG_LENGTH, &max_length);
        break :blk max_length;
    };

    var message = allocator.alloc(u8, @intCast(max_length)) catch unreachable;
    defer allocator.free(message);

    var len: i32 = 0;
    gl.GetShaderInfoLog(shader_id, max_length, &len, message.ptr);
    log.err(format, .{message[0..@intCast(len)]});
}

pub fn create(allocator: std.mem.Allocator, shaderSrc: []const u8, fragmentSrc: []const u8) Error!Ref(Self) {
    const ref = Ref(Self).init(allocator, Self{}) catch return error.NoMemory;
    const self = ref.value;

    const vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
    const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);

    gl.ShaderSource(vertex_shader, 1, @ptrCast(&shaderSrc), null);
    gl.ShaderSource(fragment_shader, 1, @ptrCast(&fragmentSrc), null);

    var is_compiled: i32 = 0;

    // complie the vertex shader
    gl.CompileShader(vertex_shader);
    errdefer gl.DeleteShader(vertex_shader);

    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &is_compiled);
    if (is_compiled == gl.FALSE) {
        printInfoLog(allocator, "Error compiling vertex shader: {s}", vertex_shader);

        return error.CompileError;
    }

    // complie the fragment shader
    gl.CompileShader(fragment_shader);
    errdefer gl.DeleteShader(fragment_shader);

    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &is_compiled);
    if (is_compiled == gl.FALSE) {
        printInfoLog(allocator, "Error compiling fragment shader: {s}", fragment_shader);

        return error.CompileError;
    }

    // create the program and get the renderer id
    self.renderer_id = gl.CreateProgram();
    errdefer gl.DeleteProgram(self.renderer_id);

    gl.AttachShader(self.renderer_id, vertex_shader);
    gl.AttachShader(self.renderer_id, fragment_shader);
    gl.LinkProgram(self.renderer_id);

    const is_linked: i32 = blk: {
        var is_linked: i32 = 0;
        gl.GetProgramiv(self.renderer_id, gl.LINK_STATUS, &is_linked);
        break :blk is_linked;
    };

    if (is_linked == gl.FALSE) {
        var max_length: i32 = blk: {
            var max_length: i32 = 0;
            gl.GetProgramiv(self.renderer_id, gl.INFO_LOG_LENGTH, &max_length);
            break :blk max_length;
        };

        var error_message = allocator.alloc(u8, @intCast(max_length)) catch unreachable;
        gl.GetProgramInfoLog(self.renderer_id, max_length, &max_length, error_message.ptr);
        log.err("Error linking program: {s}", .{error_message[0..@intCast(max_length)]});

        return error.LinkError;
    }

    gl.DetachShader(self.renderer_id, vertex_shader);
    gl.DetachShader(self.renderer_id, fragment_shader);

    return ref;
}

pub fn deinit(self: Self) void {
    gl.DeleteProgram(self.renderer_id);
}

pub fn uploadUnifrom(self: Self, name: [:0]const u8, value: UnifromType) void {
    const location = gl.GetUniformLocation(self.renderer_id, name.ptr);
    if (location == -1) {
        log.warn("Unifrom doesn't exist: {s}", .{name});
        return;
    }
    value.set(location);
}

pub fn bind(self: Self) void {
    gl.UseProgram(self.renderer_id);
}

pub fn unbind() void {
    gl.UseProgram(0);
}
