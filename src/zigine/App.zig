const std = @import("std");

const glfw = @import("glfw.zig");
const log = @import("../root.zig").core_log;
const event = @import("event.zig");
const Window = @import("Window.zig");

const Self = @This();

extern fn createApp() *Self;
extern fn deleteApp(app: *Self) void;

window: *Window,
allocator: std.mem.Allocator,
running: bool = false,

pub fn init(allocator: std.mem.Allocator) !Self {
    return Self{ .window = try Window.init(allocator, .{ .title = "Zigine Engine", .width = 1280, .height = 720 }), .allocator = allocator };
}

pub fn setEventCallback(self: *Self) void {
    self.window.data.event_callback = Window.EventCallbackFn.fromMethod(self, &onEvent);
}

fn onEvent(self: *Self, e: *event.Event) void {
    const EventFn = event.EventDispatcher.EventFn;
    const disptacher = event.EventDispatcher.init(e);
    _ = disptacher.dispatch(.window_close, EventFn.fromMethod(self, &onWindowClose));

    var buffer: [1024]u8 = undefined;
    log.info("{!s}", .{e.data.getStringBuf(&buffer)});
}

// Events
pub fn onWindowClose(self: *Self, _: event.Event) bool {
    self.running = false;
    return true;
}

pub fn deinit(self: Self) void {
    self.window.shutdown();
    self.allocator.destroy(self.window);
}

pub fn run(self: *Self) void {
    self.running = true;
    while (self.running) {
        self.window.onUpdate();
    }
}

/// this is to start the program
pub fn start() !void {
    log.info("app is starting and creating...", .{});

    const app: *Self = createApp();
    app.setEventCallback();
    app.run();
    deleteApp(app);

    log.info("app exited!", .{});
}
