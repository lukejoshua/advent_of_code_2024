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

    const part1Answer = try solve(file, 101, 103);
    std.debug.print("day 14 part 1: {}\n", .{part1Answer});

    const part2Answer = try draw(gpa.allocator(), file, 101, 103);
    std.debug.print("day 14 part 2: {}\n", .{part2Answer});
}

fn solve(file: []const u8, width: i64, height: i64) !u64 {
    var robot = [_]i64{0} ** 4;
    var component_index: usize = 0;
    var parsing = false;
    var sign: i2 = 1;
    var quadrants = [_]u64{0} ** 4;
    const ROUNDS = 100;

    for (file) |character| {
        assert(character != 0);
        const is_digit = ascii.isDigit(character);

        if (is_digit) {
            parsing = true;
            const digit = character - '0';
            assert(digit < 10);
            const current = &robot[component_index];
            current.* = 10 * current.* + digit;
            continue;
        } else if (character == '-') {
            sign = -1;
        }

        // or eof?
        if (parsing) {
            // stop parsing the current number
            parsing = false;
            robot[component_index] *= sign;
            component_index += 1;

            if (component_index == 4) {
                const px = robot[0];
                const py = robot[1];
                const vx = robot[2];
                const vy = robot[3];

                const final_x = @mod(px + ROUNDS * vx, width);
                const final_y = @mod(py + ROUNDS * vy, height);

                std.debug.print("({}, {})  --({}, {})-->  ({}, {})\n", .{ px, py, vx, vy, final_x, final_y });

                const x_midpoint = @divFloor(width, 2);
                const y_midpoint = @divFloor(height, 2);

                if (final_x != x_midpoint and final_y != y_midpoint) {
                    const qx: usize = if (final_x < x_midpoint) 0 else 1;
                    const qy: usize = if (final_y < y_midpoint) 0 else 1;

                    quadrants[qx | (qy << 1)] += 1;
                }

                @memset(&robot, 0);
                component_index = 0;
            }
            sign = 1;
        }
    }

    return quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];
}

test "part 1 example" {
    const actual = try solve(@embedFile("./example.txt"), 11, 7);
    try std.testing.expectEqual(12, actual);
}

const skip = true;
fn draw(allocator: Allocator, file: []const u8, width: i64, height: i64) !u64 {
    const Robot = [4]i64;

    var robot = [_]i64{0} ** 4;
    var component_index: usize = 0;
    var parsing = false;
    var sign: i2 = 1;
    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();

    for (file) |character| {
        assert(character != 0);
        const is_digit = ascii.isDigit(character);

        if (is_digit) {
            parsing = true;
            const digit = character - '0';
            assert(digit < 10);
            const current = &robot[component_index];
            current.* = 10 * current.* + digit;
            continue;
        } else if (character == '-') {
            sign = -1;
        }

        // or eof?
        if (parsing) {
            // stop parsing the current number
            parsing = false;
            robot[component_index] *= sign;
            component_index += 1;

            if (component_index == 4) {
                try robots.append(robot);

                @memset(&robot, 0);
                component_index = 0;
            }
            sign = 1;
        }
    }

    var board = try allocator.alloc(u8, @intCast(width * height));
    defer allocator.free(board);
    const round = 7709;

    @memset(board, '.');

    for (robots.items) |r| {
        const px = r[0];
        const py = r[1];
        const vx = r[2];
        const vy = r[3];
        const uround: i64 = @intCast(round);
        const final_x = @mod(px + uround * vx, width);
        const final_y = @mod(py + uround * vy, height);

        board[@intCast(final_y * width + final_x)] = 'x';
    }

    std.debug.print("\n\nRound {}:\n", .{round});
    for (0..@intCast(height - 1)) |r| {
        const rr: i64 = @intCast(r);
        std.debug.print("{s}\n", .{board[@intCast(width * rr)..@intCast(width * (rr + 1))]});
    }

    return round;
}
