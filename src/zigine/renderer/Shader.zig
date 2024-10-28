const std = @import("std");
const gl = @import("gl");

const log = @import("../../root.zig").core_log;

const Self = @This();

renderer_id: u32 = 0,

const ShaderError = error{
    CompileError,
    LinkError,
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

pub fn init(allocator: std.mem.Allocator, shaderSrc: []const u8, fragmentSrc: []const u8) ShaderError!Self {
    var self = Self{};

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

    return self;
}

pub fn deinit(self: Self) void {
    gl.DeleteProgram(self.renderer_id);
}

pub fn bind(self: Self) void {
    gl.UseProgram(self.renderer_id);
}

pub fn unbind() void {
    gl.UseProgram(0);
}
