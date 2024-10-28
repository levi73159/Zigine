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

var imgui_config: imgui.ConfigFlags = undefined;
pub fn onAttach(_: *Self) void {
    imgui_config = imgui.ConfigFlags{ .dock_enable = true, .viewport_enable = true };
    imgui.io.setConfigFlags(imgui_config);

    const style = imgui.getStyle();
    if (imgui_config.viewport_enable) {
        style.window_rounding = 0.0;
        const idx: usize = @intFromEnum(imgui.StyleCol.window_bg);
        style.colors[idx][3] = 1.0;
    }

    const app = App.get().?;

    imgui.backend.initWithGlSlVersion(app.window.getNative(), "#version 410");
}

pub fn onDetach(_: *Self) void {}

pub fn begin(_: *Self) void {
    const app = App.get().?;
    const size = app.window.getFrameBufferSize();
    imgui.backend.newFrame(@intCast(size[0]), @intCast(size[1]));
}

pub fn end(_: *Self) void {
    const app = App.get().?;
    const display_size = app.window.getSize();
    imgui.io.setDisplaySize(@floatFromInt(display_size[0]), @floatFromInt(display_size[1]));

    imgui.backend.draw();

    if (imgui_config.viewport_enable) {
        const backup_current_context: *glfw.Window = glfw.getCurrentContext();
        imgui.updatePlatformWindows();
        glfw.makeContextCurrent(backup_current_context);
    }
}

var show_demo_window: bool = true;
pub fn onImGuiRender(_: *Self) void {
    imgui.showDemoWindow(&show_demo_window);
}
