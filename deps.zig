const std = @import("std");
pub const pkgs = struct {
    pub const mibu = std.build.Pkg{
        .name = "mibu",
        .source = .{ .path = "lib/mibu/src/main.zig" },
    };

    pub const tuiz = std.build.Pkg{
        .name = "tuiz",
        .source = .{ .path = "src/main.zig" },
        .dependencies = &[_]std.build.Pkg{
            std.build.Pkg{
                .name = "mibu",
                .source = .{ .path = "lib/mibu/src/main.zig" },
            },
        },
    };

    pub const all = [_]std.build.Pkg{
        pkgs.mibu,
        pkgs.tuiz,
    };

    pub fn addAllTo(artifact: *std.build.LibExeObjStep) void {
        inline for (all) |pkg| {
            artifact.addPackage(pkg);
        }
    }
};
