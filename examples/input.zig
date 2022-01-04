const std = @import("std");

const teru = @import("teru");
const mibu = @import("mibu");

const Terminal = teru.Terminal;
const Input = teru.widget.Input;
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

    var input = Input.init()
        .setSize(.{ .col = 10, .row = 3, .w = 20, .h = 2 })
        .setTitle(" Input box ");

    var running = true;
    var text = std.ArrayList(u21).init(std.testing.allocator);
    while (running) {

        // blocks thread until an event is received, or timeout is reached
        if (app.nextEventTimeout(timeout)) |event| {
            switch (event) {
                .key => |k| switch (k) {
                    .ctrlC => running = false,
                    .char => |c| try text.append(c),
                    // same as backspace
                    .ctrlH => _ = text.popOrNull(),
                    else => {},
                },
                else => {},
            }
        }

        _ = input.setText(text.items);
        app.drawWidget(&input.widget);
        try app.flush(stdout.writer());
    }
}
