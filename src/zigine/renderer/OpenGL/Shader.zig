const std = @import("std");
const gl = @import("gl");
const za = @import("zalgebra");
const ShaderDataType = @import("../shader.zig").ShaderDataType;
const Ref = @import("../../ptr.zig").Ref;

const log = std.log.scoped(.OpenGL);

const Self = @This();

renderer_id: u32 = 0,

pub const Error = error{
    CompileError,
    LinkError,
    NoMemory,
};

pub const UnifromType = union(ShaderDataType) {
    none: void,
    float: f32,
    float2: [2]f32, // or should it be za.Vec2
    float3: [3]f32,
    float4: [4]f32,
    mat3: [3][3]f32,
    mat4: [4][4]f32,
    int: i32,
    int2: [2]i32,
    int3: [3]i32,
    int4: [4]i32,
    bool: bool,

    fn set(self: UnifromType, location: i32) void {
        if (location == -1) return;
        switch (self) {
            .none => return,
            .float => |f| gl.Uniform1f(location, f),
            .float2 => |f| gl.Uniform2f(location, f[0], f[1]),
            .float3 => |f| gl.Uniform3f(location, f[0], f[1], f[2]),
            .float4 => |f| gl.Uniform4f(location, f[0], f[1], f[2], f[3]),
            .int => |i| gl.Uniform1i(location, i),
            .int2 => |i| gl.Uniform2i(location, i[0], i[1]),
            .int3 => |i| gl.Uniform3i(location, i[0], i[1], i[2]),
            .int4 => |i| gl.Uniform4i(location, i[0], i[1], i[2], i[3]),
            .bool => |b| gl.Uniform1i(location, @intFromBool(b)),
            .mat3 => |m| gl.UniformMatrix3fv(location, 1, gl.FALSE, &m[0][0]),
            .mat4 => |m| gl.UniformMatrix4fv(location, 1, gl.FALSE, &m[0][0]),
        }
    }
};

fn printInfoLog(allocator: std.mem.Allocator, comptime format: []const u8, @"type": ShaderType, shader_id: u32) void {
    const max_length: i32 = blk: {
        var max_length: i32 = 0;
        gl.GetShaderiv(shader_id, gl.INFO_LOG_LENGTH, &max_length);
        break :blk max_length;
    };

    var message = allocator.alloc(u8, @intCast(max_length)) catch unreachable;
    defer allocator.free(message);

    var len: i32 = 0;
    gl.GetShaderInfoLog(shader_id, max_length, &len, message.ptr);
    log.err(format, .{@tagName(@"type")});
    log.err("{s}", .{message[0..@intCast(len)]});
}

const ShaderType = enum {
    vertex,
    fragment,
    fn toGL(self: ShaderType) gl.@"enum" {
        return switch (self) {
            .vertex => gl.VERTEX_SHADER,
            .fragment => gl.FRAGMENT_SHADER,
        };
    }
};

const SourceMap = std.EnumMap(ShaderType, ?[]const u8);

pub fn create(allocator: std.mem.Allocator, vertexSrc: []const u8, fragmentSrc: []const u8) Error!Ref(Self) {
    const ref = Ref(Self).init(allocator, Self{}) catch return error.NoMemory;
    const self = ref.value;

    var sources = SourceMap.initFullWith(.{
        .vertex = vertexSrc,
        .fragment = fragmentSrc,
    });

    self.renderer_id = try compile(allocator, &sources);
    return ref;
}

pub fn fromFilePath(alloc: std.mem.Allocator, file_path: []const u8) !Ref(Self) {
    // open a file and read the bytes
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var aa = std.heap.ArenaAllocator.init(alloc);
    defer aa.deinit();

    const allocator = aa.allocator();

    const read_buf = try file.readToEndAlloc(allocator, 2048 * 2048);

    var sources = try preProcess(allocator, read_buf);
    std.debug.print("--------vertex----------\n{s}\n", .{sources.get(.vertex).?.?});
    std.debug.print("--------fragment--------\n{s}\n", .{sources.get(.fragment).?.?});

    const renderer_id = try compile(allocator, &sources);

    return Ref(Self).init(alloc, Self{ .renderer_id = renderer_id }) catch return error.NoMemory;
}

