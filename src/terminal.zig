const std = @import("std");
const ArrayList = std.ArrayList;

const mibu = @import("mibu");
const cursor = mibu.cursor;
const RawTerm = mibu.term.RawTerm;

const Widget = @import("./widget.zig").Widget;
const Queue = @import("./mpsc.zig").Queue;
const Cell = @import("buffer.zig").Cell;

const events = @import("./events.zig");

/// Main structure
pub const Terminal = struct {
    allocator: std.mem.Allocator,
    raw_term: RawTerm,
    queue: Queue(mibu.events.Event),

    buffers: [2]Buffer, // one buffer is previous state
    current: usize = 0, // current buffer

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, handle: std.os.system.fd_t) !Self {
        var self = Self{
            .allocator = allocator,
            .buffers = .{ Buffer.init(allocator), Buffer.init(allocator) },
            .raw_term = try RawTerm.enableRawMode(handle, .blocking),
            .queue = Queue(mibu.events.Event).init(allocator),
        };

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.raw_term.disableRawMode() catch {};
        self.queue.deinit();

        self.buffers[0].deinit();
        self.buffers[1].deinit();
    }

    /// Spawns event queue thread
    pub fn startEvents(self: *Self, in: anytype) !void {
        try events.spawnEventsThread(in, &self.queue);
    }

    /// Blocks thread until next event
    pub fn nextEvent(self: *Self) mibu.events.Event {
        return self.queue.pop();
    }

    /// Blocks thread until next event or timeout reach
    pub fn nextEventTimeout(self: *Self, timeout: u64) ?mibu.events.Event {
        return self.queue.popTimeout(timeout);
    }

    /// Draws a widget on the screen.
    pub fn drawWidget(self: *Self, widget: *Widget) void {
        var update_buffer = &self.buffers[1 - self.current];
        widget.draw(update_buffer);
    }

    /// Flush the buffer to the screen, it should be called
    /// every time you want to update.
    pub fn flush(self: *Self, out: anytype) !void {
        const current_buffer = &self.buffers[self.current];
        const update_buffer = &self.buffers[1 - self.current];

        const updates = try current_buffer.diff(update_buffer);
        defer updates.deinit();

        // hide cursor before rendering
        try out.print("{s}", .{cursor.hide()});
        defer out.print("{s}", .{cursor.show()}) catch {};

        for (updates.items) |update| {
            try out.print("{s}{s}{u}", .{ cursor.goTo(update.x + 1, update.y + 1), update.c.*.style.s(), update.c.*.value });
        }

        // after draw change current buffers
        self.buffers[self.current].reset();
        self.current = 1 - self.current;
    }
};

/// Represents screen (2D)
pub const Buffer = struct {
    size: mibu.term.TermSize = undefined,

    inner: []Cell,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Inits a buffer
    pub fn init(allocator: std.mem.Allocator) Self {
        var size = mibu.term.getSize() catch unreachable;

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
        const new_size = try mibu.term.getSize();

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

    /// The caller should free (deinit) the return value
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

// TODO: change location
pub const Rect = struct {
    row: usize,
    col: usize,
    w: usize,
    h: usize,
};

test "refAll" {
    std.testing.refAllDecls(@This());
}
