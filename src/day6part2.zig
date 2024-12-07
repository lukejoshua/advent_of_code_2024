const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line_alloc = @import("./helpers.zig").next_line_alloc;

pub fn part2(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    var input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    var original_path = std.AutoHashMap(Position, void).init(allocator);
    defer original_path.deinit();

    while (try input.step() == null) {
        try original_path.put(input.position, undefined);
    }

    var candidate_obstacle_positions = original_path.keyIterator();

    var count: u32 = 0;

    outer: while (candidate_obstacle_positions.next()) |position| {
        const r = position[0];
        const c = position[1];

        if (input.obstacles.contains(.{ r, c })) {
            continue;
        }

        if (input.startingPosition[0] == r and input.startingPosition[1] == c) {
            continue;
        }

        try input.obstacles.put(.{ r, c }, undefined);
        defer _ = input.obstacles.remove(.{ r, c });

        input.previousStates.clearRetainingCapacity();
        input.position = input.startingPosition;
        try input.previousStates.put(.{ .row = input.position[0], .column = input.position[1], .direction = .up }, undefined);
        input.direction = .up;

        while (true) {
            const is_in_loop = (try input.step()) orelse continue;

            if (is_in_loop) {
                count += 1;
                break;
            } else {
                continue :outer;
            }
        }
    }

    return count;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(6, answer);
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

const Input = struct {
    const Self = @This();

    const PositionSet = std.AutoHashMap(Position, void);
    const State = struct { row: i32, column: i32, direction: Direction };

    allocator: std.mem.Allocator,
    startingPosition: Position,
    obstacles: *std.AutoHashMap(Position, void),
    position: Position,
    direction: Direction,
    previousStates: *std.AutoHashMap(State, void),
    column_count: i32,
    row_count: i32,

    // false -> loop
    // true -> exits
    // null -> continue
    fn step(self: *Self) !?bool {
        const new_position = .{ self.position[0] + self.direction.row_offset(), self.position[1] + self.direction.column_offset() };

        if (!self.in_bounds(new_position)) {
            return false;
        }

        const new_state = State{ .row = new_position[0], .column = new_position[1], .direction = self.direction };
        if (self.previousStates.contains(new_state)) {
            return true;
        }

        if (self.obstacles.contains(new_position)) {
            // We can get away with only storing the states where we encounter obstacles
            try self.previousStates.put(new_state, undefined);
            self.direction = switch (self.direction) {
                .up => .right,
                .right => .down,
                .down => .left,
                .left => .up,
            };

            return self.step();
        }

        self.position = new_position;
        return null;
    }

    fn in_bounds(self: Self, position: Position) bool {
        return 0 <= position[0] and position[0] < self.row_count and 0 <= position[1] and position[1] < self.column_count;
    }

    fn deinit(self: Self) void {
        self.obstacles.deinit();
        self.allocator.destroy(self.obstacles);
        self.previousStates.deinit();
        self.allocator.destroy(self.previousStates);
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
                    column += 1;
                },
                else => {},
            }
        }

        const previousStates = try allocator.create(std.AutoHashMap(State, void));
        previousStates.* = std.AutoHashMap(State, void).init(allocator);
        // TODO: errdefer to free visited

        return .{
            .allocator = allocator,
            .obstacles = obstacles,
            .startingPosition = startingPosition,
            .position = startingPosition,
            .previousStates = previousStates,
            .column_count = column_count,
            .row_count = row + 1,
            .direction = .up,
        };
    }
};
