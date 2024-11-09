//! this file should never be included by the user, it's only used internally in the engine
//! and should not be exposed to the user in any way or form possible
//!
//! Question: should we make it a f64? or keep it f32?
const std = @import("std");

const Self = @This();

time: f32 = 0.0,

pub inline fn getSeconds(self: Self) f32 {
    return self.time;
}

pub inline fn getMilliseconds(self: Self) f32 {
    return self.time * 1000.0;
}
