const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;

fn Input() type {
    return struct {
        const Self = @This();

        left: []u64,
        right: []u64,
        allocator: mem.Allocator,

        fn deinit(self: Self) void {
            self.allocator.free(self.left);
            self.allocator.free(self.right);
        }

        fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
            var left_list = std.ArrayList(u64).init(allocator);
            var right_list = std.ArrayList(u64).init(allocator);
            var line_buffer: [1024]u8 = undefined;

            while (true) {
                const maybe_line = try nextLine(file_reader, &line_buffer);
                const line = maybe_line orelse break;
                var numbers = std.mem.tokenizeScalar(u8, line, ' ');

                const leftDigits = numbers.next().?;
                const rightDigits = numbers.next().?;

                const left = try std.fmt.parseInt(u64, leftDigits, 10);
                try left_list.append(left);

                const right = try std.fmt.parseInt(u64, rightDigits, 10);
                try right_list.append(right);

                assert(numbers.peek() == null);
            }

            std.mem.sort(u64, left_list.items, {}, std.sort.asc(u64));
            std.mem.sort(u64, right_list.items, {}, std.sort.asc(u64));

            assert(left_list.items.len == right_list.items.len);
            const l = try left_list.toOwnedSlice();
            const r = try right_list.toOwnedSlice();
            return .{ .allocator = allocator, .left = l, .right = r };
        }
    };
}

pub fn part1(allocator: mem.Allocator, file_reader: anytype) !u64 {
    const input = try Input().parse(allocator, file_reader);
    defer input.deinit();

    var sum: u64 = 0;
    for (input.left, 0..) |left_item, index| {
        const right_item = input.right[index];
        sum += difference(u64, left_item, right_item);
    }

    return sum;
}

pub fn part2(allocator: mem.Allocator, file_reader: anytype) !u64 {
    const input = try Input().parse(allocator, file_reader);
    defer input.deinit();

    var right_counts = std.hash_map.AutoHashMap(u64, u64).init(allocator);
    defer right_counts.deinit();

    for (input.right) |right_item| {
        const result = try right_counts.getOrPut(right_item);
        const current_value = if (result.found_existing) result.value_ptr.* else 0;
        result.value_ptr.* = current_value + 1;
    }

    var sum: u64 = 0;

    for (input.left) |left_item| {
        const count = right_counts.get(left_item) orelse 0;
        sum += left_item * count;
        // std.debug.print("{d} occurs {d} times. score += {d}. new score = {d}\n", .{ left_item, count, left_item * count, sum });
    }

    return sum;
}

fn difference(comptime T: type, a: T, b: T) T {
    return if (a <= b) (b - a) else (a - b);
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}

test "part 1 example" {
    const example =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();

    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, 11);
}

test "part 2 example" {
    const example =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();

    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, 31);
}
