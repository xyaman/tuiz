const std = @import("std");

// utils
const Queue = @import("./mpsc.zig").Queue;

// modules
pub const events = @import("events.zig");
pub const widget = @import("./widget.zig");

pub const Buffer = @import("./buffer.zig").Buffer;
pub const Terminal = @import("./terminal.zig").Terminal;

test "refAllDecls" {
    std.testing.refAllDecls(@This());
}
