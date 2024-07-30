local M = {}

local ffi = require("ffi")

local C = require("cthulhu.c")

local api = vim.api
local uv = vim.uv

do
  local nvim_icon = (function()
    local runtime = os.getenv("VIMRUNTIME")
    if runtime == nil then return end
    if string.sub(runtime, #"/share/nvim/runtime") == "/share/nvim/runtime" then return end
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
    ---@return boolean @succeeded or not
    goto_ascii = function()
      if not dbus_available then error("not in GUI env") end
      return C.rime_ascii_mode() == 1
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
  last_msg_time = function()
    local val = C.nvim_last_msg_time()
    return assert(tonumber(val))
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
