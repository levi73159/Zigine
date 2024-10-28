// this graphics context of the current platform, will be changed to suport more then opengl but rn it only supports opengl
pub const GraphicsContext = switch (@import("Renderer.zig").api) {
    .OpenGL => @import("OpenGL/Context.zig"),
    .None => void,
    else => @compileError("Unsupported graphics api"),
};
