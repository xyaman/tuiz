const std = @import("std");

const Buffer = @import("../main.zig").Buffer;
const Rect = @import("../main.zig").Rect;
const Widget = @import("Widget.zig");

const Self = @This();

const single = [6]u21{ '┏', '┓', '┗', '┛', '━', '┃' };

widget: Widget = .{ .drawFn = draw, .sizeFn = size },
size: Rect = undefined,
title: ?[]const u8 = null,

pub fn init() Self {
    return .{};
}

pub fn setSize(self: *Self, r: Rect) *Self {
    self.size = r;
    return self;
}

pub fn setTitle(self: *Self, title: []const u8) *Self {
    self.title = title;
    return self;
}

pub fn draw(widget: *Widget, buf: *Buffer) void {
    var self = @fieldParentPtr(Self, "widget", widget);

    std.debug.assert(self.size.h + self.size.row < buf.size.height);
    std.debug.assert(self.size.w + self.size.col < buf.size.width);

    var row: usize = self.size.row;
    var x: usize = self.size.col;

    // borders
    buf.getRef(x, row).* = single[0];
    buf.getRef(x + self.size.w, row).* = single[1];

    buf.getRef(x, self.size.h + self.size.row).* = single[2];
    buf.getRef(x + self.size.w, self.size.h + self.size.row).* = single[3];

    row += 1;

    // vertical lines
    while (row < self.size.h + self.size.row) : (row += 1) {
        buf.getRef(x, row).* = single[5];
        buf.getRef(x + self.size.w, row).* = single[5];
    }

    // horizontal
    {
        var col: usize = self.size.col + 1;
        var y: usize = self.size.row;

        while (col < self.size.w + self.size.col) : (col += 1) {
            buf.getRef(col, y).* = single[4];
            buf.getRef(col, y + self.size.h).* = single[4];
        }
    }

    // draw title
    if (self.title) |title| {
        const start: usize = self.size.col + 1;
        var col: usize = start;
        while (col - start < title.len and col - start < self.size.w - 1) : (col += 1) {
            buf.getRef(col, self.size.row).* = title[col - start];
        }
    }
}

pub fn size(widget: *Widget) Rect {
    var self = @fieldParentPtr(Self, "widget", widget);
    return self.size;
}
