const std = @import("std");
const style = @import("mibu").style;

pub const TextStyle = enum {
    default,
    bold,
    italic,

    pub fn s(self: @This()) []const u8 {
        return switch (self) {
            .default => style.print.reset,
            .bold => style.print.bold,
            .italic => style.print.italic,
        };
    }
};
