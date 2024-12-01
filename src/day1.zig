const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line = @import("./helpers.zig").next_line;

pub fn part1(allocator: mem.Allocator, file_reader: anytype) !u64 {
    const input = try Input().parse(allocator, file_reader);
    defer input.deinit();

    var sum: u64 = 0;
    for (input.left, 0..) |left_item, index| {
        const right_item = input.right[index];

        sum += left_item.difference_from(right_item);
    }

    return sum;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();

    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, 11);
}

pub fn part2(allocator: mem.Allocator, file_reader: anytype) !u64 {
    const input = try Input().parse(allocator, file_reader);
    defer input.deinit();

    var right_counts = std.hash_map.AutoHashMap(LocationID, u64).init(allocator);
    defer right_counts.deinit();

    for (input.right) |right_item| {
        const result = try right_counts.getOrPut(right_item);
        const current_value = if (result.found_existing) result.value_ptr.* else 0;
        result.value_ptr.* = current_value + 1;
    }

    var sum: u64 = 0;

    for (input.left) |left_item| {
        const count = right_counts.get(left_item) orelse 0;
        sum += left_item.multiply_by(count);
    }

    return sum;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();

    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, 31);
}

const example =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

const LocationID = enum(u64) {
    const Self = @This();

    _,

    fn difference_from(self: Self, other: Self) u64 {
        const a = @intFromEnum(self);
        const b = @intFromEnum(other);
        return if (a < b) b - a else a - b;
    }

    fn multiply_by(self: Self, count: u64) u64 {
        return @intFromEnum(self) * count;
    }

    fn less_than(_: void, a: Self, b: Self) bool {
        return @intFromEnum(a) < @intFromEnum(b);
    }
};

fn Input() type {
    return struct {
        const Self = @This();

        left: []LocationID,
        right: []LocationID,
        allocator: mem.Allocator,

        fn deinit(self: Self) void {
            self.allocator.free(self.left);
            self.allocator.free(self.right);
        }

        fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
            var left_list = std.ArrayList(LocationID).init(allocator);
            var right_list = std.ArrayList(LocationID).init(allocator);
            var line_buffer: [128]u8 = undefined;

            while (true) {
                const maybe_line = try next_line(file_reader, &line_buffer);
                const line = maybe_line orelse break;

                var numbers = std.mem.tokenizeScalar(u8, line, ' ');
                const leftDigits = numbers.next().?;
                const rightDigits = numbers.next().?;
                assert(numbers.peek() == null);

                const left = try std.fmt.parseInt(u64, leftDigits, 10);
                try left_list.append(@enumFromInt(left));

                const right = try std.fmt.parseInt(u64, rightDigits, 10);
                try right_list.append(@enumFromInt(right));
            }

            std.mem.sort(LocationID, left_list.items, {}, LocationID.less_than);
            std.mem.sort(LocationID, right_list.items, {}, LocationID.less_than);
            assert(left_list.items.len == right_list.items.len);

            const l = try left_list.toOwnedSlice();
            const r = try right_list.toOwnedSlice();
            return .{ .allocator = allocator, .left = l, .right = r };
        }
    };
}
