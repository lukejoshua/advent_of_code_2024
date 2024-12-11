const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const day1 = @import("./day1.zig");
const day2 = @import("./day2.zig");
const day3 = @import("./day3.zig");
const day4 = @import("./day4.zig");
const day5 = @import("./day5.zig");
const day6 = @import("./day6.zig");
const day6part2 = @import("./day6part2.zig");
const day7 = @import("./day7.zig");
const day8 = @import("./day8.zig");
const day9 = @import("./day9.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            std.debug.print("Memory leak!", .{});
        }
    }

    const allocator = gpa.allocator();

    // TODO: Run in parallel?
    {
        const file = try std.fs.cwd().openFile("data/day1.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day1.part1(allocator, file.reader());
        std.debug.print("day 1 part 1: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day1.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day1.part2(allocator, file.reader());
        std.debug.print("day 1 part 2: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day2.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day2.part1(allocator, file.reader());
        std.debug.print("day 2 part 1: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day2.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day2.part2(allocator, file.reader());
        std.debug.print("day 2 part 2: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day3.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day3.part1(file.reader().any());
        std.debug.print("day 3 part 1: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day3.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day3.part2(file.reader().any());
        std.debug.print("day 3 part 2: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day4.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day4.part1(allocator, file.reader().any());
        std.debug.print("day 4 part 1: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day4.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day4.part2(allocator, file.reader().any());
        std.debug.print("day 4 part 2: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day5.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day5.part1(allocator, file.reader().any());
        std.debug.print("day 5 part 1: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day5.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day5.part2(allocator, file.reader().any());
        std.debug.print("day 5 part 2: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day6.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day6.part1(allocator, file.reader().any());
        std.debug.print("day 6 part 1: {d}\n", .{answer});
    }
    {
        const file = try std.fs.cwd().openFile("data/day6.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day6part2.part2(allocator, file.reader().any());
        std.debug.print("day 6 part 2: {d}\n", .{answer});
    }
    {
        const file = try std.fs.cwd().openFile("data/day7.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day7.part1(allocator, file.reader().any());
        std.debug.print("day 7 part 1: {d}\n", .{answer});
    }
    {
        const file = try std.fs.cwd().openFile("data/day7.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day7.part2(allocator, file.reader().any());
        std.debug.print("day 7 part 2: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day8.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day8.part1(allocator, file.reader().any());
        std.debug.print("day 8 part 1: {d}\n", .{answer});
    }

    {
        const file = try std.fs.cwd().openFile("data/day8.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day8.part2(allocator, file.reader().any());
        std.debug.print("day 8 part 2: {d}\n", .{answer});
    }
    {
        const file = try std.fs.cwd().openFile("data/day9.txt", .{ .mode = .read_only });
        defer file.close();
        const answer = try day9.part1(allocator, file.reader().any());
        std.debug.print("day 9 part 1: {d}\n", .{answer});
    }
}
