const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line_alloc = @import("./helpers.zig").next_line_alloc;

pub fn part1(allocator: mem.Allocator, file_reader: anytype) !u64 {
    var sum: u64 = 0;

    while (try next_line_alloc(file_reader, allocator)) |line| {
        defer allocator.free(line);
        var numbers = std.mem.tokenizeAny(u8, line, " :");
        const lhs = try std.fmt.parseUnsigned(u64, numbers.next().?, 10);
        const first_operand = try std.fmt.parseUnsigned(u64, numbers.next().?, 10);

        var operands = std.ArrayList(u64).init(allocator);

        while (numbers.next()) |number| {
            try operands.append(try std.fmt.parseUnsigned(u64, number, 10));
        }

        const equation = Equation{ .lhs = lhs, .operands = try operands.toOwnedSlice(), .acc = first_operand };
        defer allocator.free(equation.operands);

        if (equation.is_solvable(false)) {
            sum += equation.lhs;
        }
    }

    return sum;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(3749, answer);
}

pub fn part2(allocator: mem.Allocator, file_reader: anytype) !u64 {
    var sum: u64 = 0;

    while (try next_line_alloc(file_reader, allocator)) |line| {
        defer allocator.free(line);
        var numbers = std.mem.tokenizeAny(u8, line, " :");
        const lhs = try std.fmt.parseUnsigned(u64, numbers.next().?, 10);
        const first_operand = try std.fmt.parseUnsigned(u64, numbers.next().?, 10);

        var operands = std.ArrayList(u64).init(allocator);

        while (numbers.next()) |number| {
            try operands.append(try std.fmt.parseUnsigned(u64, number, 10));
        }

        const equation = Equation{ .lhs = lhs, .operands = try operands.toOwnedSlice(), .acc = first_operand };
        defer allocator.free(equation.operands);

        if (equation.is_solvable(true)) {
            sum += equation.lhs;
        }
    }

    return sum;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();

    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(11387, answer);
}

const example =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

const Equation = struct {
    const Self = @This();

    lhs: u64,
    acc: u64,
    operands: []u64,

    fn is_solvable(self: Self, support_concat: bool) bool {
        if (self.operands.len == 0) {
            return self.acc == self.lhs;
        }

        if (support_concat) {
            var mul = Equation{ .lhs = self.lhs, .acc = self.acc * self.operands[0], .operands = self.operands[1..] };
            var add = Equation{ .lhs = self.lhs, .acc = self.acc + self.operands[0], .operands = self.operands[1..] };

            const shift = std.math.powi(u64, 10, std.math.log10_int(self.operands[0]) + 1) catch {
                std.debug.print("Underflow or overflow", .{});
                return false;
            };

            var concat =
                Equation{
                .lhs = self.lhs,
                // shift in base 10
                .acc = self.acc * shift + self.operands[0],
                .operands = self.operands[1..],
            };

            return mul.is_solvable(true) or add.is_solvable(true) or concat.is_solvable(true);
        } else {
            var mul = Equation{ .lhs = self.lhs, .acc = self.acc * self.operands[0], .operands = self.operands[1..] };
            var add = Equation{ .lhs = self.lhs, .acc = self.acc + self.operands[0], .operands = self.operands[1..] };

            return mul.is_solvable(false) or add.is_solvable(false);
        }
    }
};
