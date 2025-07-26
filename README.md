### Zig fetch
```bash
# This updates your build.zig.zon
zig fetch --save git+https://github.com/Jesperoka/zig-rgbapng
```

### Zig build
```zig
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "your_executable",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add rgbapng as a dependency, in the form of a module "rgbapng" that you can import.
    exe.root_module.addImport(
        "rgbapng",
        b.dependency("rgbapng", .{
            .target = target,
            .optimize = optimize,
        }).module("rgbapng"),
    );

    b.installArtifact(exe);
}
```

### Decode an RGBA png image
```zig
const rgbapng = @import("rgbapng");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    defer allocator.deinit();

    const image: rgbapng.Image = try rgbapng.decode(
        .{},
        "path/to/your/image.png",
        allocator,
    );
}
```

### Decode many RGBA png images, deallocate at end with arena.
```zig
const rgbapng = @import("rgbapng");
const PngDecodeError = rgbapng.PngDecodeError;
const PngDecodeConfig = rgbapng.PngDecodeConfig;
const Image = rgbapng.Image;

pub fn main() PngDecodeError!void {
    const IMAGE_PATHS = [_][]const u8{
        "path/to/your/image1.png",
        "path/to/your/image2.png",
        //...
        "path/to/your/imageN.png",
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var images: [IMAGE_PATHS.len]Image = undefined;

    for (IMAGE_PATHS, &images) |image_path, *image| {
        image.* = try decode(
            PngDecodeConfig{
                .optimistic = true,          // Forgo crc checks, header validation and runtime safety checks.
                .timing = true,              // Print how long different decoding steps take.
                .compressed_image_bytes = 0, // Not needed, but can be set to nonzero value if known.
            },
            image_path,
            arena.allocator(),
        );
    }
}
```

### Notes
- No dependencies, just Zig.

- Only does one allocation per image.

- **Not** faster than libpng or zigimg (haven't tested, but I'm assuming).
Most of the time is spent in the Zlib decompression and the reconstruction/unfiltering function,
so as those get faster we might approach similar speeds.

- Less code => Easy to understand. Only does the one thing is says it does.
I do **not** plan on adding any features apart from maybe some more comptime flags
to allow better performance or some other useful thing. I would rather make a separate
module *just* for encoding pngs if that is something I ever need to do, since then we don't
pull in **any** more code than what is actually being used by the depending project.
