const std = @import("std");

const buffers = switch (@import("Renderer.zig").api) {
    .OpenGL => @import("OpenGL/buffer.zig"),
    .None => void,
    else => @compileError("Unsupported graphics api"),
};

pub const VertexBuffer = buffers.VertexBuffer;
pub const IndexBuffer = buffers.IndexBuffer;
