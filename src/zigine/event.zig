const std = @import("std");

// macro function
fn bit(comptime shift: u32) u32 {
    return 1 << shift; // shifts one to left `shift` time
}

pub const EventCategory = enum(u16) {
    none = 0,
    application = bit(0),
    input = bit(1),
    keyboard = bit(2),
    mouse = bit(3),
    mouse_btn = bit(4),

    pub fn inCategory(self: []const EventCategory, other: EventCategory) bool {
        // convert eventcategory to flags
        const flags: u16 = blk: {
            var result: u16 = 0;
            for (self) |category| {
                result += @intFromEnum(category);
            }
            break :blk result;
        };
        return (flags & @intFromEnum(other)) != 0;
    }
};

pub const EventDispatcher = struct {
    const EventFn = *const fn (event: *Event) bool;
    event: *Event,

    pub fn init(event: *Event) EventDispatcher {
        return .{ .event = event };
    }

    pub fn dispatch(self: *const EventDispatcher, event_func: EventFn) bool {
        self.event.handled = event_func(self.event);
    }
};

pub const EventData = union(enum) {
    none: void,
    key_pressed: ButtonDataRepeat,
    key_released: ButtonData,
    mouse_moved: VectorData,
    mouse_scrolled: VectorData,
    mouse_button_pressed: ButtonData,
    mouse_button_released: ButtonData,
    window_resize: VectorData,
    window_close: void,
    window_focus: void,
    window_lost_focus: void,
    app_tick: void,
    app_update: void,
    app_render: void,

    pub fn getStringBuf(self: EventData, buf: []u8) std.fmt.BufPrintError![]const u8 {
        return switch (self) {
            .key_released, .mouse_button_pressed, .mouse_button_released => |btn| std.fmt.bufPrint(buf, "{s}: button={}", .{ @tagName(self), btn.button }),
            .key_pressed => |btn| std.fmt.bufPrint(buf, "{s}: button={}, repeated={}", .{ @tagName(self), btn.button, btn.repeat_count }),
            .mouse_moved, .mouse_scrolled, .window_resize => |vec| std.fmt.bufPrint(buf, "{s}: x={d}, y={d}", .{ @tagName(self), vec.x, vec.y }),
            else => std.fmt.bufPrint(buf, "{s}", .{@tagName(self)}),
        };
    }
};

pub const EventType = std.meta.Tag(EventData);

// abstract struct
pub const Event = struct {
    handled: bool = false,
    data: EventData,
    categorys: [3]EventCategory, // an event is only allowed to have to categorys

    fn getCategorys(data: EventData) [3]EventCategory {
        return switch (data) {
            .none => .{ EventCategory.none, EventCategory.none, EventCategory.none },
            .key_pressed, .key_released => .{ EventCategory.keyboard, EventCategory.input, EventCategory.none },
            .mouse_moved, .mouse_scrolled => .{ EventCategory.mouse, EventCategory.input, EventCategory.none },
            .mouse_button_pressed, .mouse_button_released => .{ EventCategory.mouse, EventCategory.mouse_btn, EventCategory.input },
            .window_resize, .window_close, .window_focus, .window_lost_focus, .app_tick, .app_update, .app_render => .{ EventCategory.application, EventCategory.none, EventCategory.none },
        };
    }

    pub fn inCategory(self: Event, category: EventCategory) bool {
        return EventCategory.inCategory(self.categorys, category);
    }

    pub fn init(data: EventData) Event {
        return Event{
            .data = data,
            .categorys = getCategorys(data),
        };
    }
};

pub const ButtonData = packed struct { button: i32 };
pub const ButtonDataRepeat = packed struct { button: i32, repeat_count: u32 };
pub const VectorData = packed struct { x: f32, y: f32 };
