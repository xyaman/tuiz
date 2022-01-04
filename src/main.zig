const std = @import("std");
const mibu = @import("mibu");

pub const widget = @import("./widget.zig");

const Queue = @import("./mpsc.zig").Queue;
pub const events = @import("events.zig");

pub const Terminal = @import("./terminal.zig").Terminal;
pub const Rect = @import("./terminal.zig").Rect;

// maybe?
pub const Buffer = @import("./terminal.zig").Buffer;

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
