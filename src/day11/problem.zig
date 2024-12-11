const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub const Problem = struct { part1: ?SubProblem, part2: ?SubProblem };

pub const SubProblem =
    struct {
    const Self = @This();

    // TODO: comptime?
    example_input: []const u8,
    expected_example_answer: u64,
    solution: fn (Allocator, []const u8) anyerror!u64,
    input_filename: []const u8,
    expected_answer: ?u64,

    fn solve(self: Self, allocator: Allocator) !u64 {
        const file = @embedFile(self.input_filename);
        return self.solution(allocator, file);
    }

    fn test_example(self: Self) !void {
        assert(@import("builtin").is_test);

        const actual = self.solution(testing.allocator, self.example_input);
        try testing.expectEqual(self.expected_example_answer, actual);
    }
};
