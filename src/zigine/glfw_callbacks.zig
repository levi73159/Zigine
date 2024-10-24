const std = @import("std");
const glfw = @import("glfw");
const imgui = @import("imgui");
const Data = @import("Window.zig").Data;
const Event = @import("event.zig").Event;
const input = @import("input.zig");

const log = @import("../root.zig").core_log;

fn getUserData(window: *glfw.Window) *Data {
    const data: *Data = window.getUserPointer(Data).?;
    return data;
}

inline fn callbackCall(data: *Data, event: *Event) void {
    if (data.event_callback) |callback| {
        callback.call(event);
    } else {
        log.warn("Callback function null", .{});
    }
}

pub fn glfwErrorCallback(err: i32, description: *?[:0]const u8) callconv(.C) void {
    log.err("GLFW Error({}): {s}", .{ err, description });
}

pub fn glfwWindowResizeCallback(window: *glfw.Window, c_width: i32, c_height: i32) callconv(.C) void {
    const data = getUserData(window);
    const width: u32 = @intCast(c_width);
    const height: u32 = @intCast(c_height);
    data.width = width;
    data.height = height;

    var event = Event.init(.{ .window_resize = .{ .x = width, .y = height } });
    callbackCall(data, &event);
}

pub fn glfwWindowCloseCallback(window: *glfw.Window) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.window_close);
    callbackCall(data, &event);
}

pub fn glfwKeyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = scancode;
    _ = mods;
    const data = getUserData(window);

    var event: Event = switch (action) {
        .press => Event.init(.{ .key_pressed = .{ .button = input.Key.fromGLFW(key), .repeat_count = 0 } }),
        .repeat => Event.init(.{ .key_pressed = .{ .button = input.Key.fromGLFW(key), .repeat_count = 1 } }),
        .release => Event.init(.{ .key_released = input.Key.fromGLFW(key) }),
    };

    callbackCall(data, &event);
}

pub fn glfwTypeCallback(window: *glfw.Window, codepoint: u32) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.{ .key_typed = codepoint });
    callbackCall(data, &event);
}

pub fn glfwMouseBtnCallback(window: *glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = mods;
    const data = getUserData(window);

    var event: Event = switch (action) {
        .press => Event.init(.{ .mouse_button_pressed = input.MouseButton.fromGLFW(button) }),
        .release => Event.init(.{ .mouse_button_released = input.MouseButton.fromGLFW(button) }),
        else => unreachable,
    };
    callbackCall(data, &event);
}

pub fn glfwMouseScrollCallback(window: *glfw.Window, xOffset: f64, yOffset: f64) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.{ .mouse_scrolled = .{ .x = xOffset, .y = yOffset } });
    callbackCall(data, &event);
}

pub fn glfwCursorPosCallback(window: *glfw.Window, xOffset: f64, yOffset: f64) callconv(.C) void {
    const data = getUserData(window);

    var event = Event.init(.{ .mouse_moved = .{ .x = xOffset, .y = yOffset } });
    callbackCall(data, &event);
}

pub fn setCallbacks(window: *glfw.Window) void {
    _ = window.setSizeCallback(glfwWindowResizeCallback);
    _ = window.setCloseCallback(glfwWindowCloseCallback);
    _ = window.setKeyCallback(glfwKeyCallback);
    _ = window.setCharCallback(glfwTypeCallback);
    _ = window.setMouseButtonCallback(glfwMouseBtnCallback);
    _ = window.setScrollCallback(glfwMouseScrollCallback);
    _ = window.setCursorPosCallback(glfwCursorPosCallback);
}
