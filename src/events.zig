const std = @import("std");
const io = std.io;

const Queue = @import("mpsc.zig").Queue;

const mibu = @import("mibu");
const events = mibu.events;

pub const PollTimeout = struct {
    end: i128,

    const Self = @This();

    pub fn init(timeout: i128) Self {
        return .{
            .end = std.time.nanoTimestamp() + timeout,
        };
    }

    pub fn shouldFinish(self: Self) bool {
        const now = std.time.nanoTimestamp();
        return now >= self.end;
    }
};

/// Blocks until a event is received or timeout is reached. It needs to be used
/// with `.nonblocking` raw terminal mode otherwise it will block until an event
/// is received.
pub fn poll(in: anytype, timeout: i128) !?events.Event {
    const ptout = PollTimeout.init(timeout);

    var event: events.Event = undefined;
    while (!ptout.shouldFinish()) {
        event = try events.next(in);
        // std.debug.print("event: {s}\n\r", .{event});
        switch (event) {
            .none => continue,
            else => return event,
        }
    }

    return null;
}

/// Timeout needs to be in nanoseconds
pub fn spawnEventsThread(_in: anytype, _queue: *Queue(events.Event)) !void {
    const inType = @TypeOf(_in);

    const gen = struct {
        fn eventsThread(in: inType, queue: *Queue(events.Event)) void {
            while (true) {
                const event = events.next(in) catch continue;
                queue.push(event);
            }
        }
    };
    _ = try std.Thread.spawn(.{}, gen.eventsThread, .{ _in, _queue });
}
