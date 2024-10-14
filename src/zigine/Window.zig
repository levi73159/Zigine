const std = @import("std");
const glfw = @import("glfw.zig");
const glfw_callbacks = @import("glfw_callbacks.zig");
const builtin = @import("builtin");
const Event = @import("event.zig").Event;
const log = @import("../root.zig").core_log;

const Self = @This();
var glfw_init: bool = false;

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

window: *glfw.GLFWwindow,
data: Data,

// allocate a new Window class on heap, caller owns ptr
pub fn init(allocator: std.mem.Allocator, props: Props) !*Self {
    log.info("Creating window {s}, ({}, {})", .{ props.title, props.width, props.height });
    if (!glfw_init) {
        const success = glfw.glfwInit();
        std.debug.assert(success == 1);

        _ = glfw.glfwSetErrorCallback(glfw_callbacks.glfwErrorCallback);

        glfw_init = true;
    }
    const window = glfw.glfwCreateWindow(@intCast(props.width), @intCast(props.height), props.title, null, null);
    if (window == null) {
        return error.WindowCreateFailed;
    }
    glfw.glfwMakeContextCurrent(window);

    const ptr = try allocator.create(Self);
    ptr.* = Self{ .data = Data.fromProps(props), .window = window.? };
    glfw.glfwSetWindowUserPointer(window, &ptr.data);
    glfw_callbacks.setCallbacks(window);

    return ptr;
}

pub fn onUpdate(self: Self) void {
    glfw.glfwPollEvents();
    glfw.glfwSwapBuffers(self.window);
}

pub fn shutdown(self: Self) void {
    glfw.glfwDestroyWindow(self.window);
}

pub fn setVsync(self: *Self, enable: bool) void {
    if (enable) {
        glfw.glfwSwapInterval(1);
    } else {
        glfw.glfwSwapInterval(0);
    }

    self.data.vsync = enable;
}
