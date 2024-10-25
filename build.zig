const std = @import("std");

const test_targets = [_]std.Target.Query{
    .{}, // native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

var zigine_module: *std.Build.Module = undefined;
var zigine_lib: *std.Build.Step.Compile = undefined;

pub fn libLink(dep: *std.Build.Dependency, name: []const u8) void {
    zigine_module.linkLibrary(dep.artifact(name));
    zigine_lib.linkLibrary(dep.artifact(name));

    zigine_module.addImport(name, dep.module("root"));
    zigine_lib.root_module.addImport(name, dep.module("root"));
}

pub fn importModule(name: []const u8, dep: *std.Build.Dependency) void {
    zigine_module.addImport(name, dep.module(name));
    zigine_lib.root_module.addImport(name, dep.module(name));
}

pub fn build(b: *std.Build) void {
    // zig fmt: off
    const enable_sandbox: bool = b.option(bool, "sandbox", "Build the sandbox executable") orelse true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw_dep = b.dependency("glfw", .{
    });
    const imgui_dep = b.dependency("imgui", .{
        .shared = false,
        .with_implot = true,
        .backend = .glfw_opengl3,
    });
    const zalgebra_dep = b.dependency("zalgebra", .{
        .target = target,
        .optimize = optimize,
    });

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.6",
        .profile = .core,
    });

    zigine_module = b.addModule("zigine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    zigine_lib = b.addSharedLibrary(.{
        .name = "zigine",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize
    });

    libLink(glfw_dep, "glfw");
    libLink(imgui_dep, "imgui");

    zigine_module.addImport("gl", gl_bindings);
    zigine_lib.root_module.addImport("gl", gl_bindings);

    importModule("zalgebra", zalgebra_dep);

    const exe = b.addExecutable(.{
        .name = "sandbox",
        .root_source_file = b.path("sandbox/src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zigine", zigine_module);

    if (enable_sandbox) {
        b.installArtifact(exe);
        exe.linkLibrary(zigine_lib);

        const run_exe = b.addRunArtifact(exe);

        const run_step = b.step("run", "Run the application");
        run_step.dependOn(&run_exe.step);
    } 

    const test_step = b.step("test", "Run unit tests");
    for (test_targets) |test_target| {
        const engine_unit_tests = b.addTest(.{
            .root_source_file = b.path("src/root.zig"),
            .target = b.resolveTargetQuery(test_target),
        });
        const sandbox_unit_tests = b.addTest(.{
            .root_source_file = b.path("sandbox/src/main.zig"),
            .target = b.resolveTargetQuery(test_target),
        });

        const run_engine_test = b.addRunArtifact(engine_unit_tests);
        const run_sandbox_test = b.addRunArtifact(sandbox_unit_tests);

        test_step.dependOn(&run_engine_test.step);
        test_step.dependOn(&run_sandbox_test.step);
    }
}
