const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const assert = std.debug.assert;
const Allocator = mem.Allocator;
const is_test = @import("builtin").is_test;

pub const input = @embedFile("input.txt");
const DEBUG = false;

const log = std.log.scoped(.day15);

const Map = [][]GridCell;
const GridCell = union(enum) { robot, crate, wall, nothing };

pub fn part1(allocator: Allocator, file: []const u8) !u64 {
    var rows = std.ArrayList([]GridCell).init(allocator);
    var line_iterator = mem.splitSequence(u8, file, "\n");
    var robot_position: [2]usize = undefined;

    var row_count: usize = 0;
    while (line_iterator.next()) |line| {
        // No longer processing the grid
        if (line.len == 0 or line[0] != '#') break;

        const row = try allocator.alloc(GridCell, line.len);
        for (line, 0..) |character, c| {
            row[c] = parse_map_cell(character);
            if (row[c] == .robot) {
                robot_position = .{ row_count, c };
            }
        }
        try rows.append(row);
        row_count += 1;
    }

    const grid = try rows.toOwnedSlice();
    defer {
        for (grid) |row| {
            allocator.free(row);
        }
        allocator.free(grid);
    }

    try print(grid);

    var count: i32 = 0;
    while (line_iterator.next()) |line| {
        for (line) |instruction| {
            if (DEBUG) std.debug.print("{}: {c}\n", .{ count, instruction });
            count += 1;
            try print(grid);

            assert(grid[robot_position[0]][robot_position[1]] == .robot);

            const direction = parse_direction(instruction) orelse continue;
            const robot_target = plus(robot_position, direction);
            var obstacle = grid[robot_target[0]][robot_target[1]];
            if (DEBUG) std.debug.print("{} {} {any}\n", .{ direction[0], direction[1], obstacle });
            switch (obstacle) {
                .nothing => {
                    grid[robot_target[0]][robot_target[1]] = .robot;
                    grid[robot_position[0]][robot_position[1]] = .nothing;
                    robot_position = robot_target;
                },
                .wall => {
                    continue;
                },
                .robot => unreachable,
                .crate => {
                    var c = robot_target;
                    while (obstacle == .crate) {
                        c = plus(c, direction);

                        obstacle = grid[c[0]][c[1]];
                    }

                    switch (obstacle) {
                        .crate, .robot => unreachable,
                        .wall => continue,
                        .nothing => {
                            grid[robot_target[0]][robot_target[1]] = .robot;
                            grid[robot_position[0]][robot_position[1]] = .nothing;
                            robot_position = robot_target;
                            grid[c[0]][c[1]] = .crate;
                        },
                    }
                },
            }
        }
    }

    var total: usize = 0;

    for (grid, 0..) |row, r| {
        for (row, 0..) |cell, c| {
            if (cell != .crate) continue;

            total += r * 100 + c;
        }
    }
    try print(grid);

    assert(total == 1465152);
    return total;
}

pub fn part2(allocator: Allocator, file: []const u8) u64 {
    _ = allocator;
    _ = file;

    return 2;
}

test "part 1 small example" {
    try testing.expectEqual(2028, part1(testing.allocator, @embedFile("example-small.txt")));
}

test "part 1 large example" {
    try testing.expectEqual(10092, part1(testing.allocator, @embedFile("example-large.txt")));
}

fn parse_map_cell(c: u8) GridCell {
    return switch (c) {
        '#' => .wall,
        '.' => .nothing,
        'O' => .crate,
        '@' => .robot,
        else => {
            // log.err("Unexpected grid character: {c}", .{c});
            unreachable;
        },
    };
}

fn parse_direction(character: u8) ?[2]i8 {
    return switch (character) {
        '^' => .{ -1, 0 },
        'v' => .{ 1, 0 },
        '<' => .{ 0, -1 },
        '>' => .{ 0, 1 },
        else => null,
    };
}

// Can't be bothered to do int casting again
fn plus(position: [2]usize, direction: [2]i8) [2]usize {
    var p = position;
    const dr = direction[0];
    const dc = direction[1];

    if (dr < 0) {
        p[0] -= @abs(dr);
    } else {
        p[0] += @abs(dr);
    }

    if (direction[1] < 0) {
        p[1] -= @abs(dc);
    } else {
        p[1] += @abs(dc);
    }

    return p;
}

// This is super ineffecient, but logging is borked
fn print(map: Map) !void {
    if (!DEBUG) return;
    std.debug.print("printing {} {}\n", .{ map.len, map[0].len });
    for (map) |row| {
        for (row) |cell| {
            const char: u8 = switch (cell) {
                .robot => '@',
                .crate => 'O',
                .nothing => '.',
                .wall => '#',
            };
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}
