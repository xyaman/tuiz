const std = @import("std");

const Buffer = @import("../main.zig").Buffer;
const Rect = @import("../main.zig").Rect;

const Widget = @This();

drawFn: fn (*Widget, *Buffer) void,
sizeFn: fn (*Widget) Rect,

pub fn draw(widget: *Widget, buffer: *Buffer) void {
    widget.drawFn(widget, buffer);
}

pub fn size(widget: *Widget) Rect {
    return widget.sizeFn(widget);
}

test "refAllDecls" {
    std.testing.refAllDecls(Widget);
}
