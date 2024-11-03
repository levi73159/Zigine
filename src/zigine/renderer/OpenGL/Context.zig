const gl = @import("gl");
const glfw = @import("glfw");

pub const NativeWindowHandle = glfw.Window; // so we can access it
var opengl_procs: gl.ProcTable = undefined;

const log = @import("std").log.scoped(.OpenGL);

const Self = @This();
window_handle: *glfw.Window,

pub fn new(window_handle: *glfw.Window) Self {
    return Self{ .window_handle = window_handle };
}

pub fn init(self: Self) !void {
    glfw.makeContextCurrent(self.window_handle);

    if (!opengl_procs.init(glfw.getProcAddress)) return error.OpenGLInit;
    gl.makeProcTableCurrent(&opengl_procs);

    log.info("OpenGL info:", .{});
    log.info("    OpenGL vendor: {?s}", .{gl.GetString(gl.VENDOR)});
    log.info("    OpenGL renderer: {?s}", .{gl.GetString(gl.RENDERER)});
    log.info("    OpenGL version: {?s}", .{gl.GetString(gl.VERSION)});
}

// not really needed but might be useful
pub fn deinit() void {
    glfw.makeContextCurrent(null);
    gl.makeProcTableCurrent(null);
}

pub fn swapBuffers(self: Self) void {
    self.window_handle.swapBuffers();
}
