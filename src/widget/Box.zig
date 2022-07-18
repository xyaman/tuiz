const std = @import("std");

const Buffer = @import("../main.zig").Buffer;
const Widget = @import("Widget.zig");
const Rect = Widget.Rect;

const TextStyle = @import("../style.zig").TextStyle;

const chars = @import("chars.zig");

const Self = @This();

size: Rect = .{},
title: ?[]const u8 = null,
title_style: TextStyle = .default,

pub fn init() Self {
    return .{};
}

pub fn setSize(self: *Self, r: Rect) *Self {
    self.size = r;
    return self;
}

pub fn setTitle(self: *Self, title: []const u8, style: TextStyle) *Self {
    self.title = title;
    self.title_style = style;
    return self;
}

pub fn draw(self: *Self, buf: *Buffer) void {
    // TODO: change assert to if
    std.debug.assert(self.size.h + self.size.row < buf.size.height);
    std.debug.assert(self.size.w + self.size.col < buf.size.width);

    var row: usize = self.size.row;
    var x: usize = self.size.col;

    // borders
    buf.unsafeGetRef(x, row).*.value = chars.ULCorner;
    buf.unsafeGetRef(x, row).*.value = chars.ULCorner;
    buf.unsafeGetRef(x + self.size.w, row).*.value = chars.URCorner;

    buf.unsafeGetRef(x, self.size.h + self.size.row).*.value = chars.LLCorner;
    buf.unsafeGetRef(x + self.size.w, self.size.h + self.size.row).*.value = chars.LRCorner;

    row += 1;

    // vertical lines
    while (row < self.size.h + self.size.row) : (row += 1) {
        buf.unsafeGetRef(x, row).*.value = chars.VLine;
        buf.unsafeGetRef(x + self.size.w, row).*.value = chars.VLine;
    }

    // horizontal
    {
        var col: usize = self.size.col + 1;
        var y: usize = self.size.row;

        while (col < self.size.w + self.size.col) : (col += 1) {
            buf.unsafeGetRef(col, y).*.value = chars.HLine;
            buf.unsafeGetRef(col, y + self.size.h).*.value = chars.HLine;
        }
    }

    // draw title
    if (self.title) |title| {
        const start: usize = self.size.col + 1;
        var col: usize = start;
        while (col - start < title.len and col - start < self.size.w - 1) : (col += 1) {
            var cell = buf.unsafeGetRef(col, self.size.row);
            cell.*.value = title[col - start];
            cell.*.style = self.title_style;
        }
    }
}

pub fn size(self: *Self) Rect {
    return self.size;
}

pub fn widget(self: *Self) Widget {
    return Widget.make(self);
}
