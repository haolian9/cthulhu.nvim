local ffi = require("ffi")
local jelly = require("infra.jellyfish")("cthulhu", vim.log.levels.INFO)
local api = vim.api
local fs = require("infra.fs")

ffi.cdef([[
  int cthulhu_notify(const char *summary, const char *body, const char *icon, unsigned int urgency, int timeout);
  void cthulhu_md5hex(const char *str, char *digest[32]);
  int cthulhu_rime_ascii_mode();
  bool cthulhu_dump_buffer(int32_t bufnr, const char *outfile, size_t len);
  void cthulhu_no_lpl();
]])

local libs
do
  local root = fs.joinpath(vim.fn.stdpath("config"), "cthulhu")

  local function resolve_path(name)
    if name ~= "libcthulhu" then name = "libcthulhu-" .. name end
    return fs.joinpath(root, "zig-out/lib", name .. ".so")
  end

  libs = setmetatable({}, {
    __index = function(t, key)
      local path = resolve_path(key)
      local ok, lib = pcall(ffi.load, path, false)
      if not ok then return jelly.err("failed to load %s from %s: %s", key, path, lib) end
      t[key] = lib
      return lib
    end,
  })
end

return {
  notify = function(...) return libs.notify.cthulhu_notify(...) end,
  md5hex = function(...) return libs.md5.cthulhu_md5hex(...) end,
  rime_ascii_mode = function(...) return libs.rime.cthulhu_rime_ascii_mode(...) end,
  dump_buffer = function(...) return libs.nvim.cthulhu_dump_buffer(...) end,
  no_lpl = function() return libs.nvim.cthulhu_no_lpl() end,
}
