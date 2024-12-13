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

    const part1Answer = try solve(file, false);
    std.debug.print("day 13 part 1: {}\n", .{part1Answer});

    const part2Answer = try solve(file, true);
    std.debug.print("day 13 part 2: {}\n", .{part2Answer});
}

fn solve(file: []const u8, comptime hardmode: bool) !i64 {
    var sub_problem = [_]i64{0} ** 6;
    var sub_problem_index: usize = 0;
    var parsing = false;
    var tokens: i64 = 0;

    for (file) |character| {
        assert(character != 0);
        const is_digit = ascii.isDigit(character);

        if (is_digit) {
            parsing = true;
            const digit = character - '0';
            assert(digit < 10);
            const current = &sub_problem[sub_problem_index];
            current.* = 10 * current.* + digit;
            continue;
        }

        // or eof?
        if (parsing) {
            // stop parsing the current number
            parsing = false;
            sub_problem_index += 1;

            if (sub_problem_index == 6) {
                const ax = sub_problem[0];
                const ay = sub_problem[1];
                const bx = sub_problem[2];
                const by = sub_problem[3];
                const offset = if (hardmode) 10000000000000 else 0;
                const cx = sub_problem[4] + offset;
                const cy = sub_problem[5] + offset;

                const inv_det = ax * by - ay * bx;

                const a = exact_div(by * cx - bx * cy, inv_det);
                const b = exact_div(cy * ax - ay * cx, inv_det);

                if (a != null and b != null) {
                    tokens += 3 * a.? + b.?;
                }

                @memset(&sub_problem, 0);
                sub_problem_index = 0;
            }
        }
    }

    return tokens;
}

fn exact_div(a: i64, b: i64) ?i64 {
    if (@mod(a, b) != 0) {
        return null;
    }

    const out = @divExact(a, b);
    return out;
}

test "part 1 example" {
    const actual = try solve(@embedFile("./example.txt"), true);
    try std.testing.expectEqual(480, actual);
}
