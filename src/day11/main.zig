const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

const DEBUG = false;

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
    return solve(allocator, file, 25);
}

fn part2(allocator: Allocator, file: []const u8) !i64 {
    return solve(allocator, file, 75);
}

fn solve(allocator: Allocator, file: []const u8, iterations: comptime_int) !i64 {
    const state = try allocator.create(State);
    defer allocator.destroy(state);

    state.* = State.init(allocator);
    defer state.deinit();

    var numbers = std.mem.tokenizeAny(u8, file, " \r\n");

    while (numbers.next()) |digits| {
        const number = try std.fmt.parseUnsigned(u64, digits, 10);
        try addOrSet(state, number, 1);
    }

    print(state.*, 0);

    for (0..iterations) |i| {
        try step(state, allocator);
        print(state.*, i + 1);
    }

    var values = state.valueIterator();
    var sum: i64 = 0;

    while (values.next()) |value| {
        // Couldn't be bothered to filter out zeroes rn
        assert(value.* >= 0);
        sum += value.*;
    }

    return sum;
}

fn step(state: *State, allocator: Allocator) !void {
    var diffs = State.init(allocator);
    defer diffs.deinit();

    var entries = state.iterator();

    while (entries.next()) |entry| {
        const stone = entry.key_ptr.*;
        const count = entry.value_ptr.*;

        if (count == 0) continue;

        if (stone == 0) {
            try addOrSet(&diffs, stone, -count);
            try addOrSet(&diffs, 1, count);
            continue;
        }

        const digit_count = std.math.log10_int(stone) + 1;

        if (digit_count % 2 == 0) {
            const shift = try std.math.powi(u64, 10, digit_count / 2);
            const left = stone / shift;
            const right = stone - (left * shift);

            try addOrSet(&diffs, stone, -count);
            try addOrSet(&diffs, left, count);
            try addOrSet(&diffs, right, count);

            continue;
        }

        try addOrSet(&diffs, stone, -count);
        try addOrSet(&diffs, stone * 2024, count);
    }

    var diffIterator = diffs.iterator();

    while (diffIterator.next()) |diff| {
        try addOrSet(state, diff.key_ptr.*, diff.value_ptr.*);
    }
}

fn addOrSet(state: *State, stone: u64, count: i64) !void {
    const entry = try state.getOrPut(stone);
    if (!entry.found_existing) {
        entry.value_ptr.* = 0;
    }

    entry.value_ptr.* += count;
}

test "part 1 example" {
    const actual = try part1(std.testing.allocator, "125 17");
    try std.testing.expectEqual(55312, actual);
}

fn print(state: State, round: usize) void {
    if (!DEBUG) return;

    var keys = state.keyIterator();

    std.debug.print("After {} round<(s):\n", .{round});
    while (keys.next()) |key| {
        std.debug.print("{} occurs {} times\n", .{ key.*, state.get(key.*).? });
    }
    std.debug.print("\n", .{});
}
