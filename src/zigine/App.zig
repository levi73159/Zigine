const std = @import("std");
const input = @import("input.zig");
const log = @import("../root.zig").core_log;
const event = @import("event.zig");
const Window = @import("Window.zig");
const LayerStack = @import("LayerStack.zig");
const ImGuiLayer = @import("imgui/ImGuiLayer.zig");
const Shader = @import("renderer/shader.zig").Shader;

const buffer = @import("renderer/buffer.zig");
const VertexArray = @import("renderer/vertexArray.zig").VertexArray;
const renderer = @import("renderer/renderer.zig");
const renderCommand = @import("renderer/renderCommand.zig");

const Self = @This();

extern fn createApp() *Self;
extern fn deleteApp(app: *Self) void;

window: *Window,
allocator: std.mem.Allocator,
layer_stack: LayerStack,
running: bool = false,

// Graphics pointers
vertex_array: *VertexArray,
square_va: *VertexArray,
shader: *Shader,

_imgui_layer: *ImGuiLayer, // built into application

var instance: ?*Self = null;

pub fn init(allocator: std.mem.Allocator) !*Self {
    std.debug.assert(instance == null);

    instance = try allocator.create(Self);
    instance.?.* = Self{
        .window = try Window.init(allocator, .{ .title = "Zigine Engine", .width = 1280, .height = 720 }),
        .allocator = allocator,
        .layer_stack = LayerStack.init(allocator),
        .vertex_array = undefined,
        .square_va = undefined,
        .shader = create: {
            const ptr = try allocator.create(Shader);
            ptr.* = try Shader.init(allocator, @embedFile("renderer/vertSrc.glsl"), @embedFile("renderer/fragSrc.glsl"));
            break :create ptr;
        },
        ._imgui_layer = undefined,
    };

    const self = instance.?;
    self.window.data.event_callback = Window.EventCallbackFn.fromMethod(self, &onEvent);

    self._imgui_layer = self.pushOverlayAndGet(ImGuiLayer.init()) catch unreachable;

    self.vertex_array = VertexArray.create(allocator) catch unreachable;

    const vertices = [_]f32{
        -0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0,
        0.0,  0.5,  0.0, 0.0, 0.0, 1.0, 1.0,
    };

    const vertex_buffer = buffer.VertexBuffer.create(allocator, &vertices) catch unreachable;

    const Element = buffer.BufferElement; // just to make it easier
    const layout = buffer.BufferLayout.init(allocator, &.{
        Element.init("a_Position", .float3),
        Element.init("a_Color", .float4),
    });

    vertex_buffer.setLayout(layout);
    self.vertex_array.addVertexBuffer(vertex_buffer);

    // vertex pos
    // gl.EnableVertexAttribArray(0);
    // gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);

    const indices = [_]u32{ 0, 1, 2 };

    const index_buffer = buffer.IndexBuffer.create(allocator, &indices) catch unreachable;
    self.vertex_array.setIndexBuffer(index_buffer);

    // create square va
    const square_verts = [_]f32{
        -0.75, -0.75, 0.0, 1.0, 0.0, 0.0, 1.0,
        0.75,  -0.75, 0.0, 0.0, 0.3, 0.7, 1.0,
        0.75,  0.75,  0.0, 0.2, 0.4, 0.6, 1.0,
        -0.75, 0.75,  0.0, 0.6, 0.0, 0.6, 1.0,
    };
    const square_vb = buffer.VertexBuffer.create(allocator, &square_verts) catch unreachable;
    square_vb.setLayout(layout.clone());

    self.square_va = VertexArray.create(allocator) catch unreachable;
    self.square_va.addVertexBuffer(square_vb);

    const indices_square = [_]u32{ 0, 1, 2, 2, 3, 0 };

    const square_ib = buffer.IndexBuffer.create(allocator, &indices_square) catch unreachable;
    self.square_va.setIndexBuffer(square_ib);

    return instance.?;
}

pub fn deinit(self: *Self) void {
    self.layer_stack.deinit();
    self.window.shutdown();

    // makes sure we actually free and destroy all the buffers in the vertex arrays
    self.square_va.destroyAll();
    self.vertex_array.destroyAll();
    self.allocator.destroy(self.window);
    self.allocator.destroy(self.shader);
    gl.makeProcTableCurrent(null);
}

pub fn get() ?*Self {
    return instance;
}

fn onEvent(self: *Self, e: *event.Event) void {
    const EventFn = event.EventDispatcher.EventFn;
    const disptacher = event.EventDispatcher.init(e);
    _ = disptacher.dispatch(.window_close, EventFn.fromMethod(self, &onWindowClose));

    var i: usize = self.layer_stack.layers.items.len;
    while (i > 0) {
        i -= 1;
        const layer = self.layer_stack.layers.items[i];
        layer.onEvent(e);
        if (e.handled) break;
    }
}

// Events
pub fn onWindowClose(self: *Self, _: event.Event) bool {
    self.running = false;
    return true;
}

// calls for layerstack
pub fn pushLayer(self: *Self, layer: anytype) !void {
    const actual_layer = try self.layer_stack.pushLayer(layer);
    actual_layer.onAttach();
}

pub fn pushOverlayAndGet(self: *Self, layer: anytype) !*@TypeOf(layer) {
    const actual_layer = try self.layer_stack.pushOverlay(layer);
    actual_layer.onAttach();
    return @ptrCast(@alignCast(actual_layer.ctx));
}

pub fn pushOverlay(self: *Self, overlay: anytype) !void {
    const actual_layer = try self.layer_stack.pushOverlay(overlay);
    actual_layer.onAttach();
}

pub fn run(self: *Self) void {
    self.running = true;
    while (self.running) {
        renderCommand.setClearColor(.{ .data = .{ 0.1, 0.1, 0.1, 1.0 } });
        renderCommand.clear();

        renderer.beginScene();

        // draw square
        self.shader.bind();

        renderer.submit(self.square_va);
        renderer.submit(self.vertex_array);

        renderer.endScene();

        for (self.layer_stack.items()) |layer| {
            layer.onUpdate();
        }

        self._imgui_layer.begin();
        for (self.layer_stack.items()) |layer| {
            layer.onImGuiRender();
        }
        self._imgui_layer.end();

        self.window.onUpdate();
    }
}

/// this is to start the program
pub fn start() void {
    log.info("app is starting and creating...", .{});

    const app: *Self = createApp();
    app.run();
    deleteApp(app);

    log.info("app exited!", .{});
}
