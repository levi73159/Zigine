const Ref = @import("../ptr.zig").Ref;
const textures = switch (@import("renderer.zig").api) {
    .None => struct {},
    .OpenGL => @import("OpenGL/texture.zig"),
    else => @compileError("Unsupported API"),
};

/// abstract texture, shoudn't be kept, only pass for refrence but then destroy in stack
pub const Texture = struct {
    const Self = @This();

    ref_tex: Ref(anyopaque).Weak,
    width: u32,
    height: u32,

    _bind: *const fn (self: anytype, slot: u32) void,
    _deinit: ?*const fn (self: anytype) void,

    pub fn bind(self: Self, slot: u32) void {
        self._bind(self.ref_tex.inner.?.value, slot);
    }

    pub fn deinit(self: Self) void {
        if (self._deinit) |di| {
            di(self.ref_tex.inner.?.value);
        }
        self.ref_tex.release();
    }
};

pub usingnamespace textures;
