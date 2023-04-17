const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    const strip = mode != .Debug;

    const tests_step = b.step("test", "Run library tests");

    const submods = [_]struct { so: []const u8, src: []const u8 }{
        .{ .so = "cthulhu-md5", .src = "src/md5.zig" },
    };

    inline for (submods) |def| {
        const lib = b.addSharedLibrary(def.so, def.src, .unversioned);
        lib.setBuildMode(mode);
        lib.strip = strip;
        lib.install();

        const tests = b.addTest(def.src);
        tests_step.dependOn(&tests.step);
    }

    {
        const lib = b.addSharedLibrary("cthulhu-notify", "src/notify.zig", .unversioned);
        lib.setBuildMode(mode);
        lib.strip = strip;
        lib.linkLibC();
        lib.linkSystemLibrary("libnotify");
        lib.install();

        const tests = b.addTest("src/notify.zig");
        tests.linkLibC();
        tests.linkSystemLibrary("libnotify");
        tests_step.dependOn(&tests.step);
    }

    {
        const lib = b.addSharedLibrary("cthulhu-rime", "src/rime.zig", .unversioned);
        lib.setBuildMode(mode);
        lib.strip = strip;
        lib.linkLibC();
        lib.linkSystemLibrary("dbus-1");
        lib.install();
    }

    {
        const lib = b.addSharedLibrary("cthulhu-nvim", "src/nvim.zig", .unversioned);
        lib.setBuildMode(mode);
        lib.strip = strip;
        lib.linkLibC();
        lib.addIncludePath("include");
        lib.install();
    }
}
