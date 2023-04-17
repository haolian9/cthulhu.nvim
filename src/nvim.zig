const std = @import("std");
const mem = std.mem;
const log = std.log;

const h = @cImport(@cInclude("nvim.h"));

fn dumpBufferImpl(bufnr: i32, outfile: []const u8, len: usize) !bool {
    const buf = h.buflist_findnr(bufnr);
    if (buf == null) return error.NoSuchBuffer;

    var file = try std.fs.createFileAbsolute(outfile, .{});
    defer file.close();

    // ml_get_buf uses 1-based lnum
    var i: i32 = 1;
    while (i <= len) : (i += 1) {
        // note: when lnum out of bounds, `???` occurs
        const cline = h.ml_get_buf(buf, i, false);
        const line = mem.span(cline);
        try file.writeAll(line);
        // todo: line break varies
        try file.writeAll("\n");
    }

    return true;
}

export fn cthulhu_dump_buffer(bufnr: i32, outfile: [*:0]const u8, len: usize) bool {
    return dumpBufferImpl(bufnr, mem.span(outfile), len) catch |err| {
        log.err("{}", .{err});
        return false;
    };
}

export fn cthulhu_no_lpl() void {
    h.p_lpl = 0;
}
