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
    try std.testing.expectEqual(1928, answer);
}

pub fn part2(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    var input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    // return input.solve(.part2, allocator);
    return 0;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(undefined, answer);
}

const example = "2333133121414131402";

const Problem = enum { part1, part2 };

const Input = struct {
    const Self = @This();
    const FileID = u32;

    allocator: std.mem.Allocator,
    disk: []?FileID,

    fn print(self: Self) void {
        for (self.disk) |file_id| {
            if (file_id) |id| {
                if (id < 10) {
                    std.debug.print("{}", .{id});
                } else {
                    std.debug.print("[{}]", .{id});
                }
            } else {
                std.debug.print(".", .{});
            }
        }

        std.debug.print("\n", .{});
    }

    fn solve(self: Self, problem: Problem, allocator: mem.Allocator) !usize {
        assert(problem == .part1);
        _ = allocator;

        var next_free_space: usize = 0;
        var last_occupied_space: usize = self.disk.len - 1;

        while (next_free_space < last_occupied_space) {
            if (self.disk[next_free_space] != null) {
                next_free_space += 1;
                continue;
            }

            if (self.disk[last_occupied_space] == null) {
                last_occupied_space -= 1;
                continue;
            }

            self.disk[next_free_space] = self.disk[last_occupied_space];
            self.disk[last_occupied_space] = null;
        }

        var checksum: u64 = 0;
        for (self.disk, 0..) |file_id, index| {
            if (file_id) |id| {
                checksum += id * index;
            } else {
                break;
            }
        }
        return checksum;
    }

    fn deinit(self: Self) void {
        self.allocator.free(self.disk);
    }

    fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
        var is_file = true;
        var file_id: FileID = 0;
        var disk = std.ArrayList(?FileID).init(allocator);
        while (file_reader.readByte() catch null) |digit| {
            if (!ascii.isDigit(digit)) {
                break;
            }

            const size = digit - '0';

            if (is_file) {
                try disk.appendNTimes(file_id, size);
            } else {
                try disk.appendNTimes(null, size);
            }

            if (is_file) file_id += 1;
            is_file = !is_file;
        }

        return .{ .disk = try disk.toOwnedSlice(), .allocator = allocator };
    }
};