fn preProcess(alloc: std.mem.Allocator, buffer: []const u8) error{SyntaxError}!SourceMap {
    var sources = SourceMap.initFull(null);

    var current_type: ?ShaderType = null;
    var start: usize = 0;
    var global_version: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.trim(u8, line, &std.ascii.whitespace).len == 0) continue;

        if (line[0] != '#') continue;

        var words = std.mem.tokenizeAny(u8, line[1..], " \t");
        const op = words.next() orelse {
            log.err("Syntax Error: Expected operator, found null instead", .{});
            return error.SyntaxError;
        };

        if (std.mem.eql(u8, op, "type")) {
            const type_str = words.next() orelse {
                log.err("Syntax Error: Expected type (etc: vertex, fragment), found null instead", .{});
                return error.SyntaxError;
            };

            // before we set the type we gotta add the source if we already have a type set
            const line_index = lines.index.?;
            if (current_type) |t| {
                sources.put(t, buffer[start .. line_index - line.len - 1]);
            }

            start = line_index;
            inline for (@typeInfo(ShaderType).Enum.fields) |field| {
                if (std.mem.eql(u8, type_str, field.name)) {
                    current_type = @enumFromInt(field.value);
                    break;
                }
            }
        } else if (std.mem.eql(u8, op, "global_version")) {
            global_version = words.rest();
            if (global_version.?.len == 0) {
                log.err("Syntax Error: Expected version string, found null instead", .{});
                return error.SyntaxError;
            }
        }
    }

    if (current_type) |t| {
        sources.put(t, buffer[start..]);
    }

    // append the global version to each source that doesn't have one
    if (global_version) |v| {
        for (sources.values, 0..) |src, i| {
            if (src == null) continue;
            if (std.mem.indexOf(u8, src.?, "#version") != null) continue;
            sources.values[i] = std.fmt.allocPrint(alloc, "#version {s}\n{s}", .{ v, src.? }) catch unreachable;
        }
    }

    return sources;
}

fn compile(allocator: std.mem.Allocator, sources: *SourceMap) Error!u32 {
    // loop over the sources and create the shaders
    const program = gl.CreateProgram();
    errdefer gl.DeleteProgram(program);

    var it = sources.iterator();
    var shaders = std.EnumMap(ShaderType, u32){};
    while (it.next()) |entry| {
        if (entry.value.* == null) continue;

        const shader_type = entry.key;
        const src = entry.value.*.?;

        const shader_id = gl.CreateShader(shader_type.toGL());
        errdefer gl.DeleteShader(shader_id);

        gl.ShaderSource(shader_id, 1, @ptrCast(&src), &.{@intCast(src.len)});

        var is_compiled: i32 = 0;
        gl.CompileShader(shader_id);

        gl.GetShaderiv(shader_id, gl.COMPILE_STATUS, &is_compiled);
        if (is_compiled == gl.FALSE) {
            printInfoLog(allocator, "Error compiling {s} shader", shader_type, shader_id);
            return error.CompileError;
        }

        gl.AttachShader(program, shader_id);
        shaders.put(shader_type, shader_id);
    }
    gl.LinkProgram(program);
    errdefer for (shaders.values) |shader_id| {
        gl.DeleteShader(shader_id);
    };

    const is_linked: i32 = blk: {
        var is_linked: i32 = 0;
        gl.GetProgramiv(program, gl.LINK_STATUS, &is_linked);
        break :blk is_linked;
    };

    if (is_linked == gl.FALSE) {
        var max_length: i32 = blk: {
            var max_length: i32 = 0;
            gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, &max_length);
            break :blk max_length;
        };

        var error_message = allocator.alloc(u8, @intCast(max_length)) catch unreachable;
        gl.GetProgramInfoLog(program, max_length, &max_length, error_message.ptr);
        log.err("Error linking program: {s}", .{error_message[0..@intCast(max_length)]});

        return error.LinkError;
    }

    for (shaders.values) |shader_id| {
        gl.DetachShader(program, shader_id);
    }
    return program;
}

pub fn deinit(self: Self) void {
    gl.DeleteProgram(self.renderer_id);
}

pub fn uploadUniform(self: Self, name: [:0]const u8, value: UnifromType) void {
    const location = gl.GetUniformLocation(self.renderer_id, name.ptr);
    if (location == -1) {
        log.warn("Unifrom doesn't exist: {s}", .{name});
        return;
    }
    value.set(location);
}

pub fn bind(self: Self) void {
    gl.UseProgram(self.renderer_id);
}

pub fn unbind() void {
    gl.UseProgram(0);
}
