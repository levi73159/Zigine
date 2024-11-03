//! this file will be used to select the graphics api
//! currently only opengl is supported
//! it will also be used as an api, right now it static, but we might wanna make it an actual struct in the future
const API = enum(u8) {
    None = 0,
    OpenGL = 1,
    // more to come
    _,
};

pub const api: API = .OpenGL;

const RendererAPI = switch (api) {
    .None => struct {},
    .OpenGL => @import("OpenGL/rendererAPI.zig"),
    else => @compileError("selected API is not supported"),
};

pub usingnamespace RendererAPI;
