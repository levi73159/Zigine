const std = @import("std");
const gl = @import("gl");

pub const VertexBuffer = struct {
    const Self = @This();
    renderer_id: u32 = 0,

    pub fn create(allocator: std.mem.Allocator, vertices: []const f32) !*Self {
        const self = try allocator.create(Self);

        gl.CreateBuffers(1, @ptrCast(&self.renderer_id));
        gl.BindBuffer(gl.ARRAY_BUFFER, self.renderer_id);
        gl.BufferData(gl.ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, gl.STATIC_DRAW);

        return self;
    }

    pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
        gl.DeleteBuffers(1, @constCast(@ptrCast(&self.renderer_id)));
        allocator.destroy(self);
    }

    pub fn bind(self: Self) void {
        gl.BindBuffer(gl.ARRAY_BUFFER, self.renderer_id);
    }

    pub fn unbind() void {
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    }
};

pub const IndexBuffer = struct {
    const Self = @This();
    renderer_id: u32 = 0,
    count: isize,

    pub fn create(allocator: std.mem.Allocator, indices: []const u32) !*Self {
        const self = try allocator.create(Self);
        self.count = @intCast(indices.len);

        gl.CreateBuffers(1, @ptrCast(&self.renderer_id));
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.renderer_id);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, gl.STATIC_DRAW);

        return self;
    }

    pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
        gl.DeleteBuffers(1, @constCast(@ptrCast(&self.renderer_id)));
        allocator.destroy(self);
    }

    pub fn bind(self: Self) void {
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.renderer_id);
    }

    pub fn unbind() void {
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }
};
