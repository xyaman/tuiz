const Widget = @import("Widget.zig");
const Rect = Widget.Rect;

const Buffer = @import("../main.zig").Buffer;
const Box = @import("Box.zig");

pub const Children = struct {
    widget: Widget,
    factor: usize,
};

pub const Orientation = enum {
    horizontal,
    vertical,
};

const Self = @This();

box: Box = Box.init(.{}),
children: []Children,
sep: u21 = ' ',
orientation: Orientation = .horizontal,

pub fn draw(self: *Self, buf: *Buffer) void {
    var box = self.box.widget();
    box.draw(buf);

    // HStack will always use the whole height, but the width will be scaled
    // based on factor value.
    // The scaled value should always need an integer

    // get total factor
    var total_factor: usize = 0;
    for (self.children) |child| {
        total_factor += child.factor;
    }

    switch (self.orientation) {
        .horizontal => {
            const scaled = (self.box.rect.w - self.children.len) / total_factor;
            var cursor = self.box.rect.col + 1;
            for (self.children) |child| {
                child.widget.rect().* = .{
                    .w = child.factor * scaled,
                    .h = self.box.rect.h - 2,
                    .col = cursor,
                    .row = self.box.rect.row + 1,
                };

                cursor += child.factor * scaled + 1;
                child.widget.draw(buf);
            }
        },
        .vertical => {
            const scaled = (self.box.rect.h - self.children.len) / total_factor;
            var cursor = self.box.rect.row + 1;
            for (self.children) |child| {
                child.widget.rect().* = .{
                    .w = self.box.rect.w - 2,
                    .h = child.factor * scaled,
                    .col = self.box.rect.col + 1,
                    .row = cursor,
                };

                cursor += child.factor * scaled + 1;
                child.widget.draw(buf);
            }
        },
    }
}

pub fn _rect(self: *Self) *Rect {
    return &self.box.rect;
}

pub fn widget(self: *Self) Widget {
    return Widget.make(self);
}
