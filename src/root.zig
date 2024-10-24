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
    const scope_prefix = @tagName(scope);
    const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix ++ ": ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
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
