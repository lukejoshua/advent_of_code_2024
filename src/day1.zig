const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;

pub fn solution(allocator: mem.Allocator, file_reader: anytype) !u64 {
    var left_list = std.ArrayList(u64).init(allocator);
    defer left_list.deinit();

    var right_list = std.ArrayList(u64).init(allocator);
    defer right_list.deinit();

    var line_buffer: [1024]u8 = undefined;
    while (true) {
        const maybe_line = try nextLine(file_reader, &line_buffer);
        if (maybe_line) |line| {
            var numbers = std.mem.tokenizeScalar(u8, line, ' ');

            const leftDigits = numbers.next().?;
            const left = try std.fmt.parseInt(u64, leftDigits, 10);
            try left_list.append(left);

            const rightDigits = numbers.next().?;
            const right = try std.fmt.parseInt(u64, rightDigits, 10);
            try right_list.append(right);

            assert(numbers.peek() == null);
        } else {
            break;
        }
    }

    std.mem.sort(u64, left_list.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, right_list.items, {}, std.sort.asc(u64));

    assert(left_list.items.len == right_list.items.len);

    var sum: u64 = 0;
    var index: usize = 0;
    for (left_list.items) |left_item| {
        const right_item = right_list.items[index];
        sum += difference(u64, left_item, right_item);
        index += 1;
    }

    return sum;
}

fn difference(comptime T: type, a: T, b: T) T {
    if (a <= b) {
        return b - a;
    } else return a - b;
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

test "example" {
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

    const answer = try solution(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, 11);
}
