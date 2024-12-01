const std = @import("std");
const ascii = std.ascii;
const assert = std.debug.assert;
const mem = std.mem;
const day1 = @import("./day1.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            std.debug.print("Memory leak!", .{});
        }
    }

    const allocator = gpa.allocator();

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
}
