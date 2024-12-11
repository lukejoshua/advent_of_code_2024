const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;
const problem = @import("../problem.zig");

pub const day10 = problem.Problem{ .part1 = problem.SubProblem{
    .example_input =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
    ,
    .expected_example_answer = 36,
    .solution = solution,
    .input_filename = @embedFile("./input.txt"),
    .expected_answer = null,
}, .part2 = null };

test "example" {
    try day10.part1.?.test_example();
}

fn solution(allocator: Allocator, file: []const u8) !u64 {
    const lines = std.mem.tokenizeScalar(u8, file, '\n');

    var grid = std.ArrayList([]u8).init(allocator);
    defer {
        for (grid) |row| {
            allocator.free(row);
        }
        grid.deinit();
    }

    while (lines.next()) |line| {
        var row = allocator.alloc(u4, line.len);
        for (line, 0..) |character, index| {
            assert(ascii.isDigit(character));
            row[index] = @intCast(character - '0');
        }

        try grid.append(line);
        allocator.free(line);
    }

    var visited = AutoHashSet(Position).init(allocator);
    defer visited.deinit();

    for (grid.items, 0..) |row, r| {
        for (row, 0..) |cell, c| {
            visited.clear();
            visited.set(Position{ .row = r, .column = c });
        }
    }
}

const Position = struct {
    const Self = @This();

    row: i16,
    column: i16,

    fn neighbours(self: Self) [4]Position {
        return [_]Position{
            self.plus(-1, 0),
            self.plus(1, 0),
            self.plus(0, -1),
            self.plus(0, 1),
        };
    }

    fn plus(self: Self, row_offset: comptime_int, column_offset: comptime_int) Position {
        return Position{
            .row = self.row + row_offset,
            .column = self.column + column_offset,
        };
    }

    const offsets = [4][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };
};

fn AutoHashSet(comptime T: type) type {
    return struct {
        const Self = @This();

        hashmap: *std.AutoHashMap(T, void),

        fn init(allocator: Allocator) Self {
            return Self{
                .hashmap = std.AutoHashMap(T, void).init(allocator),
            };
        }

        fn deinit(self: Self) void {
            self.hashmap.deinit();
        }

        fn set(self: Self, value: T) !void {
            try self.hashmap.put(value, undefined);
        }

        fn clear(self: Self) void {
            self.hashmap.clearRetainingCapacity();
        }
    };
}
