const std = @import("std");
const mem = std.mem;
const log = std.log;

const h = @cImport(@cInclude("nvim.h"));

fn dumpBufferImpl(bufnr: i32, outfile: []const u8, start: i32, stop: i32) !bool {
    if (start < 0 or stop < start) return error.InvalidRange;

    const buf = h.buflist_findnr(bufnr);
    if (buf == null) return error.NoSuchBuffer;

    var file = try std.fs.createFileAbsolute(outfile, .{});
    defer file.close();

    // ml_get_buf uses 1-based lnum
    var i = start + 1;
    while (i < stop + 1) : (i += 1) {
        // note: when lnum out of bounds, `???` occurs
        const cline = h.ml_get_buf(buf, i, false);
        const line = mem.span(cline);
        try file.writeAll(line);
        try file.writeAll("\n");
    }

    return true;
}

export fn cthulhu_dump_buffer(bufnr: i32, outfile: [*:0]const u8, start: i32, stop: i32) bool {
    return dumpBufferImpl(bufnr, mem.span(outfile), start, stop) catch |err| {
        log.err("{}", .{err});
        return false;
    };
}

fn isEmptyLineImpl(bufnr: i32, lnum: i32) !bool {
    const buf = h.buflist_findnr(bufnr);
    if (buf == null) return error.NoSuchBuffer;
    const cline: [*c]u8 = h.ml_get_buf(buf, lnum + 1, false);
    return cline[0] == 0;
}

export fn cthulhu_is_empty_line(bufnr: i32, lnum: i32) bool {
    return isEmptyLineImpl(bufnr, lnum) catch |err| {
        // todo: maybe raise a lua error
        // no better way for now, let it crash
        @panic(@errorName(err));
    };
}

export fn cthulhu_silent() i8 {
    var silent: i8 = 0;
    if (h.msg_silent != 0) silent |= 1;
    if (h.emsg_silent != 0) silent |= 2;
    return silent;
}
