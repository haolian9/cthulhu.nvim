const std = @import("std");
const assert = std.debug.assert;
const fmt = std.fmt;

const Md5 = std.crypto.hash.Md5;
const hex_len = Md5.digest_length * 2;

export fn cthulhu_md5hex(in: [*:0]const u8, out: *[hex_len]u8) void {
    var digest: [Md5.digest_length:0]u8 = undefined;
    Md5.hash(std.mem.sliceTo(in, 0), &digest, .{});
    const filled = fmt.bufPrint(out, "{s}", .{fmt.fmtSliceHexLower(&digest)}) catch unreachable;
    assert(filled.len == out.len);
}

test "digest length" {
    assert(hex_len == 32);
}

test "hash" {
    const expected = "fc3ff98e8c6a0d3087d515c0473f8677";
    var hex: [hex_len:0]u8 = undefined;
    cthulhu_md5hex("hello world!", &hex);
    assert(std.mem.eql(u8, expected, &hex));
}

pub fn main() void {
    var hex: [hex_len]u8 = undefined;
    cthulhu_md5hex("hello world!", &hex);
    std.debug.print("{s}\n", .{&hex});
}
