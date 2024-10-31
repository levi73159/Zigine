const std = @import("std");
const buffer = @import("buffer.zig");
const gl = @import("gl");

const Self = @This();

const log = std.log.scoped(.OpenGL);

allocator: std.mem.Allocator,
vertex_buffs: std.ArrayListUnmanaged(*const buffer.VertexBuffer), // unmanaged because we store the allocator
index_buffer: ?*const buffer.IndexBuffer,
renderer_id: u32,

pub fn create(allocator: std.mem.Allocator) !*Self {
    var vao: u32 = undefined;
    gl.CreateVertexArrays(1, @ptrCast(&vao));

    const self = try allocator.create(Self);
    self.* = Self{
        .renderer_id = vao,
        .allocator = allocator,
        .vertex_buffs = std.ArrayListUnmanaged(*const buffer.VertexBuffer){},
        .index_buffer = null,
    };

    return self;
}

/// we do not own the buffers so we do not need to delete them
pub fn destroy(self: *Self) void {
    gl.DeleteVertexArrays(1, @ptrCast(&self.renderer_id));
    self.vertex_buffs.deinit(self.allocator);
    self.allocator.destroy(self);
}

/// this function will actually destroy the conected buffers
pub fn destroyAll(self: *Self) void {
    for (self.vertex_buffs.items) |vertex_buf| {
        vertex_buf.destroy(self.allocator);
    }
    if (self.index_buffer) |index_buf| {
        index_buf.destroy(self.allocator);
    }

    self.destroy();
}

pub fn addVertexBuffer(self: *Self, vertex_buf: *const buffer.VertexBuffer) void {
    if (vertex_buf.layout == null or vertex_buf.layout.?.elements.items.len == 0) {
        log.err("Vertex Buffer have no layout!", .{});
        std.debug.assert(false);
        return;
    }

    gl.BindVertexArray(self.renderer_id);
    vertex_buf.bind();

    for (vertex_buf.layout.?.elements.items, 0..) |element, i| {
        gl.EnableVertexAttribArray(@intCast(i));
        gl.VertexAttribPointer(
            @intCast(i),
            @intCast(element.type.count()),
            element.type.nativeType(),
            if (element.normalized) gl.TRUE else gl.FALSE,
            @intCast(vertex_buf.layout.?.stride),
            @intCast(element.offset),
        );
    }

    self.vertex_buffs.append(self.allocator, vertex_buf) catch unreachable;
}

pub fn setIndexBuffer(self: *Self, index_buf: *const buffer.IndexBuffer) void {
    gl.BindVertexArray(self.renderer_id);
    index_buf.bind();

    self.index_buffer = index_buf;
}

// if index buffer is not set retursn -1
pub fn getIndexBufferCount(self: Self) isize {
    const index_buf = self.index_buffer orelse return -1;
    return index_buf.count;
}

// same thing as `getIndexBufferCount` but returns the opengl value
pub fn getIndexBufferCountGL(self: Self) gl.sizei {
    return @truncate(self.getIndexBufferCount());
}

pub fn bind(self: Self) void {
    gl.BindVertexArray(self.renderer_id);
}

pub fn unbind() void {
    gl.BindVertexArray(0);
}
