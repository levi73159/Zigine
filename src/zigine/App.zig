const std = @import("std");

const log = @import("../root.zig").core_log;
const event = @import("event.zig");

const Self = @This();

extern fn createApp() *Self;
extern fn deleteApp(app: *Self) void;

pub fn init() Self {
    return .{};
}

pub fn run(self: Self) void {
    _ = self;
    const windowResizeEvent = event.Event.init(.{ .window_resize = .{ .x = 2700, .y = 720 } });
    var buffer: [1024]u8 = undefined;

    const resizebuf = windowResizeEvent.data.getStringBuf(&buffer) catch |err| {
        log.err("Failed to get string buf {any}", .{err});
        return;
    };

    log.info("{s}", .{resizebuf});

    while (true) {}
}

/// this is to start the program
pub fn start() !void {
    log.info("app is starting and creating...", .{});

    const app: *Self = createApp();
    app.run();
    deleteApp(app);

    log.info("app exited!", .{});
}
