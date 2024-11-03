const std = @import("std");
const VertexArray = @import("vertexArray.zig").VertexArray;
const renderCommand = @import("renderCommand.zig");

pub const api = @import("rendererAPI.zig").api;

pub fn beginScene() void {}

pub fn endScene() void {}

pub fn submit(vertex_array: *const VertexArray) void {
    vertex_array.bind();
    renderCommand.drawIndexed(vertex_array);
}
