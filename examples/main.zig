const std = @import("std");

const teru = @import("teru");
const mibu = @import("mibu");

const Terminal = teru.Terminal;
const Box = teru.widget.Box;
const events = teru.events;

const RawTerm = mibu.term.RawTerm;
const clear = mibu.clear;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();

    const timeout = 0.25 * @as(f32, std.time.ns_per_s);

    // clear screen at start
    try stdout.writer().print("{s}", .{clear.all});

    var term = try Terminal.init(std.testing.allocator, stdin.handle);
    defer term.deinit();

    try term.startEvents(stdin.reader());

    // this dont support resize yet
    var size = try mibu.term.getSize();
    var box = Box.init()
        .setSize(.{ .col = 0, .row = 0, .w = size.width - 1, .h = size.height - 1 })
        .setTitle(" Hello world ", .bold);

    var running = true;
    while (running) {

        // blocks thread until an event is received, or timeout is reached
        if (term.nextEventTimeout(timeout)) |event| {
            switch (event) {
                .key => |k| switch (k) {
                    .ctrlC => running = false,
                    else => {},
                },
                .resize => {
                    try term.resize();
                    size = try mibu.term.getSize();
                    _ = box.setSize(.{ .col = 0, .row = 0, .w = size.width - 1, .h = size.height - 1 });
                },
                else => {},
            }
        }

        term.drawWidget(&box.widget);
        try term.flush(stdout.writer());
    }
}
