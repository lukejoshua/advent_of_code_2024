const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line_alloc = @import("./helpers.zig").next_line_alloc;

pub fn part1(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    var input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    input.print();
    const answer = input.solve(.part1, allocator);
    input.print();
    return answer;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(14, answer);
}

pub fn part2(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    var input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    return input.solve(.part2, allocator);
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(34, answer);
}

const example =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
    \\
;

const Position = struct {
    const Self = @This();

    row: i32,
    column: i32,

    fn antinodes(self: Self, other: Self, problem: Problem, allocator: mem.Allocator, input: Input) ![]Position {
        const row_difference = self.row - other.row;
        const column_difference = self.column - other.column;

        switch (problem) {
            .part1 => {
                var positions = std.ArrayList(Position).init(allocator);

                const before = Position{ .row = self.row + row_difference, .column = self.column + column_difference };
                if (input.in_bounds(before)) {
                    try positions.append(before);
                }

                const after = Position{ .row = other.row - row_difference, .column = other.column - column_difference };
                if (input.in_bounds(after)) {
                    try positions.append(after);
                }

                return positions.toOwnedSlice();
            },

            .part2 => {
                var positions = std.ArrayList(Position).init(allocator);
                try positions.append(self);
                try positions.append(other);

                var current = self;
                while (true) {
                    if (!input.in_bounds(current)) break;

                    try positions.append(current);
                    current = Position{ .row = current.row + row_difference, .column = current.column + column_difference };
                }

                current = other;
                while (true) {
                    if (!input.in_bounds(current)) break;
                    try positions.append(current);
                    current = Position{ .row = current.row - row_difference, .column = current.column - column_difference };
                }

                return positions.toOwnedSlice();
            },
        }
    }
};

const Problem = enum { part1, part2 };

const Input = struct {
    const Self = @This();

    const PositionSet = std.AutoHashMap(Position, void);
    const Antennas = std.AutoHashMap(u8, std.ArrayList(Position));

    allocator: std.mem.Allocator,
    antennas: *Antennas,
    antinodes: *PositionSet,
    column_count: i32,
    row_count: i32,

    fn print(self: Self) void {
        var signals = self.antennas.keyIterator();

        std.debug.print("r# = {} c# = {}\n", .{ self.row_count, self.column_count });
        std.debug.print("antinodes: {any}\n\n", .{self.antinodes});
        var ans = self.antinodes.keyIterator();
        while (ans.next()) |an| {
            std.debug.print("({}, {})\n", .{ an.row, an.column });
        }

        while (signals.next()) |signal| {
            const antennas = self.antennas.get(signal.*).?;
            std.debug.print("{c}:, antennas: {any}\n\n", .{ signal.*, antennas.items });
        }
    }

    fn solve(self: Self, problem: Problem, allocator: mem.Allocator) !usize {
        // for each key of self.antennas
        //   for each pair of antennas in the list
        //       find the dx, dy
        //       add that to each to get 2 new positions
        //       put each in the antinodes set if they're in bounds
        // return antinode set size

        var signals = self.antennas.keyIterator();

        while (signals.next()) |signal| {
            const antennas = self.antennas.get(signal.*).?;

            if (antennas.items.len == 1) {
                continue;
            }

            for (antennas.items, 0..) |antenna1, index| {
                for (antennas.items[index + 1 ..]) |antenna2| {
                    // TODO: you can get away from allocating by using an iterator
                    const antinodes = try antenna2.antinodes(antenna1, problem, allocator, self);
                    defer allocator.free(antinodes);

                    for (antinodes) |antinode| {
                        assert(self.in_bounds(antinode));
                        try self.antinodes.put(antinode, undefined);
                    }
                }
            }
        }

        return self.antinodes.count();
    }

    fn in_bounds(self: Self, position: Position) bool {
        return 0 <= position.row and position.row < self.row_count and 0 <= position.column and position.column < self.column_count;
    }

    fn deinit(self: Self) void {
        var antennas = self.antennas.valueIterator();
        while (antennas.next()) |antenna| {
            antenna.deinit();
        }
        self.antennas.deinit();
        self.allocator.destroy(self.antennas);

        self.antinodes.deinit();
        self.allocator.destroy(self.antinodes);
    }

    fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
        var antennas = try allocator.create(Antennas);
        antennas.* = Antennas.init(allocator);
        // TODO: errdefer to free antennas

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
                '\r' => continue,
                '.' => {
                    column += 1;
                },
                else => |c| {
                    const result = try antennas.getOrPut(c);
                    if (!result.found_existing) {
                        result.value_ptr.* = std.ArrayList(Position).init(allocator);
                    }

                    try result.value_ptr.append(.{ .row = row, .column = column });
                    column += 1;
                },
            }
        }

        const antinodes = try allocator.create(PositionSet);
        antinodes.* = PositionSet.init(allocator);
        // TODO: errdefer to free visited

        return .{
            .allocator = allocator,
            .antennas = antennas,
            .antinodes = antinodes,
            .column_count = column_count,
            .row_count = row,
        };
    }
};
