const std = @import("std");
const VertexArray = @import("vertexArray.zig").VertexArray;
const Shader = @import("shader.zig").Shader;
const renderCommand = @import("renderCommand.zig");
const cam = @import("camera.zig");
const za = @import("zalgebra");

pub const api = @import("rendererAPI.zig").api;

const SceneData = struct {
    view_proj_mat: za.Mat4,
};

/// this will exist throughout the entire lifetime of the runtime
var data: ?SceneData = null;

pub fn beginScene(camera: *const cam.OrthoCamera) void {
    data = .{
        .view_proj_mat = camera.view_proj_mat,
    };
}

pub fn endScene() void {}

pub fn submit(vertex_array: *const VertexArray, shader: ?*const Shader) void {
    vertex_array.bind();
    if (shader) |s| {
        s.bind();
        s.uploadUnifromMat4("u_VP", data.?.view_proj_mat);
    }
    renderCommand.drawIndexed(vertex_array);
}
