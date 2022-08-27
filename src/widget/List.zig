const Widget = @import("Widget.zig");
const Rect = Widget.Rect;

const Buffer = @import("../main.zig").Buffer;
const Box = @import("Box.zig");

const Self = @This();

pub const Item = struct {
    text: []const u8,
};

const Config = struct {
    box: Box = Box.init(.{}),
};

box: Box,
items: []Item,
selected: usize,
hide_overflow: bool,

pub fn init(config: Config) Self {
    return .{
        .box = config.box,
    };
}

pub fn draw(self: *Self, buf: *Buffer) void {
    var box = self.box.widget();
    box.draw(buf);
}

pub fn _rect(self: *Self) *Rect {
    return &self.box.rect;
}

pub fn widget(self: *Self) Widget {
    return Widget.make(self);
}
