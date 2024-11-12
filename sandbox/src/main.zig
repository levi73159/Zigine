const std = @import("std");
const zine = @import("zigine");
const imgui = @import("imgui");
const za = @import("zalgebra");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const log = std.log.scoped(.sandbox);
pub const std_options: std.Options = zine.std_options;

const ExampleLayer = struct {
    info: zine.LayerInfo,
    camera: zine.camera.OrthoCamera,
    square_object: zine.RenderObject,
    texture_shader: zine.Ref(zine.Shader),
    texture: zine.Ref(zine.Texture2D),
    imgui_window_open: bool = true,
    clear_color: zine.Color = .{ .data = .{ 0.1, 0.1, 0.1, 1.0 } },

    color1: zine.Color = .{ .data = .{ 0.8, 0.2, 0.3, 1.0 } },
    color2: zine.Color = .{ .data = .{ 0.3, 0.2, 0.8, 1.0 } },

    square_pos: za.Vec3 = .{ .data = .{ 0.0, 0.0, 0.0 } },

    pub fn init() ExampleLayer {
        const Element = zine.buffer.Element;
        const layout = zine.buffer.Layout.init(allocator, &.{
            Element.init("a_Position", .float3),
            Element.init("a_TexCoord", .float2),
        });

        // create square va
        const square_verts = [_]f32{
            -0.5, -0.5, 0.0, 0.0, 0.0,
            0.5,  -0.5, 0.0, 1.0, 0.0,
            0.5,  0.5,  0.0, 1.0, 1.0,
            -0.5, 0.5,  0.0, 0.0, 1.0,
        };
        const square_vb = zine.buffer.VertexBuffer.create(allocator, &square_verts) catch unreachable;
        square_vb.value.setLayout(layout);

        const square_va = zine.VertexArray.create(allocator) catch unreachable;
        square_va.value.addVertexBuffer(square_vb);

        const indices_square = [_]u32{ 0, 1, 2, 2, 3, 0 };

        const square_ib = zine.buffer.IndexBuffer.create(allocator, &indices_square) catch unreachable;
        square_va.value.setIndexBuffer(square_ib);

        const shader = zine.Shader.create(allocator, @embedFile("vertSrc.glsl"), @embedFile("fragSrc.glsl")) catch |e| {
            switch (e) {
                zine.Shader.Error.NoMemory => log.err("No Memory for shader creation!", .{}),
                else => log.err("Failed to create shader due to: {any}", .{e}),
            }
            unreachable;
        };

        const texture_shader = zine.Shader.fromFilePath(allocator, "sandbox/assets/Shaders/texture.glsl") catch |e| {
            switch (e) {
                zine.Shader.Error.NoMemory => log.err("No Memory for shader creation!", .{}),
                else => log.err("Failed to create shader due to: {any}", .{e}),
            }
            unreachable;
        };

        const texture = zine.Texture2D.create(allocator, "sandbox/assets/Player.png") catch |err| blk: {
            log.err("Failed to load texture: {any}", .{err});
            if (@import("builtin").mode == .Debug) {
                std.debug.dumpCurrentStackTrace(null);
                std.process.abort();
            } else {
                break :blk undefined;
            }
        };
        texture.value.bind(0);

        texture_shader.value.uploadUniform("u_Texture", .{ .int = 0 });

        return ExampleLayer{
            .info = .{ .name = "Example" },
            .camera = blk: {
                var camera = zine.camera.OrthoCamera.init(-1.6, 1.6, -0.9, 0.9);
                camera.setZoom(1.5);
                break :blk camera;
            },
            .square_object = .{
                .vertex_array = square_va,
                .shader = shader,
            },
            .texture_shader = texture_shader,
            .texture = texture,
        };
    }

    pub fn deinit(self: *ExampleLayer, alloc: std.mem.Allocator) void {
        self.square_object.deinit();
        self.texture_shader.releaseWithFn(zine.Shader.deinit);
        self.texture.releaseWithFn(zine.Texture2D.deinit);

        alloc.destroy(self);
    }

    pub fn onImGuiRender(self: *ExampleLayer) void {
        if (imgui.begin("Example Layer", .{})) {
            imgui.text("Hello world coming from example", .{});
            _ = imgui.checkbox("Demo Window", .{ .v = &zine.ImGuiLayer.show_demo_window });
            _ = imgui.colorEdit4("Background", .{ .col = &self.clear_color.data, .flags = .{ .no_alpha = true } });

            _ = imgui.colorEdit4("Color 1", .{ .col = &self.color1.data, .flags = .{ .no_alpha = true } });
            _ = imgui.colorEdit4("Color 2", .{ .col = &self.color2.data, .flags = .{ .no_alpha = true } });
        }
        imgui.end();
    }

    pub fn onUpdate(self: *ExampleLayer, ts: zine.TimeStep) void {
        zine.renderCommand.setClearColor(self.clear_color);
        zine.renderCommand.clear();

        const move_vec = zine.input.getVector(.a, .d, .s, .w).norm();
        const move_speed = 1;

        const rotate_axis = zine.input.getAxis(.q, .e);
        const rotate_speed = 180;

        const zoom_axis = zine.input.getAxis(.z, .x);
        const zoom_speed = 1;

        const move = move_vec.scale(move_speed * ts.time);
        const current_pos = self.camera.getPosition();

        const rotate = rotate_speed * ts.time * rotate_axis;
        const current_rot = self.camera.getRotation();

        const zoom = zoom_speed * ts.time * zoom_axis;
        const current_zoom = self.camera.getZoom();

        self.camera.setPosition(current_pos.add(move.toVec3(0.0)));
        self.camera.setRotation(current_rot + rotate);
        self.camera.setZoom(current_zoom + zoom);
        zine.renderer.beginScene(&self.camera);

        // draw square
        self.square_object.transform = za.Mat4.fromTranslate(self.square_pos);
        const scale = za.Mat4.fromScale(za.Vec3.new(0.1, 0.1, 0.1));

        for (0..20) |y| {
            for (0..20) |x| {
                const x_float: f32 = @floatFromInt(x);
                const y_float: f32 = @floatFromInt(y);
                const pos = za.Vec3.new(x_float * 0.11, y_float * 0.11, 0.0);
                if (x % 2 == 0) {
                    self.square_object.getShader().uploadUniform("u_Color", .{ .float4 = self.color1.data });
                } else {
                    self.square_object.getShader().uploadUniform("u_Color", .{ .float4 = self.color2.data });
                }

                self.square_object.transform = za.Mat4.fromTranslate(pos).mul(scale);
                zine.renderer.submit(&self.square_object);
            }
        }

        {
            const old_shader = self.square_object.shader;

            self.square_object.shader = self.texture_shader;
            self.texture.value.bind(0);

            self.square_object.transform = za.Mat4.fromScale(za.Vec3.new(1.5, 1.5, 1.5));
            zine.renderer.submit(&self.square_object);

            self.square_object.shader = old_shader;
        }

        zine.renderer.endScene();
    }
};

inline fn errPush() noreturn {
    log.err("Unrecovable error while pushing", .{});
    std.process.abort();
}

export fn createApp() *zine.App {
    const app = zine.App.init(allocator) catch |err| switch (err) {
        error.NotInitialized,
        error.APIUnavailable,
        error.InvalidEnum,
        error.InvalidValue,
        error.VersionUnavailable,
        error.PlatformUnavailable,
        error.PlatformError,
        => std.debug.panic("Failed to init app due to glfw {any}", .{err}),
        error.OutOfMemory => std.debug.panic("Program doesn't have enough memory to init app!!!", .{}),
        else => std.debug.panic("Failed to init app due to: {any}", .{err}),
    };
    app.pushLayer(ExampleLayer.init()) catch errPush();
    return app;
}

export fn deleteApp(app: *zine.App) void {
    app.deinit();
    allocator.destroy(app);
}

pub fn main() !void {
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            log.err("Memory Leak Detected!", .{});
        }
    }
    zine.App.start();
}
