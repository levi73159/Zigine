pub fn ReturnFunc(comptime T: type, comptime RetT: type) type {
    return union(enum) {
        const Self = @This();

        function: *const fn (arg1: T) RetT,
        method: struct {
            ptr: *anyopaque,
            method: *const fn (self: *anyopaque, arg1: T) RetT,
        },

        pub fn fromFunc(func: *const fn (arg1: T) RetT) Self {
            return Self{ .function = func };
        }

        pub fn fromMethod(ptr: *anyopaque, func: anytype) Self {
            return Self{ .method = .{
                .ptr = ptr,
                .method = @ptrCast(func),
            } };
        }

        pub fn call(self: Self, arg1: T) RetT {
            return switch (self) {
                .function => |func| func(arg1),
                .method => |method| method.method(method.ptr, arg1),
            };
        }
    };
}

pub fn Func(comptime T: type) type {
    return ReturnFunc(T, void);
}
