const api = @import("Renderer.zig").api;

pub const VertexArray = switch (api) {
    .None => struct {},
    .OpenGL => @import("OpenGL/VertexArray.zig"),

    else => @compileError("selected API is not supported"),
};
