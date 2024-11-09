//! this file is static and should be included to the user always, usefull for time stuff
const TimeStep = @import("TimeStep.zig");

var delta_time: f32 = 0.0;
var ts: TimeStep = TimeStep{};

pub fn updateTime(step: TimeStep) void {
    delta_time = step.getSeconds();
    ts = step;
}

pub inline fn deltaTime() f32 {
    return delta_time;
}

pub inline fn timeStep() TimeStep {
    return ts;
}
