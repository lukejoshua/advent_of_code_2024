pub const solutions: [15]?type = .{
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    @import("solutions/day15/solution.zig"),
};

comptime {
    @import("std").testing.refAllDeclsRecursive(@This());
}
