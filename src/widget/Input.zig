const std = @import("std");
const ArrayList = std.ArrayList;

const Buffer = @import("../main.zig").Buffer;
const Rect = @import("../main.zig").Rect;

const Widget = @import("Widget.zig");
const Box = @import("Box.zig");
const chars = @import("chars.zig");

const Self = @This();

widget: Widget = .{ .drawFn = draw, .sizeFn = size },
box: Box = Box.init(),
size: Rect = undefined,

title: ?[]const u8 = undefined,
text: ?[]u21 = undefined,

pub fn init() Self {
    return .{};
}

pub fn setSize(self: *Self, r: Rect) *Self {
    self.size = r;
    _ = self.box.setSize(r);
    return self;
}

pub fn setTitle(self: *Self, title: []const u8) *Self {
    _ = self.box.setTitle(title);
    return self;
}

pub fn setText(self: *Self, text: []u21) *Self {
    self.text = text;
    return self;
}

pub fn draw(widget: *Widget, buf: *Buffer) void {
    var self = @fieldParentPtr(Self, "widget", widget);
    var box = &self.box.widget;
    box.draw(buf);

    // draw text

    if (self.text) |text| {
        const initial_col = self.size.col + 1;
        var col = initial_col;
        var row = self.size.row + 1;

        while (col < initial_col + text.len) : (col += 1) {
            buf.getRef(col, row).* = text[col - initial_col];
        }
    }
}

pub fn size(widget: *Widget) Rect {
    var self = @fieldParentPtr(Self, "widget", widget);
    return self.size;
}
