const std = @import("std");

const buffers = switch (@import("renderer.zig").api) {
    .OpenGL => @import("OpenGL/buffer.zig"),
    .None => struct {},
    else => @compileError("Unsupported graphics api"),
};

pub usingnamespace buffers;
