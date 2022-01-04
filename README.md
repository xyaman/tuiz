# teru

A Terminal User Interface (TUI) library, it uses [mibu](https://github.com/xyaman/mibu) as backend.
> Not recommended to use yet


## Example

```zig
const clear = @import("mibu").clear;
const Box = tui.widgets.Box;
const Terminal = tui.Terminal;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();

    // clear screen
    try stdout.writer().print("{s}", .{clear.all});

    var app = try Terminal.init(std.testing.allocator, stdin.handle);
    defer app.deinit();

    // start a separated events thread
    try app.startEvents(stdin.reader());

    const size = try mibu.term.getSize();
    var box = Box.init()
        .setSize(.{ .col = 0, .row = 0, .w = size.width - 1, .h = size.height - 1 })
        .setTitle(" Hello world ");

    var running = true;
    while (running) {
        // draw our widget
        app.drawWidget(&box.widget);
        try app.flush(stdout.writer());

        // blocks thread until an event is received,
        // we dont need timeout, because we only render one box
        // and it doesn't change
        if (app.nextEvent()) |event| {
            switch (event) {
                // teru uses raw termina mode, so you need to setup a way 
                // to exit app (ctrl-C) wont work by default
                .key => |k| switch (k) {
                    .ctrlC => running = false,
                    else => {},
                },
                else => {},
            }
        }

    }
}
```
![Screenshot](assets/box-ss.png?raw=true)
