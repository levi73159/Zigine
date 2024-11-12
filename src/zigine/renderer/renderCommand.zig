const VertexArray = @import("vertexArray.zig").VertexArray;
const rendererAPI = @import("rendererAPI.zig");
const Color = @import("../Color.zig");
const Ref = @import("../ptr.zig").Ref;

pub inline fn init() void {
    rendererAPI.init();
}

pub inline fn setClearColor(color: Color) void {
    rendererAPI.setClearColor(color);
}

pub inline fn clear() void {
    rendererAPI.clear();
}

pub inline fn drawIndexed(vertex_array: *const VertexArray) void {
    rendererAPI.drawIndexed(vertex_array);
}
