const Style = @import("style.zig").Style;
const color = @import("mibu").color;

pub const Cell = struct {
    value: u21 = ' ',
    fg: []const u8 = color.fg(.default),
    bg: []const u8 = color.bg(.default),
    style: Style = .default,
};
