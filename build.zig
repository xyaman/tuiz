const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("teru", "src/main.zig");
    lib.setBuildMode(mode);
    deps.pkgs.addAllTo(lib);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    deps.pkgs.addAllTo(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    // examples
    const examples = [_][]const u8{ "box", "input" };

    for (examples) |example| {
        const exec = b.addExecutable(example, std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{example}) catch unreachable);
        exec.setTarget(target);
        deps.pkgs.addAllTo(exec);

        const exec_run = exec.run();
        const exec_step = b.step(example, std.fmt.allocPrint(b.allocator, "Run example: {s}", .{example}) catch unreachable);
        exec_step.dependOn(&exec_run.step);
    }
}
