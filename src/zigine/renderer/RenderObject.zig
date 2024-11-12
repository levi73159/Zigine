const std = @import("std");
const za = @import("zalgebra");
const Shader = @import("shader.zig").Shader;
const VertexArray = @import("vertexArray.zig").VertexArray;
const ptr = @import("../ptr.zig");
const Texture = @import("texture.zig").Texture;

const Self = @This();

shader: ptr.Ref(Shader),
transform: za.Mat4 = za.Mat4.identity(),
vertex_array: ptr.Ref(VertexArray),

pub inline fn getShader(self: *const Self) *Shader {
    return self.shader.value;
}

pub inline fn getVertexArray(self: *const Self) *VertexArray {
    return self.vertex_array.value;
}

pub fn deinit(self: *Self) void {
    self.shader.releaseWithFn(Shader.deinit);
    self.vertex_array.releaseWithFnMut(VertexArray.destroyAll);
}
