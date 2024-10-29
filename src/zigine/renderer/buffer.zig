const std = @import("std");

const buffers = switch (@import("Renderer.zig").api) {
    .OpenGL => @import("OpenGL/buffer.zig"),
    .None => struct {},
    else => @compileError("Unsupported graphics api"),
};

pub usingnamespace buffers;
