const VertexArray = @import("vertexArray.zig").VertexArray;
const rendererAPI = @import("rendererAPI.zig");

const za = @import("zalgebra");

pub inline fn setClearColor(color: za.Vec4) void {
    rendererAPI.setClearColor(color);
}

pub inline fn clear() void {
    rendererAPI.clear();
}

pub inline fn drawIndexed(vertex_array: *const VertexArray) void {
    rendererAPI.drawIndexed(vertex_array);
}
