const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");

    const submods = [_]struct { so: []const u8, src: []const u8 }{
        .{ .so = "cthulhu-md5", .src = "src/md5.zig" },
        .{ .so = "cthulhu-str", .src = "src/str.zig" },
    };

    inline for (submods) |def| {
        const so = b.addSharedLibrary(.{
            .name = def.so,
            .target = target,
            .root_source_file = b.path(def.src),
            .optimize = optimize,
        });
        b.installArtifact(so);

        const t = b.addTest(.{
            .root_source_file = b.path(def.src),
            .optimize = optimize,
        });
        const a = b.addRunArtifact(t);
        test_step.dependOn(&a.step);
    }

    {
        const so = b.addSharedLibrary(.{
            .name = "cthulhu-notify",
            .target = target,
            .root_source_file = b.path("src/notify.zig"),
            .optimize = optimize,
            .link_libc = true,
        });
        so.linkSystemLibrary("libnotify");
        b.installArtifact(so);
    }
    {
        const t = b.addTest(.{
            .root_source_file = b.path("src/notify.zig"),
            .optimize = optimize,
            .link_libc = true,
        });
        t.linkSystemLibrary("libnotify");
        const a = b.addRunArtifact(t);
        test_step.dependOn(&a.step);
    }

    {
        const so = b.addSharedLibrary(.{
            .name = "cthulhu-rime",
            .target = target,
            .root_source_file = b.path("src/rime.zig"),
            .optimize = optimize,
            .link_libc = true,
        });
        so.linkSystemLibrary("dbus-1");
        b.installArtifact(so);
    }

    {
        const so = b.addSharedLibrary(.{
            .name = "cthulhu-nvim",
            .target = target,
            .root_source_file = b.path("src/nvim.zig"),
            .optimize = optimize,
            .link_libc = true,
        });
        so.addIncludePath(b.path("include"));
        b.installArtifact(so);
    }
}
