local ffi = require("ffi")

local resolve_plugin_root = require("infra.resolve_plugin_root")

ffi.cdef([[
  int cthulhu_notify(const char *summary, const char *body, const char *icon, unsigned int urgency, int timeout);
  void cthulhu_md5hex(const char *str, char *digest[32]);
  int cthulhu_rime_ascii_mode();
  bool cthulhu_nvim_dump_buffer(int32_t bufnr, const char *outfile, int32_t start, int32_t stop);
  int8_t cthulhu_nvim_silent();
  bool cthulhu_nvim_is_empty_line(int32_t bufnr, int32_t lnum);
  long cthulhu_nvim_last_msg_time();
  int64_t cthulhu_str_rfind(const char *haystack, const char *needle);
]])

local libs
do
  local lib_root = string.format("%s/zig-out/lib", resolve_plugin_root("cthulhu"))

  local function resolve_path(name)
    if name ~= "libcthulhu" then name = "libcthulhu-" .. name end
    return string.format("%s/%s.so", lib_root, name)
  end

  libs = setmetatable({}, {
    __index = function(t, key)
      local path = resolve_path(key)
      local ok, lib = pcall(ffi.load, path, false)
      if not ok then error(string.format("failed to load %s from %s: %s", key, path, lib)) end
      t[key] = lib
      return lib
    end,
  })
end

return {
  notify = function(...) return libs.notify.cthulhu_notify(...) end,
  md5hex = function(...) return libs.md5.cthulhu_md5hex(...) end,
  rime_ascii_mode = function(...) return libs.rime.cthulhu_rime_ascii_mode(...) end,
  nvim_dump_buffer = function(...) return libs.nvim.cthulhu_nvim_dump_buffer(...) end,
  nvim_silent = function() return libs.nvim.cthulhu_nvim_silent() end,
  nvim_is_empty_line = function(...) return libs.nvim.cthulhu_nvim_is_empty_line(...) end,
  nvim_last_msg_time = function(...) return libs.nvim.cthulhu_nvim_last_msg_time(...) end,
  str_rfind = function(...) return libs.str.cthulhu_str_rfind(...) end,
}
