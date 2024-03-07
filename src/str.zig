const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const testing = std.testing;

export fn cthulhu_str_rfind(chaystack: [*:0]const u8, cneedle: [*:0]const u8) i64 {
    const haystack = mem.span(chaystack);
    const needle = mem.span(cneedle);

    if (haystack.len < needle.len) return -1;

    var i: i64 = @intCast(haystack.len - needle.len);
    while (i >= 0) : (i -= 1) {
        const u: usize = @intCast(i);
        if (!mem.eql(u8, haystack[u .. u + needle.len], needle)) continue;
        return i + 1; // the index of lua list starts from 1 not 0
    }

    return -1;
}

test "rfind" {
    try testing.expectEqual(@as(i64, 0 + 1), cthulhu_str_rfind("hello", "h"));
    try testing.expectEqual(@as(i64, 1 + 1), cthulhu_str_rfind("hello", "e"));
    try testing.expectEqual(@as(i64, 3 + 1), cthulhu_str_rfind("hello", "l"));
    try testing.expectEqual(@as(i64, 4 + 1), cthulhu_str_rfind("hello", "o"));
    try testing.expectEqual(@as(i64, -1), cthulhu_str_rfind("hello", "x"));

    try testing.expectEqual(@as(i64, 0 + 1), cthulhu_str_rfind("hello", "he"));
    try testing.expectEqual(@as(i64, 2 + 1), cthulhu_str_rfind("hello", "ll"));
    try testing.expectEqual(@as(i64, 3 + 1), cthulhu_str_rfind("hello", "lo"));
    try testing.expectEqual(@as(i64, -1), cthulhu_str_rfind("hello", "hx"));

    try testing.expectEqual(@as(i64, 0 + 1), cthulhu_str_rfind("hello", "hello"));
    try testing.expectEqual(@as(i64, -1), cthulhu_str_rfind("hello", "helloo"));
}
