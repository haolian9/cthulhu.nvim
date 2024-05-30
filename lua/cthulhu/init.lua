local M = {}

local ffi = require("ffi")

local C = require("cthulhu.c")
local augroups = require("infra.augroups")
local jelly = require("infra.jellyfish")("cthulhu")
local strlib = require("infra.strlib")

local uv = vim.uv
local api = vim.api

do
  local nvim_icon = (function()
    local runtime = os.getenv("VIMRUNTIME")
    if runtime == nil then return end
    if not strlib.endswith(runtime, "/share/nvim/runtime") then return end
    local icon = string.format("%s/%s", string.sub(runtime, 1, #runtime - #"/nvim/runtime"), "icons/hicolor/128x128/apps/nvim.png")
    if uv.fs_stat(icon) ~= nil then return icon end
  end)() or ""

  local function notify(urgency)
    assert(urgency)

    ---@param summary string
    ---@param body string|nil
    ---@param timeout number|nil @1000ms
    ---@param icon string|nil
    return function(summary, body, icon, timeout)
      assert(summary ~= nil)
      body = body or ""
      icon = icon or nvim_icon
      timeout = timeout or 1000

      ---@diagnostic disable: undefined-field
      return C.notify(summary, body, icon, urgency, timeout) == 1
    end
  end

  M.notify = setmetatable({
    low = notify(0),
    normal = notify(1),
    critical = notify(2),
  }, {
    __call = function(cls, ...) return cls.normal(...) end,
  })
end

function M.md5(str)
  assert(str ~= nil)
  local len = 32
  local hex = ffi.new("char *[?]", len)
  C.md5hex(str, hex)
  return ffi.string(hex, len)
end

do
  local dbus_available = os.getenv("DISPLAY") ~= nil

  M.rime = {
    goto_ascii = function()
      if not dbus_available then return jelly.err("not in GUI env") end

      if C.rime_ascii_mode() ~= 1 then jelly.err("failed to set rime to ascii mode") end
    end,
    auto_ascii = function()
      if not dbus_available then return jelly.err("not in GUI env") end

      local aug = augroups.Augroup("cthulhu://rime/auto_ascii")
      aug:repeats("InsertLeave", { callback = function() M.rime.goto_ascii() end })
    end,
  }
end

M.nvim = {
  --dump content of the current buffer into file, including modified parts
  ---@param bufnr integer
  ---@param outfile string
  ---@param start integer?
  ---@param stop integer?
  ---@return boolean
  dump_buffer = function(bufnr, outfile, start, stop)
    assert(type(bufnr) == "number" and type(outfile) == "string")
    if bufnr == 0 then bufnr = api.nvim_get_current_buf() end
    start = start or 0
    stop = stop or api.nvim_buf_line_count(bufnr)
    return C.nvim_dump_buffer(bufnr, outfile, start, stop)
  end,
  ---@return boolean,boolean @silent, silent!
  silent = function()
    local val = C.nvim_silent()
    return bit.band(val, 1) == 1, bit.band(val, 2) == 2
  end,
  ---@param bufnr integer
  ---@param lnum integer @0-indexed
  ---@return boolean
  is_empty_line = function(bufnr, lnum)
    assert(type(bufnr) == "number" and type(lnum) == "number")
    if bufnr == 0 then bufnr = api.nvim_get_current_buf() end
    assert(api.nvim_buf_is_valid(bufnr))
    return C.nvim_is_empty_line(bufnr, lnum)
  end,
}

M.str = {
  ---@param haystack string
  ---@param needle string
  ---@return integer?
  rfind = function(haystack, needle)
    assert(type(haystack) == "string" and type(needle) == "string")
    local ret = tonumber(C.str_rfind(haystack, needle))
    if ret == -1 then return end
    return ret
  end,
}

return M
