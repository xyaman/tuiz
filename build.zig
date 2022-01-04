const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("teru", "src/main.zig");
    lib.setBuildMode(mode);
    deps.addAllTo(lib);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    deps.addAllTo(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    // main
    const main_ex = b.addExecutable("example", "examples/main.zig");
    main_ex.setTarget(target);
    deps.addAllTo(main_ex);

    const main_ex_step = b.step("example", "Run main_ex example");
    main_ex_step.dependOn(&main_ex.run().step);

    // input
    const input_ex = b.addExecutable("example", "examples/input.zig");
    input_ex.setTarget(target);
    deps.addAllTo(input_ex);

    const input_ex_step = b.step("input", "Run input_ex example");
    input_ex_step.dependOn(&input_ex.run().step);
}
