const std = @import("std");

pub const core_log = std.log.scoped(.Zigine);
pub const App = @import("zigine/App.zig");
pub const events = @import("zigine/event.zig");
pub const Window = @import("zigine/Window.zig");
pub const LayerInfo = @import("zigine/LayerInfo.zig");
pub const ImGuiLayer = @import("zigine/imgui/ImGuiLayer.zig");

// include buttons and input so we don't have to use input.Key etc
pub const input = @import("zigine/input.zig");
pub const Key = input.Key;
pub const MouseButton = input.MouseButton;

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
    const color_prefix = comptime switch (level) {
        .info => "\x1b[0;34m", // blue
        .warn => "\x1b[0;33m", // yellow
        .err => "\x1b[0;31m", // red
        else => "\x1b[0m",
    };
    const suffix = "\x1b[0m";
    const scope_prefix = @tagName(scope);
    const prefix = color_prefix ++ "[" ++ comptime level.asText() ++ "] " ++ scope_prefix ++ ": ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ suffix ++ "\n", args) catch return;
}

comptime {
    const gl = @import("gl");
    @setEvalBranchQuota(1_000_000);
    for (@typeInfo(gl).Struct.decls) |decl_info| switch (@typeInfo(@TypeOf(@field(gl, decl_info.name)))) {
        .Fn => |fn_info| {
            if (fn_info.calling_convention == gl.APIENTRY) {
                const f = &@field(gl, decl_info.name);
                @export(f, .{ .name = "gl" ++ decl_info.name });
            }
        },
        else => {},
    };
}
