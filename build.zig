const std = @import("std");

pub fn build(b: *std.Build) void {
    const NAME = "rgbapng";
    const SOURCE = "rgbapng.zig";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule(NAME, .{
        .root_source_file = b.path(SOURCE),
        .target = target,
        .optimize = optimize,
    });

    _ = module;
}
