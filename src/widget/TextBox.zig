const std = @import("std");
const ArrayList = std.ArrayList;

const Buffer = @import("../main.zig").Buffer;
const Widget = @import("Widget.zig");
const Rect = Widget.Rect;
const Box = @import("Box.zig");

const TextStyle = @import("../style.zig").TextStyle;
const chars = @import("chars.zig");
const Self = @This();

box: Box = Box.init(),
size: Rect = undefined,

title: ?[]const u8 = null,
title_style: TextStyle = .default,

text: ?[]u21 = null,
text_overflow: bool = false,

pub fn init() Self {
    return .{};
}

pub fn setSize(self: *Self, r: Rect) *Self {
    self.size = r;
    _ = self.box.setSize(r);
    return self;
}

pub fn setTitle(self: *Self, title: []const u8, style: TextStyle) *Self {
    _ = self.box.setTitle(title, style);
    return self;
}

pub fn setText(self: *Self, text: []u21) *Self {
    self.text = text;
    return self;
}

pub fn noTextOverflow(self: *Self, overflow: bool) *Self {
    self.text_overflow = overflow;
    return self;
}

pub fn draw(self: *Self, buf: *Buffer) void {
    // draw box
    var box = self.box.widget();
    box.draw(buf);

    // draw text
    if (self.text) |text| {
        const initial_col = self.size.col + 1;
        var col = initial_col;
        var row = self.size.row + 1;

        // overflow text
        var max_length: usize = undefined;
        if (!self.text_overflow and self.size.w - 1 < text.len) {
            max_length = self.size.w - 1;
        } else {
            max_length = text.len;
        }

        while (col < initial_col + max_length) : (col += 1) {
            buf.getRef(col, row).*.value = text[col - initial_col];
        }
    }
}

// Returns widget size
pub fn size(self: *Self) Rect {
    return self.size;
}

pub fn widget(self: *Self) Widget {
    return Widget.make(self);
}
