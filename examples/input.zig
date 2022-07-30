const std = @import("std");

const teru = @import("teru");
const mibu = @import("mibu");

const Terminal = teru.Terminal;
const TextBox = teru.widget.TextBox;
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
    try clear.all(stdout.writer());

    var app = try Terminal.init(std.testing.allocator, stdin.handle);
    defer app.deinit();

    try app.startEvents(stdin.reader());

    var input = TextBox.init(.{
        .box = Box.init(.{
            .size = .{ .col = 10, .row = 3, .w = 20, .h = 4 },
            .title = " Input ",
        }),
    });

    var running = true;
    var text = std.ArrayList(u21).init(std.testing.allocator);
    while (running) {

        // blocks thread until an event is received, or timeout is reached
        if (app.nextEventTimeout(timeout)) |event| {
            switch (event) {
                .key => |k| switch (k) {
                    .ctrl => |c| switch (c) {
                        'c' => running = false,
                        else => {},
                    },
                    .char => |c| try text.append(c),
                    .delete => _ = text.popOrNull(),
                    else => {},
                },
                else => {},
            }
        }

        input.text = text.items;
        app.drawWidget(input.widget());
        try app.flush(stdout.writer());
    }
}
