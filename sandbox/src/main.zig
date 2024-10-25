const std = @import("std");
const zigine = @import("zigine");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const log = std.log.scoped(.sandbox);
pub const std_options: std.Options = zigine.std_options;

const ExampleLayer = struct {
    info: zigine.LayerInfo,

    pub fn init() ExampleLayer {
        return ExampleLayer{ .info = .{ .name = "Example" } };
    }

    pub fn deinit(self: *ExampleLayer, allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }

    pub fn onUpdate(self: *ExampleLayer) void {
        _ = self;
        log.debug("Tab Pressed? {}", .{zigine.input.isKeyPressed(.tab)});
    }
};

inline fn errPush() noreturn {
    log.err("Unrecovable error while pushing", .{});
    std.process.abort();
}

export fn createApp() *zigine.App {
    const app = zigine.App.init(gpa.allocator()) catch |err| switch (err) {
        error.NotInitialized,
        error.APIUnavailable,
        error.InvalidEnum,
        error.InvalidValue,
        error.VersionUnavailable,
        error.PlatformUnavailable,
        error.PlatformError,
        => std.debug.panic("Failed to init app due to glfw {any}", .{err}),
        error.OutOfMemory => std.debug.panic("Program doesn't have enough memory to init app!!!", .{}),
        else => std.debug.panic("Failed to init app due to: {any}", .{err}),
    };
    app.pushLayer(ExampleLayer.init()) catch errPush();
    return app;
}

export fn deleteApp(app: *zigine.App) void {
    app.deinit();
    gpa.allocator().destroy(app);
}

pub fn main() !void {
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            log.err("Memory Leak Detected!", .{});
        }
    }
    zigine.App.start();
}
