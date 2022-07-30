const std = @import("std");
const ArrayList = std.ArrayList;

const Buffer = @import("../main.zig").Buffer;
const Widget = @import("Widget.zig");
const Rect = Widget.Rect;
const Box = @import("Box.zig");

const TextStyle = @import("../style.zig").TextStyle;
const chars = @import("chars.zig");
const Self = @This();

const Config = struct {
    box: Box = Box.init(.{}),
    text: ?[]u21 = null,
};

box: Box,
text: ?[]u21,

pub fn init(config: Config) Self {
    return .{
        .box = config.box,
        .text = config.text,
    };
}

pub fn draw(self: *Self, buf: *Buffer) void {
    // draw box
    var box = self.box.widget();
    box.draw(buf);

    // draw text
    if (self.text) |text| {
        if (text.len == 0) return;
        const initial_col = self.box.size.col + 1;
        const initial_row = self.box.size.row + 1;

        var curr_row = initial_row;
        while (curr_row < initial_row + self.box.size.h - 1) : (curr_row += 1) {
            var curr_col = initial_col;
            const row = (curr_row - initial_row) * (self.box.size.w - 2);

            // TODO: change return. check index in while condition
            while (curr_col < initial_col + self.box.size.w - 1) : (curr_col += 1) {
                var index = curr_col - initial_col + row;
                if (index >= text.len) return;
                buf.unsafeGetRef(curr_col, curr_row).*.value = text[index];
            }
        }
    }
}

// Returns widget rect
pub fn size(self: *Self) Rect {
    return self.box.size;
}

pub fn widget(self: *Self) Widget {
    return Widget.make(self);
}
