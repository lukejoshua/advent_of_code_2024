const std = @import("std");

pub fn next_line(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}
pub fn next_line_alloc(reader: std.io.AnyReader, allocator: std.mem.Allocator) !?[]const u8 {
    // TODO: use the streaming API
    const line = reader.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(u16)) catch |err| switch (err) {
        error.EndOfStream => return null,
        else => unreachable,
    };

    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}
