const std = @import("std");

const tuiz = @import("tuiz");
const mibu = @import("mibu");

const Terminal = tuiz.Terminal;
const Box = tuiz.widget.Box;
const events = tuiz.events;

const RawTerm = mibu.term.RawTerm;
const clear = mibu.clear;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();

    // clear screen at start
    try stdout.writer().print("{s}", .{clear.print.all});

    var allocator_state = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_state.allocator();
    defer {
        _ = allocator_state.deinit();
    }

    var term = try Terminal.init(allocator, stdin.handle);
    term.deinit();

    // No autolayout yet
    var size = try mibu.term.getSize(0);
    var box = Box.init(.{
        .rect = .{ .col = 0, .row = 0, .w = size.width - 1, .h = size.height - 1 },
        .title = " Hello World ",
        .title_style = .bold,
    });

    // refresh every 0.25 seconds
    const timeout = 0.25 * @as(f32, std.time.ns_per_s);

    // start reading events
    try term.startEvents(stdin.reader());
    var running = true;
    while (running) {

        // blocks thread until an event is received, or timeout is reached
        if (term.nextEventTimeout(timeout)) |event| {
            switch (event) {
                // exit when pressing ctrl-c
                .key => |k| switch (k) {
                    .ctrl => |c| switch (c) {
                        'c' => running = false,
                        else => {},
                    },
                    else => {},
                },
                .resize => {
                    try term.resize();
                    size = try mibu.term.getSize(0);
                    box.rect = .{ .col = 0, .row = 0, .w = size.width - 1, .h = size.height - 1 };
                },
                else => {},
            }
        }

        // draw widget in the buffer
        term.drawWidget(box.widget());

        // make changes visible
        try term.flush(stdout.writer());
    }
}
