const std = @import("std");
const ArrayList = std.ArrayList;

const TextStyle = @import("style.zig").TextStyle;

const mibu = @import("mibu");
const color = mibu.color;

pub const Cell = struct {
    value: u21 = ' ',
    fg: []const u8 = color.print.fg(.default),
    bg: []const u8 = color.print.bg(.default),
    style: TextStyle = .default,
};

/// Represents screen (2D)
pub const Buffer = struct {
    size: mibu.term.TermSize,

    inner: []Cell,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Inits a buffer
    pub fn init(allocator: std.mem.Allocator) Self {
        // TODO: check getSize parameter
        var size = mibu.term.getSize(std.os.STDOUT_FILENO) catch unreachable;

        var inner = allocator.alloc(Cell, size.width * size.height) catch unreachable;
        std.mem.set(Cell, inner, .{});

        return .{
            .size = size,
            .allocator = allocator,
            .inner = inner,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.inner);
    }

    // Resets the buffer inner content with empty cells
    pub fn reset(self: *Self) void {
        std.mem.set(Cell, self.inner, .{});
    }

    /// Returns a reference of a cell based on col and row.
    /// Be careful about calling this func with out of bounds col or rows.
    pub fn getRef(self: *Self, x: usize, y: usize) *Cell {
        const row = y * self.size.width;
        return &self.inner[row + x];
    }

    /// Resizes the buffer if is necesary (terminal size changed)
    /// Return true if it changed, false otherwise
    pub fn resize(self: *Self) !bool {
        // TODO: check parameter of getSize
        const new_size = try mibu.term.getSize(0);

        // size changed
        if (new_size.width != self.size.width or new_size.height != self.size.height) {
            self.size = new_size;

            var old_inner = self.inner;
            defer self.allocator.free(old_inner);

            self.inner = try self.allocator.alloc(Cell, new_size.width * new_size.height);
            self.reset();

            return true;
        }

        return false;
    }

    pub const BufDiff = struct {
        x: usize,
        y: usize,
        c: *Cell,
    };

    /// *Note*: The caller should free (deinit) the return value
    pub fn diff(self: *Self, other: *Buffer) !ArrayList(BufDiff) {
        var updates = ArrayList(BufDiff).init(self.allocator);

        var i: usize = 0;
        while (i < self.inner.len) : (i += 1) {
            if (!std.meta.eql(self.inner[i], other.inner[i])) {
                try updates.append(.{ .x = i % self.size.width, .y = i / self.size.width, .c = &other.inner[i] });
            }
        }

        return updates;
    }
};

test "refAll" {
    std.testing.refAllDecls(@This());
}
