const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line = @import("./helpers.zig").next_line;

pub fn part1(allocator: mem.Allocator, file_reader: anytype) !u64 {
    const input = try Input().parse(allocator, file_reader);
    defer input.deinit();

    var count: u64 = 0;

    outer: for (input.reports) |report| {
        var sign: i32 = undefined;

        for (report, 0..) |level, index| {
            if (index == 0) continue;

            const previous_level = report[index - 1];
            const step = previous_level - level;
            const difference = @abs(step);

            if (difference < 1 or difference > 3) {
                continue :outer;
            }

            if (index == 1) {
                sign = std.math.sign(step);
            } else {
                if (sign != std.math.sign(step)) {
                    continue :outer;
                }
            }
        }

        count += 1;
    }

    return count;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();

    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, 2);
}

pub fn part2(allocator: mem.Allocator, file_reader: anytype) !u64 {
    const input = try Input().parse(allocator, file_reader);
    defer input.deinit();

    return 0;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader();

    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(answer, undefined);
}

const example =
    \\ 7 6 4 2 1
    \\ 1 2 7 8 9
    \\ 9 7 6 2 1
    \\ 1 3 2 4 5
    \\ 8 6 4 4 1
    \\ 1 3 6 7 9
;

fn Input() type {
    return struct {
        const Self = @This();
        const Level = i32;
        const Report = []Level;

        reports: []Report,
        allocator: mem.Allocator,

        fn deinit(self: Self) void {
            for (self.reports) |report| {
                self.allocator.free(report);
            }
            self.allocator.free(self.reports);
        }

        fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
            var line_buffer: [1024]u8 = undefined;

            var reports = std.ArrayList(Report).init(allocator);
            while (true) {
                const maybe_line = try next_line(file_reader, &line_buffer);
                const line = maybe_line orelse break;

                var numbers = std.mem.tokenizeScalar(u8, line, ' ');
                var levels = std.ArrayList(Level).init(allocator);
                while (numbers.next()) |digits| {
                    const level = try std.fmt.parseInt(Level, digits, 10);
                    try levels.append(level);
                }

                try reports.append(try levels.toOwnedSlice());
            }

            return .{
                .allocator = allocator,
                .reports = try reports.toOwnedSlice(),
            };
        }
    };
}
