const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const assert = std.debug.assert;
const math = std.math;
const Allocator = mem.Allocator;
const is_test = @import("builtin").is_test;

pub const input = @embedFile("input.txt");
const DEBUG = false;

const log = std.log.scoped(.day16);

const Map = [][]Cell;
const Cell = enum { wall, empty };

const Position = struct {
    row: u32,
    column: u32,
};

const Direction = enum {
    const Self = @This();

    up,
    down,
    left,
    right,

    // Result of rotating ±90 degrees
    fn rotations(self: Self) [2]Direction {
        return switch (self) {
            .up, .down => .{ .left, .right },
            .left, .right => .{ .up, .down },
        };
    }
};

const StateWithCost = struct {
    const Self = @This();

    state: State,
    cost: u32,
};

const State = struct {
    const Self = @This();

    row: u32,
    column: u32,
    direction: Direction,

    fn next(self: Self, cost: u32) [3]StateWithCost {
        var result: [3]StateWithCost = undefined;
        const directions = self.direction.rotations();
        result[0] = StateWithCost{ .state = self.rotate(directions[0]), .cost = cost + 1000 };
        result[1] = StateWithCost{ .state = self.rotate(directions[1]), .cost = cost + 1000 };
        result[2] = StateWithCost{ .state = self.forward(), .cost = cost + 1 };
        return result;
    }

    fn rotate(self: Self, direction: Direction) Self {
        return Self{ .row = self.row, .column = self.column, .direction = direction };
    }

    fn forward(self: Self) Self {
        return switch (self.direction) {
            .up => Self{ .row = self.row - 1, .column = self.column, .direction = self.direction },
            .down => Self{ .row = self.row + 1, .column = self.column, .direction = self.direction },
            .left => Self{ .row = self.row, .column = self.column - 1, .direction = self.direction },
            .right => Self{ .row = self.row, .column = self.column + 1, .direction = self.direction },
        };
    }
};

const StateSet = struct {
    const Self = @This();

    const Inner = std.AutoHashMap(State, u32);

    // OPTIMIZE: would this be better as a dynamic bit set?
    // That wouldn't require additional allocations after init.
    set: *Inner,
    allocator: Allocator,

    fn init(allocator: Allocator) !Self {
        const set = try allocator.create(Inner);
        set.* = Inner.init(allocator);
        return Self{
            .set = set,
            .allocator = allocator,
        };
    }

    fn deinit(self: Self) void {
        self.set.deinit();
        self.allocator.destroy(self.set);
    }

    fn get(self: Self, state: State) ?u32 {
        return self.set.get(state);
    }

    // Return true iff the cost is lower than the current cost for that state.
    // If the state has not been encountered, the current cost is infinity.
    fn update(self: Self, state: State, cost: u32) !bool {
        const existing_state = try self.set.getOrPut(state);

        if (existing_state.found_existing and cost >= existing_state.value_ptr.*) {
            return false;
        }

        existing_state.value_ptr.* = cost;
        return true;
    }

    fn compare(self: Self, a: State, b: State) math.Order {
        const cost_of_a = self.get(a) orelse unreachable;
        const cost_of_b = self.get(b) orelse unreachable;

        // The builtin priority queue type seems to treat items with equal
        // priority as being the same item. So we must explicitly prioritize
        // earlier items over later ones.

        if (cost_of_a != cost_of_b) {
            return math.order(cost_of_a, cost_of_b);
        }

        if (a.row != b.row) {
            return math.order(a.row, b.row);
        }

        if (a.column != b.column) {
            return math.order(a.column, b.column);
        }

        return math.order(@intFromEnum(a.direction), @intFromEnum(b.direction));
    }
};

