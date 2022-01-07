const std = @import("std");
const Atomic = std.atomic.Atomic;

/// Multiple-Producer single-consumer struct.
/// It's safe to send between threads, but only one
/// thread should call pop()
pub fn Queue(comptime T: type) type {
    return struct {
        pub const Node = struct {
            next: Atomic(?*Node) = Atomic(?*Node).init(null),
            value: T = undefined,
        };

        allocator: std.mem.Allocator,
        count: Atomic(usize) = Atomic(usize).init(0),
        ptr: Atomic(u32) = Atomic(u32).init(1),

        head: Atomic(?*Node) = Atomic(?*Node).init(null),
        tail: *Node = undefined,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            var node = allocator.create(Node) catch unreachable;

            return .{
                .allocator = allocator,
                .head = Atomic(?*Node).init(node),
                .tail = node,
            };
        }

        pub fn deinit(self: *Self) void {
            // free all items
            while (self.tryPop()) |_| {}
            self.allocator.destroy(self.tail);
        }

        pub fn len(self: *Self) usize {
            return self.count.load(.Acquire);
        }

        /// Push a new value to the queue, its safe to call from any thread,
        /// it doesn't block thread either.
        pub fn push(self: *Self, v: T) void {
            var new_node = self.allocator.create(Node) catch unreachable;
            new_node.* = .{ .value = v };

            // swap self.head with new_node
            var prev = self.head.swap(new_node, .AcqRel) orelse self.tail;

            // save new_node(pointer) on previous node
            // so now prev.next -> new_node
            prev.next.store(new_node, .Release);

            // increase internal count
            _ = self.count.fetchAdd(1, .Monotonic);

            std.Thread.Futex.wake(&self.ptr, 1);
        }

        /// Tries to pops some value from queue, returns null if there are no values. 
        /// Should be called only from one thread. It doesn't block the thread.
        pub fn tryPop(self: *Self) ?T {
            if (self.count.load(.Acquire) < 1) {
                return null;
            }

            var tail = self.tail;
            var next = self.tail.next.load(.Acquire);

            if (next) |next_nonnull| {
                self.tail = next_nonnull;

                var ret = next_nonnull.value;
                self.allocator.destroy(tail);
                // decrease internal count
                _ = self.count.fetchSub(1, .Monotonic);
                return ret;
            }

            return null;
        }

        /// Pops some value from queue, blocks until receives a value,
        /// Should be called only from one thread. 
        pub fn pop(self: *Self) T {
            if (self.tryPop()) |v| {
                return v;
            }

            // wait
            std.Thread.Futex.wait(&self.ptr, 1, null) catch {};
            return self.tryPop().?;
        }

        /// Pops some value from queue, blocks until receives a value,
        /// or timeout is reached. Should be called only from one thread. 
        pub fn popTimeout(self: *Self, timeout: u64) ?T {
            if (self.tryPop()) |v| {
                return v;
            }

            // wait, if there is timeout error, return null
            std.Thread.Futex.wait(&self.ptr, 1, timeout) catch {
                return null;
            };

            return self.tryPop();
        }
    };
}

test "mpsc" {
    const TestQueue = Queue(usize);
    var queue = TestQueue.init(std.testing.allocator);
    defer queue.deinit();

    queue.push(5);
    queue.push(5);
    queue.push(5);
    var v = queue.tryPop();
    try std.testing.expect(v.? == 5);
}
