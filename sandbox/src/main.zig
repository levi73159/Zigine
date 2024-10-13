const std = @import("std");
const zigine = @import("zigine");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const log = std.log.scoped(.sandbox);
pub const std_options: std.Options = zigine.std_options;

export fn createApp() *zigine.App {
    const app_ptr = gpa.allocator().create(zigine.App) catch std.debug.panic("Error not enough memory to run app", .{});
    app_ptr.* = zigine.App.init();
    return app_ptr;
}
export fn deleteApp(app: *zigine.App) void {
    gpa.allocator().destroy(app);
}

pub fn main() !void {
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            log.err("Memory Leak Detected!", .{});
        }
    }
    try zigine.App.start();
}
