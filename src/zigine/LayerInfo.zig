//! this structure is to help for overriding Layers which must be done
//! All layers will have this LayerInfo
//! And All Layers will have a
//! - onAttach(self: *anyopeque) void : anyopeque meaining it can be any pointer
//! - onDetach(self: *anyopegue) void
//! - onUpdate(self: *anyopegue) void
//! - onImGuiRender(self: *anyopegue) void
//! - onEvent(self: *anyopegue, event: *Event) void
//! - deinit(self: *anyopegue, allocator: std.mem.Allocator) void
const Self = @This();

name: []const u8,

pub fn init(name: []const u8) Self {
    return Self{ .name = name };
}