pub fn part1(allocator: Allocator, comptime file: []const u8) !u64 {
    var rows = std.ArrayList([]Cell).init(allocator);
    var line_iterator = mem.splitSequence(u8, file, "\n");
    var start: Position = undefined;
    var end: Position = undefined;

    var row_count: u32 = 0;
    while (line_iterator.next()) |line| {
        const row = try allocator.alloc(Cell, line.len);
        for (line, 0..) |character, c| {
            switch (character) {
                '#' => row[c] = .wall,
                '.' => row[c] = .empty,
                'E' => {
                    row[c] = .empty;
                    end = Position{ .row = row_count, .column = @intCast(c) };
                },
                'S' => {
                    row[c] = .empty;
                    start = Position{ .row = row_count, .column = @intCast(c) };
                },
                else => {
                    log.err("Unexpected grid character: {c}\n", .{character});
                    unreachable;
                },
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

    const known_costs = try StateSet.init(allocator);
    defer known_costs.deinit();

    var queue = std.PriorityQueue(State, StateSet, StateSet.compare).init(allocator, known_costs);
    defer queue.deinit();

    const starting_state = State{ .column = start.column, .row = start.row, .direction = .right };
    const is_less_than_current = try known_costs.update(starting_state, 0);
    assert(is_less_than_current);
    try queue.add(starting_state);

    while (queue.removeOrNull()) |cheapest_state| {
        const cost = known_costs.get(cheapest_state) orelse unreachable;
        // std.debug.print("current: ({}, {}) {s} @{}\n", .{ cheapest_state.row, cheapest_state.column, @tagName(cheapest_state.direction), cost });

        if (cheapest_state.column == end.column and cheapest_state.row == end.row) {
            return cost;
        }

        const next_states = cheapest_state.next(cost);

        for (next_states) |next_state| {
            const row = next_state.state.row;
            const column = next_state.state.column;

            if (grid[row][column] == .wall) {
                continue;
            }

            if (try known_costs.update(next_state.state, next_state.cost)) {
                try queue.add(next_state.state);
            }
        }
    }
    unreachable;
}

pub fn part2(allocator: Allocator, file: []const u8) !u64 {
    var rows = std.ArrayList([]Cell).init(allocator);
    var line_iterator = mem.splitSequence(u8, file, "\n");
    var start: Position = undefined;
    var end: Position = undefined;

    var row_count: u32 = 0;
    while (line_iterator.next()) |line| {
        const row = try allocator.alloc(Cell, line.len);
        for (line, 0..) |character, c| {
            switch (character) {
                '#' => row[c] = .wall,
                '.' => row[c] = .empty,
                'E' => {
                    row[c] = .empty;
                    end = Position{ .row = row_count, .column = @intCast(c) };
                },
                'S' => {
                    row[c] = .empty;
                    start = Position{ .row = row_count, .column = @intCast(c) };
                },
                else => {
                    log.err("Unexpected grid character: {c}\n", .{character});
                    unreachable;
                },
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

    const known_costs = try StateSet.init(allocator);
    defer known_costs.deinit();

    var queue = std.PriorityQueue(State, StateSet, StateSet.compare).init(allocator, known_costs);
    defer queue.deinit();

    const starting_state = State{ .column = start.column, .row = start.row, .direction = .right };
    const is_less_than_current = try known_costs.update(starting_state, 0);
    assert(is_less_than_current);
    try queue.add(starting_state);

    while (queue.removeOrNull()) |cheapest_state| {
        const cost = known_costs.get(cheapest_state) orelse unreachable;
        // std.debug.print("current: ({}, {}) {s} @{}\n", .{ cheapest_state.row, cheapest_state.column, @tagName(cheapest_state.direction), cost });

        if (cheapest_state.column == end.column and cheapest_state.row == end.row) {
            continue;
        }

        const next_states = cheapest_state.next(cost);

        for (next_states) |next_state| {
            const row = next_state.state.row;
            const column = next_state.state.column;

            if (grid[row][column] == .wall) {
                continue;
            }

            if (try known_costs.update(next_state.state, next_state.cost)) {
                try queue.add(next_state.state);
            }
        }
    }

    return 0;
}

test "part 1 small example" {
    try testing.expectEqual(7036, part1(testing.allocator, @embedFile("example-small.txt")));
}

test "part 1 large example" {
    try testing.expectEqual(11048, part1(testing.allocator, @embedFile("example-large.txt")));
}

test "part 2 small example" {
    try testing.expectEqual(45, part2(testing.allocator, @embedFile("example-small.txt")));
}

test "part 2 large example" {
    try testing.expectEqual(64, part2(testing.allocator, @embedFile("example-large.txt")));
}

// This is super ineffecient, but logging is borked
fn print(map: Map) !void {
    if (!DEBUG) return;
    for (map) |row| {
        for (row) |cell| {
            const char: u8 = switch (cell) {
                .empty => '.',
                .wall => '#',
            };
            std.debug.print("{c}", .{char});
        }

        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}
