const std = @import("std");
const za = @import("zalgebra");
const gl = @import("gl");

const VertexArray = @import("VertexArray.zig");

pub fn setClearColor(color: za.Vec4) void {
    gl.ClearColor(color.x(), color.y(), color.z(), color.w());
}

pub fn clear() void {
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}

pub fn drawIndexed(vertex_array: *const VertexArray) void {
    gl.DrawElements(gl.TRIANGLES, vertex_array.getIndexBufferCountGL(), gl.UNSIGNED_INT, 0);
}
