const std = @import("std");

const tuiz = @import("tuiz");
const mibu = @import("mibu");

const Terminal = tuiz.Terminal;
const TextBox = tuiz.widget.TextBox;
const Box = tuiz.widget.Box;
const events = tuiz.events;

const RawTerm = mibu.term.RawTerm;
const clear = mibu.clear;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();

    const timeout = 0.25 * @as(f32, std.time.ns_per_s);

    // clear screen
    try clear.all(stdout.writer());

    var allocator_state = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocator_state.allocator();
    defer {
        _ = allocator_state.deinit();
    }

    var app = try Terminal.init(allocator, stdin.handle);
    defer app.deinit();

    try app.startEvents(stdin.reader());

    var input = TextBox.init(.{
        .box = Box.init(.{
            .size = .{ .col = 10, .row = 3, .w = 20, .h = 4 },
            .title = " Input ",
        }),
    });

    var running = true;
    var text = std.ArrayList(u21).init(allocator);
    defer text.deinit();

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
    input.text = null;
}
