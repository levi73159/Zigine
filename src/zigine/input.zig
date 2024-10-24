const std = @import("std");
const App = @import("App.zig");

// based on glfw keys so easy to convert

// no need for release cause if it is this will be false
pub inline fn isKeyPressed(key: Key) bool {
    const state = App.get().?.window.native.getKey(key.toGLFW());
    return state == .press or state == .repeat;
}

pub inline fn isMouseButtonPressed(btn: MouseButton) bool {
    const state = App.get().?.window.native.getMouseButton(btn.toGLFW());
    return state == .press or state == .repeat;
}

pub inline fn getMousePos() [2]f32 {
    const pos = App.get().?.window.native.getCursorPos();

    return .{ @floatCast(pos[0]), @floatCast(pos[1]) };
}

// zig fmt: off
pub inline fn getMouseX() f32 { return getMousePos()[0]; }
pub inline fn getMouseY() f32 { return getMousePos()[1]; }
// zig fmt: on

pub const Key = enum(u32) {
    unknown = 0,

    space = 32,
    apostrophe = 39,
    comma = 44,
    minus = 45,
    period = 46,
    slash = 47,
    zero = 48,
    one = 49,
    two = 50,
    three = 51,
    four = 52,
    five = 53,
    six = 54,
    seven = 55,
    eight = 56,
    nine = 57,
    semicolon = 59,
    equal = 61,
    a = 65,
    b = 66,
    c = 67,
    d = 68,
    e = 69,
    f = 70,
    g = 71,
    h = 72,
    i = 73,
    j = 74,
    k = 75,
    l = 76,
    m = 77,
    n = 78,
    o = 79,
    p = 80,
    q = 81,
    r = 82,
    s = 83,
    t = 84,
    u = 85,
    v = 86,
    w = 87,
    x = 88,
    y = 89,
    z = 90,
    left_bracket = 91,
    backslash = 92,
    right_bracket = 93,
    grave_accent = 96,
    world_1 = 161,
    world_2 = 162,

    escape = 256,
    enter = 257,
    tab = 258,
    backspace = 259,
    insert = 260,
    delete = 261,
    right = 262,
    left = 263,
    down = 264,
    up = 265,
    page_up = 266,
    page_down = 267,
    home = 268,
    end = 269,
    caps_lock = 280,
    scroll_lock = 281,
    num_lock = 282,
    print_screen = 283,
    pause = 284,
    F1 = 290,
    F2 = 291,
    F3 = 292,
    F4 = 293,
    F5 = 294,
    F6 = 295,
    F7 = 296,
    F8 = 297,
    F9 = 298,
    F10 = 299,
    F11 = 300,
    F12 = 301,
    F13 = 302,
    F14 = 303,
    F15 = 304,
    F16 = 305,
    F17 = 306,
    F18 = 307,
    F19 = 308,
    F20 = 309,
    F21 = 310,
    F22 = 311,
    F23 = 312,
    F24 = 313,
    F25 = 314,
    kp_0 = 320,
    kp_1 = 321,
    kp_2 = 322,
    kp_3 = 323,
    kp_4 = 324,
    kp_5 = 325,
    kp_6 = 326,
    kp_7 = 327,
    kp_8 = 328,
    kp_9 = 329,
    kp_decimal = 330,
    kp_divide = 331,
    kp_multiply = 332,
    kp_subtract = 333,
    kp_add = 334,
    kp_enter = 335,
    kp_equal = 336,
    left_shift = 340,
    left_control = 341,
    left_alt = 342,
    left_super = 343,
    right_shift = 344,
    right_control = 345,
    right_alt = 346,
    right_super = 347,
    menu = 348,

    // eventually these will change once we include other windowing managers so we can cast different window managers keys to this
    pub fn toGLFW(key: Key) @import("glfw").Key {
        if (key == .unknown) return .unknown; // because our unknow is 0 but glfw wants -1
        return @enumFromInt(@intFromEnum(key));
    }

    pub fn fromGLFW(key: @import("glfw").Key) Key {
        if (key == .unknown) return .unknown; // because our unknow is 0 but glfw wants -1
        return @enumFromInt(@intFromEnum(key));
    }
};

pub const MouseButton = enum(u32) {
    left = 0,
    right,
    middle,
    four,
    five,
    six,
    seven,
    eight,

    pub fn toGLFW(btn: MouseButton) @import("glfw").MouseButton {
        return @enumFromInt(@intFromEnum(btn));
    }

    pub fn fromGLFW(btn: @import("glfw").MouseButton) MouseButton {
        return @enumFromInt(@intFromEnum(btn));
    }
};
