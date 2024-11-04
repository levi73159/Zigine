const std = @import("std");
const za = @import("zalgebra");

pub const OrthoCamera = struct {
    const Self = @This();

    projection_mat: za.Mat4,
    view_mat: za.Mat4,
    view_proj_mat: za.Mat4,

    /// this two variable `position` and `rotation` should only be set using the setters
    _position: za.Vec3 = za.Vec3.zero(),
    /// this two variable `position` and `rotation` should only be set using the setters
    _rotation: f32 = 0.0,

    pub fn init(left: f32, right: f32, bottom: f32, top: f32) Self {
        const projection_mat = za.orthographic(left, right, bottom, top, -1.0, 1.0);
        const view_mat = za.Mat4.identity();
        return Self{
            .projection_mat = projection_mat,
            .view_mat = view_mat,
            .view_proj_mat = projection_mat.mul(view_mat),
        };
    }

    // setters for pos roation
    pub fn setPosition(self: *Self, pos: za.Vec3) void {
        self._position = pos;
        self.recalculateViewMatrix();
    }

    pub fn getPosition(self: Self) za.Vec3 {
        return self._position;
    }

    pub fn setRotation(self: *Self, rotation: f32) void {
        self._rotation = rotation;
        self.recalculateViewMatrix();
    }

    pub fn getRotation(self: Self) f32 {
        return self._rotation;
    }

    fn recalculateViewMatrix(self: *Self) void {
        const transform = za.Mat4.identity()
            .rotate(self._rotation, za.Vec3.new(0, 0, 1))
            .translate(self._position);

        self.view_mat = transform.inv();
        self.view_proj_mat = self.projection_mat.mul(self.view_mat);
    }
};
