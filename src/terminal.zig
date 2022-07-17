const std = @import("std");
const os = std.os;

const mibu = @import("mibu");
const cursor = mibu.cursor;
const clear = mibu.clear;
const term = mibu.term;

const Buffer = @import("buffer.zig").Buffer;
const Widget = @import("./widget.zig").Widget;
const Queue = @import("./mpsc.zig").Queue;
const Cell = @import("buffer.zig").Cell;

const events = @import("./events.zig");

/// Main structure
pub const Terminal = struct {
    allocator: std.mem.Allocator,
    raw_term: term.RawTerm,
    queue: Queue(mibu.events.Event),

    buffers: [2]Buffer, // one buffer is previous state
    current: u2 = 0, // current buffer index (0 or 1)

    needs_clean: bool = false,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, handle: std.os.system.fd_t) !Self {
        var self = Self{
            .allocator = allocator,
            .buffers = .{ Buffer.init(allocator), Buffer.init(allocator) },
            .raw_term = try term.enableRawMode(handle, .blocking),
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

    /// Resize screen buffer, useful when terminal size changes
    pub fn resize(self: *Self) !void {
        for (self.buffers) |*buffer| {
            _ = try buffer.resize();
        }
        // This will force to clean screen in next render, otherwise we may
        // experience visual bugs
        self.needs_clean = true;
    }

    /// Spawns event queue thread
    pub fn startEvents(self: *Self, in: anytype) !void {
        try events.spawnEventsThread(in, &self.queue);

        // Resize event (SIGWINCH)
        const gen = struct {
            pub threadlocal var _self: *Self = undefined;
            fn handleSigWinch(_: c_int) callconv(.C) void {
                _self.queue.push(.resize);
            }
        };

        gen._self = self;

        try os.sigaction(os.SIG.WINCH, &os.Sigaction{
            .handler = .{ .handler = gen.handleSigWinch },
            .mask = os.empty_sigset,
            .flags = 0,
        }, null);
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
    /// Technically, writes a widget in the buffer. Flush will draw the changes
    /// in the buffer.
    pub fn drawWidget(self: *Self, widget: Widget) void {
        var not_current_buffer = &self.buffers[1 - self.current];
        widget.draw(not_current_buffer);
    }

    /// Flush the buffer to the screen, it should be called
    /// every time you want to update.
    pub fn flush(self: *Self, out: anytype) !void {
        // clear screen is only needed when buffer is resized
        if (self.needs_clean) {
            try out.print("{s}", .{clear.print.all});
            self.needs_clean = false;
        }

        const current_buffer = &self.buffers[self.current];
        const update_buffer = &self.buffers[1 - self.current];

        const updates = try current_buffer.diff(update_buffer);
        defer updates.deinit();

        // hide cursor before rendering
        try out.print("{s}", .{cursor.print.hide()});
        defer out.print("{s}", .{cursor.print.show()}) catch {};

        for (updates.items) |update| {
            try out.print("{s}{s}{u}", .{ cursor.print.goTo(update.x + 1, update.y + 1), update.c.*.style.s(), update.c.*.value });
        }

        // after draw change current buffers
        self.buffers[self.current].reset();
        self.current = 1 - self.current;
    }
};

test "refAll" {
    std.testing.refAllDecls(@This());
}
