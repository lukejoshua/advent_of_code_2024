const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line_alloc = @import("./helpers.zig").next_line_alloc;

pub fn part1(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    var input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    while (try input.step()) {}

    for (0..@intCast(input.row_count)) |r| {
        for (0..@intCast(input.column_count)) |c| {
            const pos: Position = .{ @intCast(r), @intCast(c) };
            if (s[0] == pos[0] and s[1] == pos[1]) {
                std.debug.print("^", .{});
            } else if (input.visited.contains(pos)) {
                std.debug.print("X", .{});
            } else if (input.obstacles.contains(pos)) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    return input.visited.count();
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(41, answer);
}

pub fn part2(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    _ = allocator;
    _ = file_reader;
    return 0;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(undefined, answer);
}

const example =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

const Direction = enum {
    const Self = @This();

    up,
    right,
    down,
    left,

    fn row_offset(self: Self) i32 {
        return switch (self) {
            .up => -1,
            .down => 1,
            .left, .right => 0,
        };
    }

    fn column_offset(self: Self) i32 {
        return switch (self) {
            .left => -1,
            .right => 1,
            .up, .down => 0,
        };
    }
};

const Position = [2]i32;
// TODO: remove
var s: Position = undefined;

const Input = struct {
    const Self = @This();

    const PositionSet = std.AutoHashMap(Position, void);

    allocator: std.mem.Allocator,
    obstacles: *PositionSet,
    position: Position,
    visited: *PositionSet,
    direction: Direction,
    column_count: i32,
    row_count: i32,

    fn step(self: *Self) !bool {
        const new_position = .{ self.position[0] + self.direction.row_offset(), self.position[1] + self.direction.column_offset() };
        if (!self.in_bounds(new_position)) {
            return false;
        }

        if (self.obstacles.contains(new_position)) {
            self.direction = switch (self.direction) {
                .up => .right,
                .right => .down,
                .down => .left,
                .left => .up,
            };

            return self.step();
        }

        try self.visited.put(new_position, undefined);
        self.position = new_position;
        return true;
    }

    fn in_bounds(self: Self, position: Position) bool {
        return 0 <= position[0] and position[0] < self.row_count and 0 <= position[1] and position[1] < self.column_count;
    }

    fn deinit(self: Self) void {
        self.obstacles.deinit();
        self.allocator.destroy(self.obstacles);
        self.visited.deinit();
        self.allocator.destroy(self.visited);
    }

    fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
        var obstacles = try allocator.create(PositionSet);
        obstacles.* = PositionSet.init(allocator);
        // TODO: errdefer to free obstacles

        var startingPosition: Position = undefined;

        var row: i32 = 0;
        var column: i32 = 0;
        var column_count: i32 = 0;

        while (true) {
            const cell = file_reader.readByte() catch break;

            switch (cell) {
                '\n' => {
                    column_count = @max(column_count, column);
                    column = 0;
                    row += 1;
                },
                '#' => {
                    try obstacles.put(.{ row, column }, undefined);
                    column += 1;
                },
                '.' => {
                    column += 1;
                },
                '^' => {
                    startingPosition = .{ row, column };
                    s = startingPosition;
                    column += 1;
                },
                else => {},
            }
        }

        const visited = try allocator.create(PositionSet);
        visited.* = PositionSet.init(allocator);
        // TODO: errdefer to free visited
        try visited.put(startingPosition, undefined);

        return .{
            .allocator = allocator,
            .obstacles = obstacles,
            .position = startingPosition,
            .visited = visited,
            .column_count = column_count,
            .row_count = row + 1,
            // Up
            .direction = .up,
        };
    }
};
