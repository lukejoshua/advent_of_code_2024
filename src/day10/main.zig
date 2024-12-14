const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const file = @embedFile("./input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};

    const part1Answer = try part1(gpa.allocator(), file);
    std.debug.print("Day 10 part 1: {}\n", .{part1Answer});

    const part2Answer = try part2(gpa.allocator(), file);
    std.debug.print("Day 10 part 2: {}\n", .{part2Answer});
}

test "part 1 example" {
    const file = @embedFile("./example.txt");
    const actual = part1(std.testing.allocator, file);
    try std.testing.expectEqual(36, actual);
}

test "part 2 example" {
    const file = @embedFile("./example.txt");
    const actual = part2(std.testing.allocator, file);
    try std.testing.expectEqual(81, actual);
}

fn part1(allocator: Allocator, file: []const u8) !u64 {
    var lines = std.mem.tokenizeAny(u8, file, "\n\r");
    var rows = std.ArrayList([]u4).init(allocator);

    defer {
        for (rows.items) |row| {
            allocator.free(row);
        }
        rows.deinit();
    }

    var starting_points = std.ArrayList(Position).init(allocator);
    defer starting_points.deinit();

    var r: i32 = 0;
    while (lines.next()) |line| {
        const row = try allocator.alloc(u4, line.len);

        for (line, 0..) |char, c| {
            assert(ascii.isDigit(char));
            const height: u4 = @intCast(char - '0');
            if (height == 0) {
                try starting_points.append(Position{ .row = r, .column = @intCast(c) });
            }
            row[c] = height;
        }

        try rows.append(row);
        r += 1;
    }

    const grid = rows.items;

    var visited = std.AutoHashMap(Position, void).init(allocator);
    defer (&visited).deinit();

    var total: u32 = 0;

    for (starting_points.items) |starting_point| {
        try traverse(grid, starting_point, &visited);
        var key_iterator = visited.keyIterator();
        while (key_iterator.next()) |position| {
            const height = position.get(grid) orelse continue;
            if (height != 9) continue;
            total += 1;
        }
        (&visited).clearRetainingCapacity();
    }

    return total;
}

fn part2(allocator: Allocator, file: []const u8) !u64 {
    var lines = std.mem.tokenizeAny(u8, file, "\n\r");
    var rows = std.ArrayList([]u4).init(allocator);

    defer {
        for (rows.items) |row| {
            allocator.free(row);
        }
        rows.deinit();
    }

    var starting_points = std.ArrayList(Position).init(allocator);
    defer starting_points.deinit();

    var r: i32 = 0;
    while (lines.next()) |line| {
        const row = try allocator.alloc(u4, line.len);

        for (line, 0..) |char, c| {
            assert(ascii.isDigit(char));
            const height: u4 = @intCast(char - '0');
            if (height == 0) {
                try starting_points.append(Position{ .row = r, .column = @intCast(c) });
            }
            row[c] = height;
        }

        try rows.append(row);
        r += 1;
    }

    const grid = rows.items;

    var total: u32 = 0;

    for (starting_points.items) |starting_point| {
        total += traverseAll(grid, starting_point);
        std.debug.print("New Total: {}\n", .{total});
        // var key_iterator = visited.keyIterator();
        // while (key_iterator.next()) |position| {
        //     const height = position.get(grid) orelse continue;
        //     if (height != 9) continue;
        //     total += 1;
        // }
        // (&visited).clearRetainingCapacity();
    }

    return total;
}

const Grid = [][]u4;
const Position = struct {
    const Self = @This();
    row: i32,
    column: i32,
    fn get(self: Self, grid: Grid) ?u4 {
        if (self.row < 0 or grid.len <= self.row)
            return null;

        if (self.column < 0 or grid[0].len <= self.column)
            return null;

        return grid[@intCast(self.row)][@intCast(self.column)];
    }
    fn neighbours(self: Self, grid: Grid) [4]?Position {
        var ns = [_]?Position{null} ** 4;

        const directions: [4][2]i32 = .{
            // up
            .{ -1, 0 },
            // down
            .{ 1, 0 },
            // left
            .{ 0, -1 },
            // right
            .{ 0, 1 },
        };

        for (directions, 0..) |direction, index| {
            const new_row = self.row + direction[0];
            const new_column = self.column + direction[1];

            if (new_row < 0 or new_row >= grid.len) {
                continue;
            }

            if (new_column < 0 or new_column >= grid[0].len) {
                continue;
            }

            if (grid[@intCast(new_row)][@intCast(new_column)] != grid[@intCast(self.row)][@intCast(self.column)] + 1) {
                continue;
            }

            ns[index] = Position{
                .row = new_row,
                .column = new_column,
            };
        }

        return ns;
    }
};

fn traverse(grid: Grid, starting_point: Position, visited: *std.AutoHashMap(Position, void)) !void {
    if (visited.contains(starting_point))
        return;

    try visited.put(starting_point, undefined);

    for (starting_point.neighbours(grid)) |neighbour| {
        try traverse(grid, neighbour orelse continue, visited);
    }
}

fn traverseAll(grid: Grid, starting_point: Position) u32 {
    if (starting_point.get(grid) == 9) {
        return 1;
    }

    var sum: u32 = 0;
    for (starting_point.neighbours(grid)) |neighbour| {
        sum += traverseAll(grid, neighbour orelse continue);
    }
    return sum;
}
