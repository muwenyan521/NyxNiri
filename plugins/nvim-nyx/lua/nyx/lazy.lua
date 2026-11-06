-- lazy.nvim bootstrap. Cloned only once; every later start is served from disk.
local M = {}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("lazy.nvim bootstrap failed:\n" .. out, vim.log.levels.ERROR)
    return false
  end
end

vim.opt.rtp:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if not ok then
  vim.notify("lazy.nvim could not be loaded: " .. tostring(lazy), vim.log.levels.ERROR)
  return false
end

lazy.setup("nyx.plugins", {
  install = { missing = true },
  checker = { enabled = false, notify = false },
  change_detection = { notify = false, enabled = true },
  ui = { border = "rounded", backdrop = 55 },
  rocks = { enabled = false },
  readme = { enabled = false },
  performance = {
    cache = { enabled = true },
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

M.lazypath = lazypath
return true
