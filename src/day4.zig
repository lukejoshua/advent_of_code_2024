const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line_alloc = @import("./helpers.zig").next_line_alloc;

pub fn part1(allocator: mem.Allocator, file_reader: std.io.AnyReader) !i32 {
    const input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    var count: i32 = 0;

    for (input.grid, 0..) |_, row| {
        std.debug.print("{} {s}\n", .{ row, input.grid[row] });
        for (input.grid[row], 0..) |_, column| {
            const position = Position{ .row = @intCast(row), .column = @intCast(column) };

            const char = input.at(position).?;

            if (char != 'X') {
                continue;
            }

            // Is there really not a better way to enumerate over enumerations?
            const directions = [_]Direction{
                .up,
                .down,
                .left,
                .right,
                .up_left,
                .down_left,
                .up_right,
                .down_right,
            };

            outer: for (directions) |direction| {
                const end_position = position.plus(direction, 3);
                if (!input.in_bounds(end_position)) {
                    continue;
                }

                for ("MAS", 1..) |expected, offset| {
                    const next_position = position.plus(direction, @intCast(offset));

                    const actual = input.at(next_position).?;
                    if (actual != expected) {
                        continue :outer;
                    }
                }

                std.debug.print("!! {} {} ({c})\n", .{ position, direction, char });
                count += 1;
            }
        }
    }

    return count;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(18, answer);
}

pub fn part2(allocator: mem.Allocator, file_reader: std.io.AnyReader) !i32 {
    const input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    var count: i32 = 0;

    for (input.grid, 0..) |_, row| {
        std.debug.print("{} {s}\n", .{ row, input.grid[row] });
        column_loop: for (input.grid[row], 0..) |_, column| {
            const position = Position{ .row = @intCast(row), .column = @intCast(column) };

            const char = input.at(position).?;

            if (char != 'A') {
                continue;
            }

            const top_left = input.at(position.plus(.up_left, 1)) orelse continue;
            const top_right = input.at(position.plus(.up_right, 1)) orelse continue;
            const bottom_left = input.at(position.plus(.down_left, 1)) orelse continue;
            const bottom_right = input.at(position.plus(.down_right, 1)) orelse continue;

            for ([_]u8{ top_left, top_right, bottom_left, bottom_right }) |corner| {
                if (corner != 'S' and corner != 'M') continue :column_loop;
            }

            if (top_left == bottom_right or top_right == bottom_left) {
                continue :column_loop;
            }

            std.debug.print("!! {}\n", .{position});
            count += 1;
        }
    }

    return count;
}

const Direction = enum {
    const Self = @This();

    up,
    down,
    left,
    right,
    up_left,
    down_left,
    up_right,
    down_right,

    pub fn format(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: std.io.AnyWriter,
    ) !void {
        _ = fmt;
        _ = options;

        const symbol = switch (self) {
            .up => "↑",
            .down => "↓",
            .left => "←",
            .right => "→",
            .up_left => "↖",
            .down_left => "↙",
            .up_right => "↗",
            .down_right => "↘",
        };

        try writer.writeAll(symbol);
    }

    fn column_offset(self: Self) i32 {
        return switch (self) {
            .right, .up_right, .down_right => 1,
            .left, .up_left, .down_left => -1,
            .up, .down => 0,
        };
    }

    fn row_offset(self: Self) i32 {
        return switch (self) {
            .up, .up_left, .up_right => -1,
            .down, .down_left, .down_right => 1,
            .left, .right => 0,
        };
    }
};

const Position = struct {
    const Self = @This();

    row: i32,
    column: i32,

    pub fn format(
        self: Position,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: std.io.AnyWriter,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({},{})", .{ self.row, self.column });
    }

    fn plus(self: Self, direction: Direction, times: i32) Position {
        const new_row = self.row + times * direction.row_offset();
        const new_column = self.column + times * direction.column_offset();

        return Position{ .row = new_row, .column = new_column };
    }
};

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(9, answer);
}

const example =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;

const Grid = [][]const u8;

const Input = struct {
    const Self = @This();

    grid: Grid,
    allocator: mem.Allocator,

    fn at(self: Self, position: Position) ?u8 {
        if (!self.in_bounds(position)) {
            return null;
        }

        return self.grid[@intCast(position.row)][@intCast(position.column)];
    }

    fn deinit(self: Self) void {
        for (self.grid) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.grid);
    }

    fn in_bounds(self: Self, position: Position) bool {
        return 0 <= position.row and position.row < self.number_of_rows() and 0 <= position.column and position.column < self.number_of_columns();
    }

    fn number_of_columns(self: Self) usize {
        return self.grid[0].len;
    }

    fn number_of_rows(self: Self) usize {
        return self.grid.len;
    }

    fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
        var grid = std.ArrayList([]const u8).init(allocator);
        while (true) {
            const line = try next_line_alloc(file_reader, allocator) orelse break;
            try grid.append(line);
        }

        return .{ .allocator = allocator, .grid = try grid.toOwnedSlice() };
    }
};
