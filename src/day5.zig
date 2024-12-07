const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const next_line_alloc = @import("./helpers.zig").next_line_alloc;

pub fn part1(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    const input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    var total: u64 = 0;
    outer: for (input.updates) |update| {
        std.debug.print("update: {any}\n", .{update});
        for (update, 0..) |page, index| {
            for (update[index + 1 ..]) |later_page| {
                if (!input.is_allowed(page, later_page)) {
                    std.debug.print("{}->{} is not allowed\n", .{ page, later_page });
                    continue :outer;
                }
            }
        }
        const score = update[(update.len / 2)];
        std.debug.print("Success: Add {} to the total\n", .{score});
        total += score;
    }

    return total;
}

test "part 1 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part1(std.testing.allocator, reader);
    try std.testing.expectEqual(143, answer);
}

pub fn part2(allocator: mem.Allocator, file_reader: std.io.AnyReader) !u64 {
    const input = try Input.parse(allocator, file_reader);
    defer input.deinit();

    var total: u64 = 0;
    for (input.updates) |update| {
        std.debug.print("update: {any}\n", .{update});
        const is_ordered = blk: {
            for (update, 0..) |page, index| {
                for (update[index + 1 ..]) |later_page| {
                    if (!input.is_allowed(page, later_page)) {
                        break :blk false;
                    }
                }
            }
            break :blk true;
        };

        if (is_ordered) {
            continue;
        }

        std.sort.block(u32, update, input, struct {
            fn f(context: Input, lhs: u32, rhs: u32) bool {
                return context.is_allowed(lhs, rhs);
            }
        }.f);

        const score = update[(update.len / 2)];
        std.debug.print("Success: Add {} to the total\n", .{score});
        total += score;
    }

    return total;
}

test "part 2 example" {
    var stream = std.io.fixedBufferStream(example);
    const reader = stream.reader().any();
    const answer = try part2(std.testing.allocator, reader);
    try std.testing.expectEqual(123, answer);
}

const example =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

const Input = struct {
    const Self = @This();
    const Update = []u32;
    const Rule = [2]u32;

    rules: *std.AutoHashMap(Rule, void),
    updates: []Update,
    allocator: mem.Allocator,

    fn is_allowed(self: Self, first: u32, second: u32) bool {
        return self.rules.contains(.{ first, second }) and !self.rules.contains(.{ second, first });
    }

    fn deinit(self: Self) void {
        self.rules.clearAndFree();
        self.allocator.destroy(self.rules);
        for (self.updates) |update| {
            self.allocator.free(update);
        }
        self.allocator.free(self.updates);
    }

    fn parse(allocator: mem.Allocator, file_reader: anytype) !Self {
        // TODO: this can't be the proper way to return a heap-allocated hashmap pointer, right???
        var rules = try allocator.create(std.AutoHashMap(Rule, void));
        rules.* = std.AutoHashMap(Rule, void).init(allocator);

        // ordering rules
        while (true) {
            // TODO: This can be done without the allocator
            const line = (try next_line_alloc(file_reader, allocator)).?;
            defer allocator.free(line);

            if (line.len == 0) {
                break;
            }

            var numbers = std.mem.tokenizeScalar(u8, line, '|');

            const before = try std.fmt.parseUnsigned(u32, numbers.next().?, 10);
            const after = try std.fmt.parseUnsigned(u32, numbers.next().?, 10);
            assert(numbers.next() == null);

            try rules.put(.{ before, after }, undefined);
        }

        // updates
        var updates = std.ArrayList(Update).init(allocator);

        while (true) {
            const line = try next_line_alloc(file_reader, allocator) orelse break;
            defer allocator.free(line);

            var numbers = std.mem.tokenizeScalar(u8, line, ',');
            var update = std.ArrayList(u32).init(allocator);

            while (numbers.next()) |number| {
                const page = try std.fmt.parseUnsigned(u32, number, 10);
                try update.append(page);
            }

            const u = try update.toOwnedSlice();
            try updates.append(u);
        }

        return .{ .allocator = allocator, .rules = rules, .updates = try updates.toOwnedSlice() };
    }
};
