const std = @import("std");
const LayerInfo = @import("LayerInfo.zig");
const Event = @import("event.zig").Event;

const Self = @This();

allocator: std.mem.Allocator,
layers: std.ArrayListUnmanaged(Layer),
layer_insert: usize,

const BasicFunc = *const fn (ctx: *anyopaque) void;
const EventFunc = *const fn (ctx: *anyopaque, e: *Event) void;
const MemFunc = *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) void;

const Layer = struct {
    ctx: *anyopaque,
    info: *LayerInfo, // points into the LayerInfo in the ptr

    attach_fn: ?BasicFunc,
    detach_fn: ?BasicFunc,
    update_fn: ?BasicFunc,
    imgui_render_fn: ?BasicFunc,
    event_fn: ?EventFunc,
    deinit_fn: ?MemFunc,

    inline fn getMethod(comptime RetT: type, comptime name: []const u8, structure: anytype) ?RetT {
        if (@hasDecl(@TypeOf(structure), name)) {
            return @ptrCast(&@field(@TypeOf(structure), name));
        } else {
            return null;
        }
    }

    pub fn init(comptime T: type, allocator: std.mem.Allocator, layer_override: T) Layer {
        // allocates memory
        const ptr = allocator.create(T) catch unreachable;
        ptr.* = layer_override;

        const layer_info: *LayerInfo = blk: {
            if (@hasField(T, "layer_info")) {
                break :blk &ptr.layer_info;
            } else if (@hasField(T, "info")) {
                break :blk &ptr.info;
            } else {
                @compileError("A Layer must have a LayerInfo under the name of \"layer_info\", \"info\"");
            }
        };

        return Layer{
            .ctx = ptr,
            .info = layer_info,
            .attach_fn = getMethod(BasicFunc, "onAttach", layer_override),
            .detach_fn = getMethod(BasicFunc, "onDetach", layer_override),
            .update_fn = getMethod(BasicFunc, "onUpdate", layer_override),
            .imgui_render_fn = getMethod(BasicFunc, "onImGuiRender", layer_override),
            .event_fn = getMethod(EventFunc, "onEvent", layer_override),
            .deinit_fn = getMethod(MemFunc, "deinit", layer_override),
        };
    }

    pub fn deinit(self: Layer, allocator: std.mem.Allocator) void {
        self.deinit_fn.?(self.ctx, allocator);
    }

    pub fn onAttach(self: Layer) void {
        if (self.attach_fn) |func| {
            func(self.ctx);
        }
    }

    pub fn onDetach(self: Layer) void {
        if (self.detach_fn) |func| {
            func(self.ctx);
        }
    }

    pub fn onUpdate(self: Layer) void {
        if (self.update_fn) |func| {
            func(self.ctx);
        }
    }

    pub fn onImGuiRender(self: Layer) void {
        if (self.imgui_render_fn) |func| {
            func(self.ctx);
        }
    }

    pub fn onEvent(self: Layer, e: *Event) void {
        if (self.event_fn) |func| {
            func(self.ctx, e);
        }
    }
};

pub fn init(allocator: std.mem.Allocator) Self {
    // zig fmt: off
    return Self{
        .allocator = allocator,
        .layers = std.ArrayListUnmanaged(Layer).initCapacity(allocator, 0) catch unreachable,
        .layer_insert = 0,
    };
    // zig fmt: on
}

pub fn deinit(self: *Self) void {
    for (self.layers.items) |layer| {
        layer.onDetach();
        layer.deinit(self.allocator);
    }
    self.layers.deinit(self.allocator);
}

pub fn items(self: Self) []const Layer {
    return self.layers.items;
}

pub fn pushLayer(self: *Self, layer: anytype) !Layer {
    const actual_layer = Layer.init(@TypeOf(layer), self.allocator, layer);
    try self.layers.insert(self.allocator, self.layer_insert, actual_layer);
    self.layer_insert += 1;
    return actual_layer;
}

pub fn pushOverlay(self: *Self, overlay: anytype) !Layer {
    const actual_layer = Layer.init(@TypeOf(overlay), self.allocator, overlay);
    try self.layers.append(self.allocator, actual_layer);
    return actual_layer;
}

pub fn popLayer(self: Self) ?Layer {
    if (self.layers.items.len == 0) {
        return null;
    }
    defer self.layer_insert -= 1;
    return self.layers.orderedRemove(self.layer_insert);
}

pub fn popOverlay(self: Self) ?Layer {
    return self.layers.popOrNull();
}
