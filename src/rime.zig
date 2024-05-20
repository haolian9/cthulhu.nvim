const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log;

const c = @cImport(@cInclude("dbus/dbus.h"));

var state: struct {
    inited: bool = false,
    conn: *c.DBusConnection = undefined,

    const Self = @This();
    fn init(self: *Self) !void {
        if (self.inited) return;
        defer self.inited = true;
        self.conn = c.dbus_bus_get(c.DBUS_BUS_SESSION, null).?;
    }

    fn deinit(self: *Self) void {
        c.dbus_connection_unref(self.conn);
    }
} = .{};

fn isInAsciiMode(conn: *c.DBusConnection) bool {
    const msg = c.dbus_message_new_method_call("org.fcitx.Fcitx5", "/rime", "org.fcitx.Fcitx.Rime1", "IsAsciiMode");

    const reply = c.dbus_connection_send_with_reply_and_block(conn, msg, 250, null);
    assert(reply != null);
    defer c.dbus_message_unref(reply);

    var iter: c.DBusMessageIter = undefined;
    assert(c.dbus_message_iter_init(reply, &iter) == 1);
    const arg_type = c.dbus_message_iter_get_arg_type(&iter);
    assert(arg_type == c.DBUS_TYPE_BOOLEAN);
    var val: bool = false;
    c.dbus_message_iter_get_basic(&iter, &val);

    return val;
}

fn setToAsciiiMode(conn: *c.DBusConnection) void {
    const msg = c.dbus_message_new_method_call("org.fcitx.Fcitx5", "/rime", "org.fcitx.Fcitx.Rime1", "SetAsciiMode");
    assert(msg != null);

    var iter: c.DBusMessageIter = undefined;
    c.dbus_message_iter_init_append(msg, &iter);
    assert(c.dbus_message_iter_append_basic(&iter, c.DBUS_TYPE_BOOLEAN, &c.TRUE) == 1);

    assert(c.dbus_connection_send(conn, msg, 0) == 1);
    c.dbus_connection_flush(conn);
}

export fn cthulhu_rime_ascii_mode() callconv(.C) c_int {
    // todo: deinit
    state.init() catch unreachable;

    if (!isInAsciiMode(state.conn)) setToAsciiiMode(state.conn);
    return 1;
}

pub fn main() !void {
    try state.init();
    defer state.deinit();

    if (!isInAsciiMode(state.conn)) {
        setToAsciiiMode(state.conn);
        log.info("set to ascii mode", .{});
    } else {
        log.info("in ascii mode", .{});
    }
}
