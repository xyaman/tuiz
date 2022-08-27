const std = @import("std");

const Buffer = @import("../main.zig").Buffer;
const Widget = @import("Widget.zig");
const Rect = Widget.Rect;

const TextStyle = @import("../style.zig").TextStyle;

const chars = @import("chars.zig");

const Self = @This();

const Config = struct {
    rect: Rect = .{},
    border: bool = true,
    layout: Layout = .default,
    title: ?[]const u8 = null,
    title_style: TextStyle = .default,
};

pub const Layout = enum {
    default,
    // Use full width and height.
    // Its recommended to only use max in ONE widget. Usually the main one
    max,
};

rect: Rect,
border: bool,
layout: Layout,
title: ?[]const u8,
title_style: TextStyle,

pub fn init(config: Config) Self {
    return .{
        .rect = config.rect,
        .layout = config.layout,
        .border = config.border,
        .title = config.title,
        .title_style = config.title_style,
    };
}

pub fn draw(self: *Self, buf: *Buffer) void {
    if (self.layout == .max and buf.size_changed) {
        self.rect = .{ .row = 0, .col = 0, .w = buf.size.width - 1, .h = buf.size.height - 1 };
    }

    // TODO: change assert to if
    std.debug.assert(self.rect.h + self.rect.row < buf.size.height);
    std.debug.assert(self.rect.w + self.rect.col < buf.size.width);

    var row: usize = self.rect.row;
    var x: usize = self.rect.col;

    // borders
    if (self.border) {
        buf.unsafeGetRef(x, row).*.value = chars.ULCorner;
        buf.unsafeGetRef(x, row).*.value = chars.ULCorner;
        buf.unsafeGetRef(x + self.rect.w, row).*.value = chars.URCorner;

        buf.unsafeGetRef(x, self.rect.h + self.rect.row).*.value = chars.LLCorner;
        buf.unsafeGetRef(x + self.rect.w, self.rect.h + self.rect.row).*.value = chars.LRCorner;

        row += 1;

        // vertical lines
        while (row < self.rect.h + self.rect.row) : (row += 1) {
            buf.unsafeGetRef(x, row).*.value = chars.VLine;
            buf.unsafeGetRef(x + self.rect.w, row).*.value = chars.VLine;
        }

        // horizontal
        {
            var col: usize = self.rect.col + 1;
            var y: usize = self.rect.row;

            while (col < self.rect.w + self.rect.col) : (col += 1) {
                buf.unsafeGetRef(col, y).*.value = chars.HLine;
                buf.unsafeGetRef(col, y + self.rect.h).*.value = chars.HLine;
            }
        }
    }

    // draw title
    if (self.title) |title| {
        const start: usize = self.rect.col + 1;
        var col: usize = start;
        while (col - start < title.len and col - start < self.rect.w - 1) : (col += 1) {
            var cell = buf.unsafeGetRef(col, self.rect.row);
            cell.*.value = title[col - start];
            cell.*.style = self.title_style;
        }
    }
}

pub fn _rect(self: *Self) *Rect {
    return &self.rect;
}

pub fn widget(self: *Self) Widget {
    return Widget.make(self);
}
