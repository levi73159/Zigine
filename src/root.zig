const std = @import("std");

pub const core_log = std.log.scoped(.Zigine);
pub const App = @import("zigine/App.zig");
pub const events = @import("zigine/event.zig");

// logging
pub const std_options: std.Options = .{
    .logFn = logFn,
};

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = @tagName(scope);
    const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix ++ ": ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}
