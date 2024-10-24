const std = @import("std");
const glfw = @import("glfw");
const glfw_callbacks = @import("glfw_callbacks.zig");
const builtin = @import("builtin");
const Event = @import("event.zig").Event;
const log = @import("../root.zig").core_log;
const gl = @import("gl");
const imgui = @import("imgui");

const Self = @This();
var glfw_init: bool = false;

var opengl_procs: gl.ProcTable = undefined;

pub const Props = struct {
    title: [:0]const u8,
    width: u32,
    height: u32,
};

pub const EventCallbackFn = @import("func.zig").Func(*Event);
pub const Data = struct {
    title: [:0]const u8,
    width: u32,
    height: u32,
    vsync: bool = false,
    event_callback: ?EventCallbackFn = null,

    fn fromProps(props: Props) Data {
        return Data{ .title = props.title, .width = props.width, .height = props.height };
    }
};

// pub const current_window: ?*glfw.Window = null;

/// the main context for the window, which this class is built on, right now this is the glfw window
native: *glfw.Window,
data: Data,

// allocate a new Window class on heap, caller owns ptr
pub fn init(allocator: std.mem.Allocator, props: Props) !*Self {
    log.info("Creating window {s}, ({}, {})", .{ props.title, props.width, props.height });

    if (!glfw_init) {
        try glfw.init();
        _ = glfw.setErrorCallback(glfw_callbacks.glfwErrorCallback);
        glfw_init = true;
    }

    glfw.windowHintTyped(.context_version_major, gl.info.version_major);
    glfw.windowHintTyped(.context_version_minor, gl.info.version_minor);
    glfw.windowHintTyped(.opengl_profile, if (gl.info.profile == .core) .opengl_core_profile else .opengl_compat_profile);

    const window = try glfw.Window.create(@intCast(props.width), @intCast(props.height), props.title, null);
    glfw.makeContextCurrent(window);

    // current_window = window;

    if (!opengl_procs.init(glfw.getProcAddress)) return error.OpenGLInit;

    gl.makeProcTableCurrent(&opengl_procs);

    const ptr = allocator.create(Self) catch unreachable;
    ptr.* = Self{ .data = Data.fromProps(props), .native = window };
    window.setUserPointer(&ptr.data);
    glfw_callbacks.setCallbacks(window);

    log.info("Opengl version: {?s}\n\n", .{gl.GetString(gl.VERSION)});

    imgui.init(allocator);
    imgui.backend.initWithGlSlVersion(window, "#version 410");

    return ptr;
}

pub inline fn getSize(self: Self) [2]i32 {
    return self.native.getSize();
}

pub inline fn getFrameBufferSize(self: Self) [2]i32 {
    return self.native.getFramebufferSize();
}

pub fn onUpdate(self: Self) void {
    glfw.pollEvents();
    self.native.swapBuffers();
}

pub fn shutdown(self: Self) void {
    imgui.backend.deinit();
    imgui.deinit();
    self.native.destroy();
}

pub fn setVsync(self: *Self, enable: bool) void {
    if (enable) {
        glfw.swapInterval(1);
    } else {
        glfw.swapInterval(0);
    }

    self.data.vsync = enable;
}
