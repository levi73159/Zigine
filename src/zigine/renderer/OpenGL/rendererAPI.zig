const std = @import("std");
const za = @import("zalgebra");
const gl = @import("gl");

const VertexArray = @import("VertexArray.zig");
const Color = @import("../../Color.zig");

pub fn init() void {
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
}

pub fn setClearColor(color: Color) void {
    gl.ClearColor(color.r(), color.g(), color.b(), color.a());
}

pub fn clear() void {
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}

pub fn drawIndexed(vertex_array: *const VertexArray) void {
    gl.DrawElements(gl.TRIANGLES, vertex_array.getIndexBufferCountGL(), gl.UNSIGNED_INT, 0);
}
