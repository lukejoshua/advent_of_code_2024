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

    // const part1Answer = try part1(gpa.allocator(), file);
    // std.debug.print("day 09 part 1: {}\n\n", .{part1Answer});
    // assert(part1Answer == 6421128769094);

    const part2Answer = try part2(file, gpa.allocator());
    std.debug.print("day 09 part 2: {}\n\n", .{part2Answer});
}

fn part1(file: []const u8, allocator: Allocator) !i64 {
    return solve(file, .allow_file_splitting, allocator);
}

fn part2(file: []const u8, allocator: Allocator) !u64 {
    return solve(file, .forbid_file_splitting, allocator);
}

const Disk = std.DoublyLinkedList(*Section);

const fragmentation_mode = enum { allow_file_splitting, forbid_file_splitting };

fn solve(file: []const u8, mode: fragmentation_mode, allocator: Allocator) !u64 {
    const disk = try allocator.create(Disk);
    disk.* = Disk{};

    defer {
        var node = disk.first;

        while (node) |n| {
            const next = n.next;
            allocator.destroy(n.data);
            allocator.destroy(n);
            node = next;
        }

        allocator.destroy(disk);
    }

    var is_file = true;
    var file_id: Section.FileId = 0;

    for (file) |character| {
        if (!ascii.isDigit(character)) break;

        const size: Section.Size = @intCast(character - '0');

        if (size != 0) {
            const node = try allocator.create(Disk.Node);
            const section = try allocator.create(Section);
            section.* = if (is_file) Section.file(size, file_id) else Section.empty(size);
            node.* = Disk.Node{ .data = section };

            disk.append(node);
        }

        if (is_file) {
            file_id += 1;
        }

        is_file = !is_file;
    }

    var right: ?*Disk.Node = disk.last;

    while (right) |rightmostFile| {
        print(disk, null, right);

        const source = rightmostFile.data;

        if (source.file_id == null) {
            right = rightmostFile.prev;
            continue;
        }

        assert(mode != .allow_file_splitting);

        if (mode == .forbid_file_splitting) {
            var left = disk.first;

            while (left) |leftmostEmptyNode| {
                const target = leftmostEmptyNode.data;
                print(disk, left, right);

                if (target == source) {
                    right = rightmostFile.prev;
                    break;
                }

                if (target.file_id == null and source.file_id == null) {
                    left = leftmostEmptyNode.next;
                    continue;
                }
                assert(!(target.file_id == null and source.file_id == null));

                if (target.file_id) |_| {
                    left = leftmostEmptyNode.next;
                    continue;
                }

                // This is where mode is important
                if (target.size < source.size) {
                    left = leftmostEmptyNode.next;
                    continue;
                }

                std.debug.print("moving file #{}\n", .{source.file_id.?});

                target.file_id = source.file_id;
                source.file_id = null;

                const empty_space_remaining = target.size - source.size;

                if (empty_space_remaining > 0) {
                    target.size = source.size;
                    const empty_block = try allocator.create(Disk.Node);
                    const section = try allocator.create(Section);
                    section.* = Section.empty(empty_space_remaining);
                    empty_block.* = Disk.Node{ .data = section };

                    disk.insertAfter(leftmostEmptyNode, empty_block);

                    right = rightmostFile.prev;
                    break;
                }

                right = rightmostFile.prev;
            }

            // right = rightmostFile.prev;
        } else {
            return 0;
            // TODO: continue
        }
    }

    std.debug.print("end\n", .{});
    var sum: u64 = 0;
    var cursor = disk.first;
    var index: usize = 0;

    while (cursor) |curs| {
        const section = curs.data;
        const size = section.size;
        const id = section.file_id orelse {
            index += size;
            cursor = curs.next;
            continue;
        };
        sum += (size * index + ((@as(u8, size) * @as(u8, size - 1))) / 2) * id;
        index += size;
        cursor = curs.next;
    }

    print(disk, null, null);
    return sum;
}

const example = "2333133121414131402";

test "part 1 example" {
    return error.SkipZigTest;
    // const actual = try part1(example, testing.allocator);
    // try std.testing.expectEqual(1928, actual);
}

test "part 2 example" {
    const actual = try part2(example, testing.allocator);
    try std.testing.expectEqual(2858, actual);
}

fn print(disk: *Disk, left: ?*Disk.Node, right: ?*Disk.Node) void {
    if (!DEBUG) return;

    var node = disk.first;

    while (node) |n| {
        const section = n.data;

        if (left == n) {
            // bold red
            std.debug.print("\x1B[1m", .{});
            std.debug.print("\x1B[0;31m", .{});
        } else if (right == n) {
            // bold green
            std.debug.print("\x1B[1m", .{});
            std.debug.print("\x1B[0;32m", .{});
        }

        if (section.file_id) |id| {
            std.debug.print("[#{} x {}] ", .{ id, section.size });
        } else {
            std.debug.print("[{} empty] ", .{section.size});
        }

        if (left == n or right == n) {
            std.debug.print("\x1B[0m", .{});
        }

        node = n.next;
    }
    std.debug.print("\n", .{});
}

const Section = struct {
    const Self = @This();

    const Size = u4;
    const FileId = u32;

    file_id: ?FileId,
    size: Size,

    fn empty(size: Size) Self {
        assert(size < 10);
        return .{ .file_id = null, .size = size };
    }

    fn file(size: Size, id: FileId) Self {
        assert(size < 10);
        return .{ .file_id = id, .size = size };
    }
};
