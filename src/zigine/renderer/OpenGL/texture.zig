const std = @import("std");
const Allocator = std.mem.Allocator;
const gl = @import("gl");
const zimg = @import("zigimg");
const Ref = @import("../../ptr.zig").Ref;

const Texture = @import("../texture.zig").Texture;

// actual textures
pub const Texture2D = struct {
    const Self = @This();

    width: u32,
    height: u32,

    path: []const u8,
    renderer_id: u32,

    pub fn create(alloc: Allocator, path: []const u8) !Ref(Self) {
        var image = try zimg.Image.fromFilePath(alloc, path);
        defer image.deinit();

        var id: u32 = 0;
        const width: u32 = @intCast(image.width);
        const height: u32 = @intCast(image.height);

        const g_width: gl.sizei = @intCast(image.width);
        const g_height: gl.sizei = @intCast(image.height);

        const format: struct { internal: gl.@"enum", data: gl.@"enum" } = blk: {
            if (image.pixelFormat().isRgba()) {
                break :blk .{ .internal = gl.RGBA8, .data = gl.RGBA };
            } else if (image.pixelFormat().isStandardRgb()) {
                break :blk .{ .internal = gl.RGB8, .data = gl.RGB };
            }

            std.debug.panic("Unsupported image format!, path: {s}", .{path});
        };

        gl.CreateTextures(gl.TEXTURE_2D, 1, @ptrCast(&id));
        gl.TextureStorage2D(id, 1, format.internal, g_width, g_height);

        gl.TextureParameteri(id, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TextureParameteri(id, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        const image_data = image.pixels.asConstBytes();
        gl.TextureSubImage2D(id, 0, 0, 0, g_width, g_height, format.data, gl.UNSIGNED_BYTE, image_data.ptr);

        return try Ref(Self).init(alloc, Self{
            .width = width,
            .height = height,
            .path = path,
            .renderer_id = id,
        });
    }

    pub fn deinit(self: Self) void {
        gl.DeleteTextures(1, @constCast(@ptrCast(&self.renderer_id)));
    }

    pub fn bind(self: Self, slot: u32) void {
        gl.BindTextureUnit(slot, self.renderer_id);
    }

    pub fn toGenericTexture(self: Ref(Self)) Texture {
        return Texture{
            .ref_tex = self.downgrade(),
            .width = self.value.width,
            .height = self.value.height,
            ._bind = &Texture2D.bind,
            ._deinit = &Texture2D.deinit,
        };
    }
};
