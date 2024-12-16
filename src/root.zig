pub const solutions: [16]?type =
    .{null} ** 14 ++ .{
    @import("solutions/day15/solution.zig"),
    @import("solutions/day16/solution.zig"),
};

comptime {
    @import("std").testing.refAllDeclsRecursive(@This());
}
