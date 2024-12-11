const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

const Problem = struct { part1: ?SubProblem, part2: ?SubProblem };

const SubProblem =
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

pub const day9 = Problem{
    .part1 = null,
    .part2 = SubProblem{
        .example_input = "",
        .expected_example_answer = 2858,
        .solution = solution,
        .input_filename = @embedFile("./input.txt"),
        .expected_answer = null,
    },
};

test "example" {
    try day9.part2.?.test_example();
}

fn solution(allocator: Allocator, file: []const u8) !u64 {
    var is_file = true;
    var file_id: FileId = 0;

    var disk = Disk.init(allocator);
    defer disk.deinit();

    for (file) |character| {
        assert(ascii.isDigit(character));
        const size = character - '0';
        assert(0 < size and size < 10);
        try disk.append(@intCast(size), if (is_file) file_id else null);

        if (is_file) file_id += 1;
        is_file = !is_file;
    }

    while (!try disk.step(allocator)) {}

    return disk.checksum();
}

/// Doubly linked list
const Disk = struct {
    const Self = @This();

    first_block: ?*Block,
    last_block: ?*Block,
    first_empty_block: ?*Block,
    last_occupied_block: ?*Block,
    allocator: Allocator,

    fn init(allocator: Allocator) Self {
        return Self{
            //
            .first_block = null,
            .last_block = null,
            .first_empty_block = null,
            .last_occupied_block = null,
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        var current = self.first_block;
        while (current) |block| {
            const next = block.next;
            self.allocator.destroy(block);
            current = next;
        }
    }

    fn append(self: *Self, size: BlockSize, id: ?FileId) !void {
        if (size == 0) {
            return;
        }

        const block = try self.allocator.create(Block);
        errdefer self.allocator.destroy(block);

        block.* = Block{
            .next = null,
            .previous = null,
            .size = size,
            .file_id = id,
        };

        if (self.first_block == null) {
            self.first_block = block;
        }

        if (self.first_empty_block == null and id == null) {
            self.first_empty_block = block;
        }

        if (self.last_block) |last_block| {
            block.previous = last_block;
            last_block.next = block;
        }

        self.last_block = block;

        if (id) |_| {
            self.last_occupied_block = block;
        }
    }

    // returns true iff the process is done
    fn step(self: *Self, allocator: Allocator) !bool {
        var first_empty_block = self.first_empty_block orelse return true;
        var last_occupied_block = self.last_occupied_block orelse return true;

        if (first_empty_block == last_occupied_block) {
            return true;
        }

        if (first_empty_block.is_empty()) {
            self.first_empty_block = first_empty_block.next;
            return false;
        }

        if (last_occupied_block.file_id == null) {
            self.last_occupied_block = last_occupied_block.previous;
            return false;
        }

        assert(first_empty_block.is_empty());
        assert(!last_occupied_block.is_empty());

        var empty_block: ?*Block = first_empty_block;

        while (empty_block) |target| {
            if (!target.is_empty()) {
                empty_block = target.next;
                continue;
            }
            if (target.size > last_occupied_block.size) {
                empty_block = target.next;
                continue;
            } else if (target.size == last_occupied_block.size) {
                target.file_id = last_occupied_block.file_id;
                last_occupied_block.file_id = null;
                return false;
            } else {
                target.file_id = last_occupied_block.file_id;
                const remaining_space = target.size - last_occupied_block.size;
                target.size = last_occupied_block.size;

                const block = try allocator.create(Block);
                block.* = Block{ .next = target.next, .previous = target, .size = remaining_space, .file_id = null };

                target.next = block;
                return false;
            }
        }
        return true;
    }

    fn checksum(self: Self) u64 {
        var sum: u64 = 0;
        var block = self.first_block;
        var index: u64 = 0;
        while (block) |b| {
            const size = b.size;
            if (b.file_id) |id| {
                sum += (size * id) + ((size - 1) * (size - 2)) / 2;
            }

            index += size;
            block = b.next;
        }
        return sum;
    }
};

const Block = struct {
    const Self = @This();

    next: ?*Block,
    previous: ?*Block,
    size: BlockSize,
    file_id: ?FileId,

    fn is_empty(self: Self) bool {
        return self.file_id == null;
    }
};

const FileId = u16;

// between 0 and 9
const BlockSize = u4;
