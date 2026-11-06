-- Nyx Neovim profile.
-- Loaded through NVIM_APPNAME=nvim-nyx, so it never collides with a vanilla
-- ~/.config/nvim. Colour, features and plugins all live under lua/nyx/.
if vim.g.nyx_loaded then
  return
end
vim.g.nyx_loaded = true

-- Leader must exist before any module registers a mapping.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("nyx.options")
require("nyx.keymaps")
require("nyx.autocmds")

-- Colours before plugins so the dashboard and floats are already themed.
local themed = pcall(vim.cmd.colorscheme, "nyx")
if not themed then
  vim.notify("Nyx: colourscheme failed to load", vim.log.levels.WARN)
end

-- Plugins. If the bootstrap fails (no network on first run), the editor stays
-- fully usable: options, keys and the Nyx palette are already in place.
local plugins_ok = require("nyx.lazy")

-- Plugins define their own groups while loading; repaint once they settle.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    pcall(function() require("nyx-theme").refresh() end)
  end,
})

-- Fallback splash when plugins are unavailable.
if not plugins_ok then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      local empty = vim.fn.argc() == 0 and vim.fn.line("$") == 1 and vim.fn.getline(1) == ""
      if not empty then
        return
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "  NYXNIRI / EDITOR  (plugins unavailable)",
        "",
        "  <Space>w   write      <Space>q   quit",
        "  <Space>ff  files      <Space>fg  grep",
        "",
        "  :Lazy  to inspect the plugin state",
      })
      vim.bo.modified = false
      vim.bo.buftype = "nofile"
      vim.bo.bufhidden = "wipe"
      vim.bo.filetype = "nyx-dashboard"
    end,
  })
end

-- Dunder Protocol: this file survives dotfile redeploys, so personal tweaks go
-- here instead of editing the managed modules.
pcall(require, "nyx.__custom__")
