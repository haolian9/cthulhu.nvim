local M = {}

local ffi = require("ffi")
local C = require("cthulhu.c")
local jelly = require("infra.jellyfish")("cthulhu")

local uv = vim.loop
local api = vim.api

M.notify = (function()
  local nvim_icon = (function()
    local runtime = os.getenv("VIMRUNTIME")
    if runtime == nil then return end
    if not vim.endswith(runtime, "/share/nvim/runtime") then return end
    local icon = string.format("%s/%s", string.sub(runtime, 1, #runtime - #"/nvim/runtime"), "icons/hicolor/128x128/apps/nvim.png")
    local stat, errmsg, err = uv.fs_stat(icon)
    if stat ~= nil then return icon end
    if err == "ENOENT" then return end
    jelly.err(errmsg)
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

  return setmetatable({
    low = notify(0),
    normal = notify(1),
    critical = notify(2),
  }, {
    __call = function(cls, ...) return cls.normal(...) end,
  })
end)()

function M.md5(str)
  assert(str ~= nil)
  local len = 32
  local hex = ffi.new("char *[?]", len)
  C.md5hex(str, hex)
  return ffi.string(hex, len)
end

M.rime = (function()
  local dbus_available = os.getenv("DISPLAY") ~= nil

  return {
    goto_ascii = function()
      if not dbus_available then return jelly.err("not in GUI env") end

      ---@diagnostic disable: undefined-field
      if C.rime_ascii_mode() ~= 1 then jelly.err("failed to set rime to ascii mode") end
    end,
    auto_ascii = function()
      if not dbus_available then return jelly.err("not in GUI env") end

      -- todo: ModeChanged? ctrl-c
      api.nvim_create_autocmd({ "InsertLeave" }, {
        callback = function() M.goto_ascii() end,
      })
    end,
  }
end)()

M.nvim = {
  --dump content of the current buffer into file, including modified parts
  ---@param bufnr number
  ---@param outfile string
  ---@return boolean
  dump_buffer = function(bufnr, outfile)
    vim.validate({ bufnr = { bufnr, "number" }, outfile = { outfile, "string" } })
    if bufnr == 0 then bufnr = api.nvim_get_current_buf() end
    local len = api.nvim_buf_line_count(bufnr)
    return C.dump_buffer(bufnr, outfile, len)
  end,
  no_lpl = function() C.no_lpl() end,
}

return M
