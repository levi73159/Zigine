const std = @import("std");
const LayerInfo = @import("../LayerInfo.zig");
const Event = @import("../event.zig").Event;
const EventDispatcher = @import("../event.zig").EventDispatcher;
const App = @import("../App.zig");

const log = @import("../../root.zig").core_log;

const input = @import("../input.zig");
const glfw = @import("glfw");
const imgui = @import("imgui");

const Self = @This();

info: LayerInfo,
time: f32,

pub fn init() Self {
    return Self{ .info = .{ .name = "ImGuiLayer" }, .time = 0 };
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn onAttach(_: *Self) void {
    // const app = App.get().?;
}

pub fn onDetach(_: *Self) void {}

var should_show: bool = true;
pub fn onUpdate(self: *Self) void {
    const app = App.get().?;
    imgui.backend.newFrame(@intCast(app.window.getSize()[0]), @intCast(app.window.getSize()[1]));

    const current_time: f32 = @floatCast(glfw.getTime());
    imgui.io.setDeltaTime(if (self.time > 0.0) current_time - self.time else 1.0 / 60.0);
    self.time = current_time;

    imgui.showDemoWindow(&should_show);

    imgui.backend.draw();
}

pub fn toImGuiKey(key: input.Key) imgui.Key {
    return switch (key) {
        .tab => imgui.Key.tab,
        .left => imgui.Key.left_arrow,
        .right => imgui.Key.right_arrow,
        .up => imgui.Key.up_arrow,
        .down => imgui.Key.down_arrow,
        .page_up => imgui.Key.page_up,
        .page_down => imgui.Key.page_down,
        .home => imgui.Key.home,
        .end => imgui.Key.end,
        .insert => imgui.Key.insert,
        .delete => imgui.Key.delete,
        .backspace => imgui.Key.backspace,
        .space => imgui.Key.space,
        .enter => imgui.Key.enter,
        .escape => imgui.Key.escape,
        .a => imgui.Key.a,
        .c => imgui.Key.c,
        .v => imgui.Key.v,
        .x => imgui.Key.x,
        .y => imgui.Key.y,
        .z => imgui.Key.z,
        else => imgui.Key.none,
    };
}

pub fn toImGuiMouse(button: input.MouseButton) imgui.MouseButton {
    return switch (button) {
        .left => imgui.MouseButton.left,
        .right => imgui.MouseButton.right,
        .middle => imgui.MouseButton.left,
        else => imgui.MouseButton.left,
    };
}

pub fn onEvent(_: *Self, e: *Event) void {
    const dispatcher = EventDispatcher.init(e);
    _ = dispatcher.dispatch(.key_pressed, EventDispatcher.EventFn.fromFunc(onKeyPressed));
    _ = dispatcher.dispatch(.key_typed, EventDispatcher.EventFn.fromFunc(onKeyType));
    _ = dispatcher.dispatch(.key_released, EventDispatcher.EventFn.fromFunc(onKeyReleased));
    _ = dispatcher.dispatch(.mouse_moved, EventDispatcher.EventFn.fromFunc(onMouseMoved));
    _ = dispatcher.dispatch(.mouse_scrolled, EventDispatcher.EventFn.fromFunc(onMouseScrolled));
    _ = dispatcher.dispatch(.mouse_button_pressed, EventDispatcher.EventFn.fromFunc(onMouseButtonPressed));
    _ = dispatcher.dispatch(.mouse_button_released, EventDispatcher.EventFn.fromFunc(onMouseButtonReleased));
    _ = dispatcher.dispatch(.window_resize, EventDispatcher.EventFn.fromFunc(onWindowResize));
}

pub fn onKeyPressed(e: *Event) bool {
    imgui.io.addKeyEvent(toImGuiKey(e.data.key_pressed.button), true);

    imgui.io.addKeyEvent(.mod_ctrl, imgui.isKeyDown(.left_ctrl) or imgui.isKeyDown(.right_ctrl));
    imgui.io.addKeyEvent(.mod_shift, imgui.isKeyDown(.left_shift) or imgui.isKeyDown(.right_shift));
    imgui.io.addKeyEvent(.mod_alt, imgui.isKeyDown(.left_alt) or imgui.isKeyDown(.right_alt));
    imgui.io.addKeyEvent(.mod_super, imgui.isKeyDown(.left_super) or imgui.isKeyDown(.right_super));
    return false;
}

pub fn onKeyType(e: *Event) bool {
    var codepoint: [4]u8 = undefined;
    const written = std.unicode.utf8Encode(@intCast(e.data.key_typed), &codepoint) catch |err| {
        log.err("Failed to encode codepoint {} to utf8: {any}", .{ e.data.key_typed, err });
        return false;
    };
    codepoint[written] = 0;
    const text = codepoint[0..written :0];
    imgui.io.addInputCharactersUTF8(text.ptr);
    return false;
}

pub fn onKeyReleased(e: *Event) bool {
    imgui.io.addKeyEvent(toImGuiKey(e.data.key_released), false);
    return false;
}

pub fn onMouseMoved(e: *Event) bool {
    imgui.io.addMousePositionEvent(@floatCast(e.data.mouse_moved.x), @floatCast(e.data.mouse_moved.y));
    return false;
}

pub fn onMouseScrolled(e: *Event) bool {
    imgui.io.addMouseWheelEvent(@floatCast(e.data.mouse_scrolled.x), @floatCast(e.data.mouse_scrolled.y));
    return false;
}

pub fn onMouseButtonPressed(e: *Event) bool {
    imgui.io.addMouseButtonEvent(toImGuiMouse(e.data.mouse_button_pressed), true);
    return false;
}

pub fn onMouseButtonReleased(e: *Event) bool {
    imgui.io.addMouseButtonEvent(toImGuiMouse(e.data.mouse_button_released), false);
    return false;
}

pub fn onWindowResize(e: *Event) bool {
    const event_data = e.data.window_resize;
    imgui.io.setDisplaySize(@floatFromInt(event_data.x), @floatFromInt(event_data.y));
    imgui.io.setDisplayFramebufferScale(1.0, 1.0);
    @import("gl").Viewport(0, 0, @intCast(event_data.x), @intCast(event_data.y));
    return false;
}
