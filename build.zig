const std = @import("std");

const test_targets = [_]std.Target.Query{
    .{}, // native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

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

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.6",
        .profile = .core,
    });

    const zigine_module = b.addModule("zigine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zigine_lib = b.addSharedLibrary(.{
        .name = "zigine",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize
    });
    zigine_module.linkLibrary(glfw_dep.artifact("glfw"));
    zigine_lib.linkLibrary(glfw_dep.artifact("glfw"));

    zigine_module.linkLibrary(imgui_dep.artifact("imgui"));
    zigine_lib.linkLibrary(imgui_dep.artifact("imgui"));

    zigine_module.addImport("glfw", glfw_dep.module("root"));
    zigine_lib.root_module.addImport("glfw", glfw_dep.module("root"));

    zigine_module.addImport("imgui", imgui_dep.module("root"));
    zigine_lib.root_module.addImport("imgui", imgui_dep.module("root"));

    zigine_module.addImport("gl", gl_bindings);
    zigine_lib.root_module.addImport("gl", gl_bindings);

    const exe = b.addExecutable(.{
        .name = "sandbox",
        .root_source_file = b.path("sandbox/src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibrary(glfw_dep.artifact("glfw"));
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
