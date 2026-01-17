const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "test3-flecs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_command = b.addRunArtifact(exe);
    run_step.dependOn(&run_command.step);

    const zflecs_dep = b.dependency("zflecs", .{
        .target = target,
        .optimize = optimize,
    });

    const zflecs = zflecs_dep.module("root");
    const zflecs_artifact = zflecs_dep.artifact("flecs");

    exe.linkLibrary(zflecs_artifact);
    exe.root_module.addImport("zflecs", zflecs);
}
