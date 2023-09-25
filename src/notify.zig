const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const log = std.log;

const c = @cImport(@cInclude("libnotify/notify.h"));

var state: struct {
    inited: bool = false,
    succeeded: bool = false,

    const Self = @This();

    fn init(self: *Self, retry: bool) bool {
        if (retry and !self.succeeded) {
            self.inited = false;
            self.succeeded = false;
        }

        if (self.inited) return self.succeeded;

        self.inited = true;
        self.succeeded = c.notify_init("cthulhu") == 1;
        return self.succeeded;
    }

    fn deinit(self: *Self) void {
        if (self.inited and self.succeeded) {
            c.notify_uninit();
        }
    }
} = .{};

const Urgency = enum(c_uint) { low, normal, critical };

// param timeout: milliseconds
export fn cthulhu_notify(summary: [*:0]const u8, body: [*:0]const u8, icon: [*:0]const u8, urgency: c_uint, timeout: c_int) c_int {
    // todo: deinit?
    if (!state.init(true)) return 0;

    // todo: release?
    const noti: *c.NotifyNotification = c.notify_notification_new(summary, body, icon);
    c.notify_notification_set_urgency(noti, blk: {
        const u = std.meta.intToEnum(Urgency, urgency) catch return 0;
        break :blk @intFromEnum(u);
    });
    c.notify_notification_set_timeout(noti, timeout);
    // todo: GError instead of null
    return c.notify_notification_show(noti, null);
}

fn gbool(val: c_int) bool {
    return val == 1;
}

test "libnotify: primitive way" {
    assert(gbool(c.notify_init("cthulhu")));
    defer c.notify_uninit();

    const noti: *c.NotifyNotification = c.notify_notification_new("hello", "world", null);
    c.notify_notification_set_urgency(noti, @intFromEnum(Urgency.normal));
    c.notify_notification_set_timeout(noti, std.time.ms_per_s * 2);
    assert(gbool(c.notify_notification_show(noti, null)));
}

test "libnotify: cthulhu way" {
    defer state.deinit();
    assert(gbool(cthulhu_notify("世界", "你好", "", @intFromEnum(Urgency.normal), 5_000)));
}
