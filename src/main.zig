const std = @import("std");
const ascii = std.ascii;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
// const day1 = @import("./day1.zig");
// const day2 = @import("./day2.zig");
// const day3 = @import("./day3.zig");
// const day4 = @import("./day4.zig");
// const day5 = @import("./day5.zig");
// const day6 = @import("./day6.zig");
// const day6part2 = @import("./day6part2.zig");
// const day7 = @import("./day7.zig");
// const day8 = @import("./day8.zig");

const solutions = @import("root.zig").solutions;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    const allocator = gpa.allocator();

    defer {
        const check = gpa.deinit();
        if (check == .leak) {
            std.debug.print("Memory leak!", .{});
        }
    }

    inline for (solutions, 0..) |solution, index| {
        var day: [2]u8 = undefined;
        _ = fmt.formatIntBuf(&day, index + 1, 10, .lower, fmt.FormatOptions{ .width = 2, .fill = '0' });

        const sol = solution orelse {
            print("Day {s} has not been implemented.\n", .{day});
            continue;
        };

        const parts = .{ "1", "2" };

        inline for (parts) |part| {
            const part_name = "part" ++ part;

            if (!@hasDecl(sol, part_name)) {
                std.debug.print("Day {s} part {s} is not implemented\n", .{ day, part });
                continue;
            }

            const part_fn = @field(sol, part_name);
            const function_type = @TypeOf(part_fn);
            const function_type_info = @typeInfo(function_type);
            const params = function_type_info.Fn.params;
            const requires_allocator = params.len > 0 and params[0].type == Allocator;

            const answer = if (requires_allocator) part_fn(allocator, sol.input) else part_fn(sol.input);
            const allocation_message = if (requires_allocator) "" else " (no alloc!!)";
            std.debug.print("Day {s} part {s} -> {!d}{s}\n", .{ day, part, answer, allocation_message });
        }
    }

    // const allocator = gpa.allocator();

    // TODO: Run in parallel?
    // {
    //     const file = try std.fs.cwd().openFile("data/day1.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day1.part1(allocator, file.reader());
    //     std.debug.print("day 1 part 1: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day1.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day1.part2(allocator, file.reader());
    //     std.debug.print("day 1 part 2: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day2.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day2.part1(allocator, file.reader());
    //     std.debug.print("day 2 part 1: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day2.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day2.part2(allocator, file.reader());
    //     std.debug.print("day 2 part 2: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day3.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day3.part1(file.reader().any());
    //     std.debug.print("day 3 part 1: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day3.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day3.part2(file.reader().any());
    //     std.debug.print("day 3 part 2: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day4.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day4.part1(allocator, file.reader().any());
    //     std.debug.print("day 4 part 1: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day4.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day4.part2(allocator, file.reader().any());
    //     std.debug.print("day 4 part 2: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day5.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day5.part1(allocator, file.reader().any());
    //     std.debug.print("day 5 part 1: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day5.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day5.part2(allocator, file.reader().any());
    //     std.debug.print("day 5 part 2: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day6.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day6.part1(allocator, file.reader().any());
    //     std.debug.print("day 6 part 1: {d}\n", .{answer});
    // }
    // {
    //     const file = try std.fs.cwd().openFile("data/day6.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day6part2.part2(allocator, file.reader().any());
    //     std.debug.print("day 6 part 2: {d}\n", .{answer});
    // }
    // {
    //     const file = try std.fs.cwd().openFile("data/day7.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day7.part1(allocator, file.reader().any());
    //     std.debug.print("day 7 part 1: {d}\n", .{answer});
    // }
    // {
    //     const file = try std.fs.cwd().openFile("data/day7.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day7.part2(allocator, file.reader().any());
    //     std.debug.print("day 7 part 2: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day8.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day8.part1(allocator, file.reader().any());
    //     std.debug.print("day 8 part 1: {d}\n", .{answer});
    // }
    //
    // {
    //     const file = try std.fs.cwd().openFile("data/day8.txt", .{ .mode = .read_only });
    //     defer file.close();
    //     const answer = try day8.part2(allocator, file.reader().any());
    //     std.debug.print("day 8 part 2: {d}\n", .{answer});
    // }

}
fn first_parameter_is_allocator(function_type: type) bool {
    const function_type_info = @typeInfo(function_type);
    return function_type_info.Fn.params[0].type == std.mem.Allocator;
}
