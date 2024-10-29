const std = @import("std");
const gl = @import("gl");
const dbg = @import("builtin").mode == .Debug;

const log = std.log.scoped(.OpenGL);

pub const VertexBuffer = struct {
    const Self = @This();
    renderer_id: u32 = 0,
    layout: BufferLayout,

    pub fn create(allocator: std.mem.Allocator, vertices: []const f32) !*Self {
        const self = try allocator.create(Self);

        gl.CreateBuffers(1, @ptrCast(&self.renderer_id));
        gl.BindBuffer(gl.ARRAY_BUFFER, self.renderer_id);
        gl.BufferData(gl.ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, gl.STATIC_DRAW);

        return self;
    }

    pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
        gl.DeleteBuffers(1, @constCast(@ptrCast(&self.renderer_id)));
        self.layout.deinit();
        allocator.destroy(self);
    }

    pub fn bind(self: Self) void {
        gl.BindBuffer(gl.ARRAY_BUFFER, self.renderer_id);
    }

    pub fn unbind() void {
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    }

    pub fn setLayout(self: *Self, layout: BufferLayout) void {
        // don't display this message in release
        if (dbg and self.layout.elements.items.len == 0) log.debug("setting an empty layout", .{});
        self.layout = layout;
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

const ShaderDataType = enum {
    const Self = @This();
    // zig fmt: off
    none,
    float, float2, float3, float4,
    mat3, mat4,
    int, int2, int3, int4,
    bool,
    // zig fmt: on

    fn size(self: Self) u32 {
        return switch (self) {
            .none => err: {
                // if we are not in debug mode
                // - we want to crash and cause a panic
                // otherwise we just want to print an err and hope its ok
                if (@import("builtin").mode == .Debug) {
                    std.debug.panic("Unknown ShaderDataType", .{});
                }

                log.err("Unknow ShaderDataType", .{});
                break :err 0;
            },
            .float => @sizeOf(f32),
            .float2 => @sizeOf(f32) * 2,
            .float3 => @sizeOf(f32) * 3,
            .float4 => @sizeOf(f32) * 4,
            .mat3 => @sizeOf(f32) * 3 * 3,
            .mat4 => @sizeOf(f32) * 4 * 4,
            .int => @sizeOf(i32),
            .int2 => @sizeOf(i32) * 2,
            .int3 => @sizeOf(i32) * 3,
            .int4 => @sizeOf(i32) * 4,
            .bool => @sizeOf(bool),
        };
    }

    pub fn count(self: Self) u32 {
        return switch (self) {
            .float2, .int2 => 2,
            .float3, .int3 => 3,
            .float4, .int4 => 4,
            .mat3 => 3 * 3,
            .mat4 => 4 * 4,
            else => 1,
        };
    }

    pub fn nativeType(self: Self) gl.@"enum" {
        return switch (self) {
            .float, .float2, .float3, .float4 => gl.FLOAT,
            .mat3, .mat4 => gl.FLOAT,
            .int, .int2, .int3, .int4 => gl.INT,
            .bool => gl.BOOL,
            .none => unreachable,
        };
    }
};

pub const BufferElement = struct {
    name: []const u8,
    type: ShaderDataType,
    offset: u32,
    size: u32,
    normalized: bool = false,

    pub fn init(name: []const u8, @"type": ShaderDataType) BufferElement {
        return initNormalized(name, @"type", false);
    }

    pub fn initNormalized(name: []const u8, @"type": ShaderDataType, norm: bool) BufferElement {
        return BufferElement{
            .name = name,
            .type = @"type",
            .offset = 0,
            .size = @"type".size(),
            .normalized = norm,
        };
    }
};

pub const BufferLayout = struct {
    const Self = @This();

    elements: std.ArrayList(BufferElement),
    stride: u32,

    pub fn initEmpty(allocator: std.mem.Allocator) Self {
        // the reason why we want to warn them because initlizing an empty buffer layout is not really performant so we want to avoid it but it may be wanted
        log.warn("initlizing empty BufferLayout", .{});
        return Self{
            .elements = std.ArrayList(BufferElement).init(allocator),
            .stride = 0,
        };
    }

    pub fn init(allocator: std.mem.Allocator, elements: []const BufferElement) Self {
        if (elements.len == 0) return initEmpty(allocator);
        var self = Self{
            .elements = std.ArrayList(BufferElement).init(allocator),
            .stride = 0,
        };
        self.elements.appendSlice(elements) catch unreachable;
        self.calcualteOffsetAndStride();
        return self;
    }

    pub fn deinit(self: Self) void {
        self.elements.deinit();
    }

    /// NOTE: `init` is faster then adding each element one by one because we don't have to re-calculate the stride & offset
    /// sort of a waste but we keep this function just in case we need to change the layout and wanna just add an element
    pub fn addElement(self: *Self, element: BufferElement) void {
        self.elements.append(element) catch unreachable;
        self.calcualteOffsetAndStride();
    }

    fn calcualteOffsetAndStride(self: *Self) void {
        var offset: u32 = 0;
        self.stride = 0;
        for (self.elements.items) |*element| {
            element.offset = offset;
            offset += element.size;
            self.stride += element.size;
        }
    }
};
