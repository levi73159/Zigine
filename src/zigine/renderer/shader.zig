const api = @import("renderer.zig").api;

pub const Shader = switch (api) {
    .None => struct {},
    .OpenGL => @import("OpenGL/Shader.zig"),
    else => @compileError("selected API is not supported"),
};
