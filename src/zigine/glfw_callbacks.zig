const std = @import("std");
const glfw = @import("glfw.zig");
const Data = @import("Window.zig").Data;
const Event = @import("event.zig").Event;

const log = @import("../root.zig").core_log;

fn getUserData(window: ?*glfw.GLFWwindow) *Data {
    const raw_userptr = glfw.glfwGetWindowUserPointer(window) orelse std.debug.panic("GLFW User pointer not setup or not found!", .{});
    const data: *Data = @ptrCast(@alignCast(raw_userptr));
    return data;
}

inline fn callbackCall(data: *Data, event: *Event) void {
    if (data.event_callback) |callback| {
        callback.call(event);
    } else {
        log.warn("Callback function null", .{});
    }
}

pub fn glfwErrorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    log.err("GLFW Error({}): {s}", .{ err, description });
}

pub fn glfwWindowResizeCallback(window: ?*glfw.GLFWwindow, c_width: c_int, c_height: c_int) callconv(.C) void {
    const data = getUserData(window);
    const width: u32 = @intCast(c_width);
    const height: u32 = @intCast(c_height);
    data.width = width;
    data.height = height;

    var event = Event.init(.{ .window_resize = .{ .x = width, .y = height } });
    callbackCall(data, &event);
}

pub fn glfwWindowCloseCallback(window: ?*glfw.GLFWwindow) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.window_close);
    callbackCall(data, &event);
}

pub fn glfwKeyCallback(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = scancode;
    _ = mods;
    const data = getUserData(window);

    var event: Event = switch (action) {
        glfw.GLFW_PRESS => Event.init(.{ .key_pressed = .{ .button = @intCast(key), .repeat_count = 0 } }),
        glfw.GLFW_REPEAT => Event.init(.{ .key_pressed = .{ .button = @intCast(key), .repeat_count = 1 } }),
        glfw.GLFW_RELEASE => Event.init(.{ .key_released = .{ .button = @intCast(key) } }),
        else => unreachable,
    };

    callbackCall(data, &event);
}

pub fn glfwMouseBtnCallback(window: ?*glfw.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = mods;
    const data = getUserData(window);

    var event: Event = switch (action) {
        glfw.GLFW_PRESS => Event.init(.{ .mouse_button_pressed = .{ .button = @intCast(button) } }),
        glfw.GLFW_RELEASE => Event.init(.{ .mouse_button_released = .{ .button = @intCast(button) } }),
        else => unreachable,
    };
    callbackCall(data, &event);
}

pub fn glfwMouseScrollCallback(window: ?*glfw.GLFWwindow, xOffset: f64, yOffset: f64) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.{ .mouse_scrolled = .{ .x = xOffset, .y = yOffset } });
    callbackCall(data, &event);
}

pub fn glfwCursorPosCallback(window: ?*glfw.GLFWwindow, xOffset: f64, yOffset: f64) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.{ .mouse_moved = .{ .x = xOffset, .y = yOffset } });
    callbackCall(data, &event);
}

pub fn setCallbacks(window: ?*glfw.GLFWwindow) void {
    _ = glfw.glfwSetWindowSizeCallback(window, glfwWindowResizeCallback);
    _ = glfw.glfwSetWindowCloseCallback(window, glfwWindowCloseCallback);
    _ = glfw.glfwSetKeyCallback(window, glfwKeyCallback);
    _ = glfw.glfwSetMouseButtonCallback(window, glfwMouseBtnCallback);
    _ = glfw.glfwSetScrollCallback(window, glfwMouseScrollCallback);
    _ = glfw.glfwSetCursorPosCallback(window, glfwCursorPosCallback);
}
