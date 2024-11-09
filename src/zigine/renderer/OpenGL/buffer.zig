const std = @import("std");
const gl = @import("gl");
const dbg = @import("builtin").mode == .Debug;
const ShaderDataType = @import("../shader.zig").ShaderDataType;
const Ref = @import("../../ptr.zig").Ref;

const log = std.log.scoped(.OpenGL);

pub const VertexBuffer = struct {
    const Self = @This();
    renderer_id: u32 = 0,
    layout: ?Layout,

    pub fn create(allocator: std.mem.Allocator, vertices: []const f32) !Ref(Self) {
        const ref = try Ref(Self).init(allocator, Self{ .layout = null });
        const self = ref.value;

        gl.CreateBuffers(1, @ptrCast(&self.renderer_id));
        gl.BindBuffer(gl.ARRAY_BUFFER, self.renderer_id);
        gl.BufferData(gl.ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, gl.STATIC_DRAW);

        return ref;
    }

    pub fn destroy(self: Self) void {
        gl.DeleteBuffers(1, @constCast(@ptrCast(&self.renderer_id)));
        if (self.layout) |layout| {
            layout.deinit();
        }
    }

    pub fn bind(self: Self) void {
        gl.BindBuffer(gl.ARRAY_BUFFER, self.renderer_id);
    }

    pub fn unbind() void {
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    }

    pub fn setLayout(self: *Self, layout: Layout) void {
        // don't display this message in release
        if (dbg and layout.elements.items.len == 0) log.debug("setting an empty layout", .{});
        self.layout = layout;
    }
};

pub const IndexBuffer = struct {
    const Self = @This();
    renderer_id: u32 = 0,
    count: isize,

    pub fn create(allocator: std.mem.Allocator, indices: []const u32) !Ref(Self) {
        const ref = try Ref(Self).init(allocator, Self{
            .count = @intCast(indices.len),
        });
        const self = ref.value;

        gl.CreateBuffers(1, @ptrCast(&self.renderer_id));
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.renderer_id);
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, gl.STATIC_DRAW);

        return ref;
    }

    pub fn destroy(self: Self) void {
        gl.DeleteBuffers(1, @constCast(@ptrCast(&self.renderer_id)));
    }

    pub fn bind(self: Self) void {
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.renderer_id);
    }

    pub fn unbind() void {
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }
};

pub const Element = struct {
    name: []const u8,
    type: ShaderDataType,
    offset: u32,
    size: u32,
    normalized: bool = false,

    pub fn init(name: []const u8, @"type": ShaderDataType) Element {
        return initNormalized(name, @"type", false);
    }

    pub fn initNormalized(name: []const u8, @"type": ShaderDataType, norm: bool) Element {
        return Element{
            .name = name,
            .type = @"type",
            .offset = 0,
            .size = @"type".size(),
            .normalized = norm,
        };
    }
};

pub const Layout = struct {
    const Self = @This();

    elements: std.ArrayList(Element),
    stride: u32,

    pub fn initEmpty(allocator: std.mem.Allocator) Self {
        // the reason why we want to warn them because initlizing an empty buffer layout is not really performant so we want to avoid it but it may be wanted
        log.warn("initlizing empty BufferLayout", .{});
        return Self{
            .elements = std.ArrayList(Element).init(allocator),
            .stride = 0,
        };
    }

    pub fn init(allocator: std.mem.Allocator, elements: []const Element) Self {
        if (elements.len == 0) return initEmpty(allocator);
        var self = Self{
            .elements = std.ArrayList(Element).init(allocator),
            .stride = 0,
        };
        self.elements.appendSlice(elements) catch unreachable;
        self.calcualteOffsetAndStride();
        return self;
    }

    pub fn clone(self: Self) Self {
        return Self{
            .elements = self.elements.clone() catch unreachable,
            .stride = self.stride,
        };
    }

    pub fn deinit(self: Self) void {
        self.elements.deinit();
    }

    /// NOTE: `init` is faster then adding each element one by one because we don't have to re-calculate the stride & offset
    /// sort of a waste but we keep this function just in case we need to change the layout and wanna just add an element
    pub fn addElement(self: *Self, element: Element) void {
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
