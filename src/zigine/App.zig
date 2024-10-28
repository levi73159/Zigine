const std = @import("std");
const gl = @import("gl");
const glfw = @import("glfw");
const input = @import("input.zig");
const log = @import("../root.zig").core_log;
const event = @import("event.zig");
const Window = @import("Window.zig");
const LayerStack = @import("LayerStack.zig");
const ImGuiLayer = @import("imgui/ImGuiLayer.zig");
const Shader = @import("renderer/Shader.zig");

const buffer = @import("renderer/buffer.zig");

const Self = @This();

extern fn createApp() *Self;
extern fn deleteApp(app: *Self) void;

window: *Window,
allocator: std.mem.Allocator,
layer_stack: LayerStack,
running: bool = false,
vertex_buffer: *const buffer.VertexBuffer,
index_buffer: *const buffer.IndexBuffer,
vertex_array: u32 = 0,
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
        .vertex_buffer = undefined,
        .index_buffer = undefined,
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

    gl.GenVertexArrays(1, @ptrCast(&self.vertex_array));
    gl.BindVertexArray(self.vertex_array);

    const vertices = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    self.vertex_buffer = buffer.VertexBuffer.create(allocator, &vertices) catch unreachable;

    // vertex pos
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);

    const indices = [_]u32{ 0, 1, 2 };

    self.index_buffer = buffer.IndexBuffer.create(allocator, &indices) catch unreachable;
    return instance.?;
}

pub fn deinit(self: *Self) void {
    self.layer_stack.deinit();
    self.window.shutdown();

    self.vertex_buffer.destroy(self.allocator);
    self.index_buffer.destroy(self.allocator);
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
        gl.ClearColor(0.1, 0.1, 0.1, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        self.shader.bind();
        gl.BindVertexArray(self.vertex_array);
        gl.DrawElements(gl.TRIANGLES, @truncate(self.index_buffer.count), gl.UNSIGNED_INT, 0);

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
