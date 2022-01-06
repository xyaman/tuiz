const std = @import("std");
const style = @import("mibu").style;

pub const Style = enum {
    default,
    bold,
    italic,

    pub fn s(self: @This()) []const u8 {
        return switch (self) {
            .default => style.reset,
            .bold => style.bold,
            .italic => style.italic,
        };
    }
};
