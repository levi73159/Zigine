const std = @import("std");
const VertexArray = @import("vertexArray.zig").VertexArray;
const Shader = @import("shader.zig").Shader;
const renderCommand = @import("renderCommand.zig");
const RenderObject = @import("RenderObject.zig");
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

pub fn submit(object: *const RenderObject) void {
    object.getVertexArray().bind();
    object.getShader().bind();
    object.getShader().uploadUnifrom("u_VP", .{ .mat4 = data.?.view_proj_mat.data });
    object.getShader().uploadUnifrom("u_Transform", .{ .mat4 = object.transform.data });
    renderCommand.drawIndexed(object.getVertexArray());
}
