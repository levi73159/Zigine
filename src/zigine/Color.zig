/// rgba color
const std = @import("std");
const za = @import("zalgebra");

const Self = @This();

// r: f32,
// g: f32,
// b: f32,
// a: f32,
data: [4]f32,

pub fn rgb8(red: u8, green: u8, blue: u8) Self {
    return rgba8(red, green, blue, 255);
}

pub fn rgba8(red: u8, green: u8, blue: u8, alpha: u8) Self {
    const real_r = @as(f32, @floatFromInt(red)) / 255.0;
    const real_g = @as(f32, @floatFromInt(green)) / 255.0;
    const real_b = @as(f32, @floatFromInt(blue)) / 255.0;
    const real_a = @as(f32, @floatFromInt(alpha)) / 255.0;
    return Self{ .data = .{ real_r, real_g, real_b, real_a } };
}

pub fn rgb(red: f32, green: f32, blue: f32) Self {
    return Self{ .data = .{ red, green, blue, 1.0 } };
}

pub fn rgba(red: f32, green: f32, blue: f32, alpha: f32) Self {
    return Self{ .data = .{ red, green, blue, alpha } };
}

pub fn r(self: Self) f32 {
    return self.data[0];
}

pub fn rMut(self: *Self) *f32 {
    return &self.data[0];
}

pub fn r8(self: Self) u8 {
    return @as(u8, @intFromFloat(self.data[0]));
}

pub fn g(self: Self) f32 {
    return self.data[1];
}

pub fn gMut(self: *Self) *f32 {
    return &self.data[1];
}

pub fn g8(self: Self) u8 {
    return @as(u8, @intFromFloat(self.data[1]));
}

pub fn b(self: Self) f32 {
    return self.data[2];
}

pub fn bMut(self: *Self) *f32 {
    return &self.data[2];
}

pub fn b8(self: Self) u8 {
    return @as(u8, @intFromFloat(self.data[2]));
}

pub fn a(self: Self) f32 {
    return self.data[3];
}

pub fn aMut(self: *Self) *f32 {
    return &self.data[3];
}

pub fn a8(self: Self) u8 {
    return @as(u8, @intFromFloat(self.data[3]));
}

pub fn toVec4(self: Self) za.Vec4 {
    return za.Vec4.fromSlice(self.data);
}

pub fn toVec3(self: Self) za.Vec3 {
    return za.Vec3.fromSlice(self.data);
}

pub fn mul(self: Self, other: Self) Self {
    return Self{
        .r = self.r() * other.r(),
        .g = self.g() * other.g(),
        .b = self.b() * other.b(),
        .a = self.a() * other.a(),
    };
}

pub fn add(self: Self, other: Self) Self {
    return Self{
        .r = self.r() + other.r(),
        .g = self.g() + other.g(),
        .b = self.b() + other.b(),
        .a = self.a() + other.a(),
    };
}

pub fn sub(self: Self, other: Self) Self {
    return Self{
        .r = self.r() - other.r(),
        .g = self.g() - other.g(),
        .b = self.b() - other.b(),
        .a = self.a() - other.a(),
    };
}

pub fn div(self: Self, other: Self) Self {
    return Self{
        .r = self.r() / other.r(),
        .g = self.g() / other.g(),
        .b = self.b() / other.b(),
        .a = self.a() / other.a(),
    };
}

pub fn scale(self: Self, scaler: f32) Self {
    return Self{
        .r = self.r() * scaler,
        .g = self.g() * scaler,
        .b = self.b() * scaler,
        .a = self.a() * scaler,
    };
}
