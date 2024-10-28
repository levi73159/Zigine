const std = @import("std");

pub const RendererAPI = enum(u8) {
    None = 0,
    OpenGL = 1,
    // more to come
    _,
};

pub const api: RendererAPI = .OpenGL;
