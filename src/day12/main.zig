const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

const DEBUG = true;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer assert(gpa.deinit() == .ok);

    const file = @embedFile("./input.txt");

    const part1Answer = try part1(gpa.allocator(), file);
    std.debug.print("day 11 part 1: {}\n\n", .{part1Answer});

    const part2Answer = try part2(gpa.allocator(), file);
    std.debug.print("day 11 part 2: {}\n\n", .{part2Answer});
}

const State = std.AutoHashMap(u64, i64);

fn part1(allocator: Allocator, file: []const u8) !i64 {
    return solve(allocator, file);
}

fn part2(allocator: Allocator, file: []const u8) !i64 {
    return solve(allocator, file);
}

fn solve(allocator: Allocator, file: []const u8) !i64 {
    // split into lines
    // paste each parsed line
    //
    // iterate starting cell over rows/columns
    // keep a table of which nodes have been visited already
    // start a flood fill
    // keep track of count (area)
    // for each block, when calculating neighbours to move to- track how many "exposed sides" (perimeter)

    var lineIterator = std.mem.tokenizeAny(u8, file, "\r\n");

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var column_length: ?usize = null;

    while (lineIterator.next()) |line| {
        if (column_length) |len| {
            assert(line.len == len);
        } else {
            column_length = line.len;
        }

        try lines.append(line);
    }

    const grid = lines.items;
    print(grid);

    var visited = try allocator.create(std.AutoHashMap([2]i32, void));
    visited.* = std.AutoHashMap([2]i32, void).init(allocator);
    defer {
        visited.deinit();
        allocator.destroy(visited);
    }

    var sum: u32 = 0;
    for (0..grid.len) |r| {
        for (0..grid[r].len) |c| {
            const current_position = Position{ .row = @intCast(r), .column = @intCast(c), .grid = grid };
            if (visited.contains(current_position.rc())) continue;
            const f = try floodFill(current_position, visited);
            sum += f[0] * f[1];
        }
    }

    return sum;
}

const PositionSet = std.AutoHashMap(Position, void);

/// Returns area, perimeter
fn floodFill(position: Position, visited: *std.AutoHashMap([2]i32, void)) ![2]u32 {
    const entry = try visited.getOrPut(position.rc());
    if (entry.found_existing) {
        return .{ 0, 0 };
    }

    var area: u32 = 1;
    var perimeter: u32 = 0;

    const neighbours = position.neighbours();

    for (neighbours) |neighbour| {

        // is the neighbour the same type
        if (neighbour) |n| {
            const f = try floodFill(n, visited);
            area += f[0];
            perimeter += f[1];
        } else {
            perimeter += 1;
        }
    }

    return .{ area, perimeter };
}

const Grid = [][]const u8;

const Position = struct {
    const Self = @This();

    row: i32,
    column: i32,
    grid: Grid,

    fn rc(self: Self) [2]i32 {
        return .{ self.row, self.column };
    }

    fn create(grid: Grid, row: i32, column: i32) Self {
        assert(row < grid.len);
        assert(column < grid[0].len);

        return Self{ .row = row, .column = column, .grid = grid };
    }

    fn neighbours(self: Self) [4]?Position {
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

            if (new_row < 0 or new_row >= self.grid.len) {
                continue;
            }

            if (new_column < 0 or new_column >= self.grid[0].len) {
                continue;
            }

            if (self.grid[@intCast(new_row)][@intCast(new_column)] != self.grid[@intCast(self.row)][@intCast(self.column)]) {
                continue;
            }

            ns[index] = Position{
                .row = new_row,
                .column = new_column,
                .grid = self.grid,
            };
        }

        return ns;
    }
};

const example =
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
;

test "part 1 example" {
    const actual = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(1930, actual);
}

fn print(grid: [][]const u8) void {
    if (!DEBUG) return;

    for (grid) |row| {
        std.debug.print("{s}\n", .{row});
    }
}
