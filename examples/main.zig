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

    // probably needs to find a better way
    const timeout = 0.25 * @as(f32, std.time.ns_per_s);

    // clear screen
    try stdout.writer().print("{s}", .{clear.all});

    var app = try Terminal.init(std.testing.allocator, stdin.handle);
    defer app.deinit();

    try app.startEvents(stdin.reader());

    // this dont support resize yet
    const size = try mibu.term.getSize();
    var box = Box.init()
        .setSize(.{ .col = 0, .row = 0, .w = size.width - 1, .h = size.height - 1 })
        .setTitle(" Hello world ");

    var running = true;
    while (running) {
        // _ = try app.buffer.resize();

        // blocks thread until an event is received, or timeout is reached
        if (app.nextEventTimeout(timeout)) |event| {
            switch (event) {
                .key => |k| switch (k) {
                    .ctrlC => running = false,
                    else => {},
                },
                else => {},
            }
        }

        app.drawWidget(&box.widget);
        try app.flush(stdout.writer());
    }
}
