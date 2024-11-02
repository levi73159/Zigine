const std = @import("std");

pub fn SharedPtr(comptime T: type) type {
    return struct {
        const Self = @This();

        ref_count: usize = 0,
        value: T,

        pub fn init(ptr: T) Self {
            return Self{
                .ref_count = 1,
                .value = ptr,
            };
        }

        pub fn initEmpty() Self {
            return Self{
                .ref_count = 0,
                .value = undefined,
            };
        }

        pub fn create(allocator: std.mem.Allocator) !*Self {
            const self = try allocator.create(Self);
            self.* = Self.initEmpty();
            return self;
        }

        // this is used to create a sharedptr from a raw pointer
        pub fn fromRaw(allocator: std.mem.Allocator, ptr: *const T) !*Self {
            const value = ptr.*;
            allocator.destroy(ptr);
            const self = try allocator.create(Self);
            self.* = Self.init(value);
            return self;
        }

        pub fn createAndInit(allocator: std.mem.Allocator, value: T) !*Self {
            const self = try allocator.create(Self);
            self.* = Self.init(value);
            return self;
        }

        pub fn canDestroy(self: *const Self) bool {
            return self.ref_count == 0;
        }

        pub fn get(self: *const Self) T {
            return self.value;
        }

        pub fn getPtr(self: *const Self) *T {
            return &self.value;
        }

        pub fn clone(self: *const Self) *Self {
            self.inc();
            return @constCast(self);
        }

        /// actually destroy the sharedptr object in memory, decereamt ref count and destroy if ref count is 0
        pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
            self.dec();
            if (self.ref_count == 0) {
                allocator.destroy(self);
            }
        }

        /// This function will destroy and deinit the obejct by calling the deint function (must have)
        pub fn destroyAndDeinit(self: *const Self, allocator: std.mem.Allocator) void {
            if (!@hasDecl(T, "deinit"))
                @compileError("T must have a deinit function");

            if (self.decAndCheck()) {
                // just in case the deinit function is not const (which is valid)
                const mutable_self = @constCast(self);
                mutable_self.value.deinit();
                allocator.destroy(self);
            }
        }

        pub fn inc(self: *const Self) void {
            const self_ptr: *Self = @constCast(self);
            self_ptr.ref_count += 1;
        }

        pub fn dec(self: *const Self) void {
            const self_ptr: *Self = @constCast(self);
            self_ptr.ref_count -= 1;
        }

        pub fn decAndCheck(self: *const Self) bool {
            self.dec();
            return self.ref_count == 0;
        }
    };
}
