-- Autocommands: filetype tuning, quality-of-life, and theme re-application hooks.
local augroup = vim.api.nvim_create_augroup("NyxCore", { clear = true })

local function on(event, pattern, callback, desc)
  vim.api.nvim_create_autocmd(event, {
    group = augroup,
    pattern = pattern,
    callback = callback,
    desc = desc,
  })
end

-- Restore the cursor where it was left.
on("BufReadPost", "*", function(args)
  local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
  local lines = vim.api.nvim_buf_line_count(args.buf)
  if mark[1] > 0 and mark[1] <= lines then
    pcall(vim.api.nvim_win_set_cursor, 0, mark)
  end
end, "Restore last cursor position")

-- Keep splits balanced when the terminal resizes.
on("VimResized", "*", function()
  vim.cmd("tabdo wincmd =")
end, "Equalise splits on resize")

-- Pick up changes made outside Neovim.
on({ "FocusGained", "BufEnter", "CursorHold" }, "*", function()
  if vim.fn.mode() ~= "c" then
    pcall(vim.cmd, "checktime")
  end
end, "Reload changed files")

-- Tree-sitter + folds per buffer.
on("FileType", "*", function(args)
  local ft = vim.bo[args.buf].filetype
  if vim.treesitter and vim.treesitter.start then
    pcall(vim.treesitter.start, args.buf)
  end
  if ft ~= "" and ft ~= "bigfile" and ft ~= "snacks_dashboard" then
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo[0][0].foldlevel = 99
  end
end, "Enable treesitter and folds")

-- Filetype specifics.
local ft_settings = {
  markdown = { wrap = true, spell = true, conceallevel = 2, concealcursor = "nc" },
  gitcommit = { wrap = true, spell = true, colorcolumn = "72" },
  text = { wrap = true, spell = true },
  yaml = { shiftwidth = 2, tabstop = 2 },
  json = { shiftwidth = 2, tabstop = 2 },
  jsonc = { shiftwidth = 2, tabstop = 2 },
  toml = { shiftwidth = 2, tabstop = 2 },
  lua = { shiftwidth = 2, tabstop = 2 },
  python = { shiftwidth = 4, tabstop = 4, softtabstop = 4, colorcolumn = "88" },
  go = { expandtab = false, shiftwidth = 4, tabstop = 4, list = false },
  rust = { shiftwidth = 4, tabstop = 4 },
  c = { shiftwidth = 2, tabstop = 2 },
  cpp = { shiftwidth = 2, tabstop = 2 },
  make = { expandtab = false },
  fish = { shiftwidth = 4, tabstop = 4 },
  sh = { shiftwidth = 4, tabstop = 4 },
  css = { shiftwidth = 2, tabstop = 2 },
  html = { shiftwidth = 2, tabstop = 2 },
  javascript = { shiftwidth = 2, tabstop = 2 },
  typescript = { shiftwidth = 2, tabstop = 2 },
}

on("FileType", vim.tbl_keys(ft_settings), function(args)
  local opts = ft_settings[vim.bo[args.buf].filetype]
  if not opts then
    return
  end
  for key, value in pairs(opts) do
    vim.opt_local[key] = value
  end
end, "Per-filetype options")

-- Terminal buffers should not show line numbers or status columns.
on("TermOpen", "*", function()
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.colorcolumn = ""
  vim.opt_local.spell = false
end, "Terminal buffer options")

-- Tools that need your care: no auto-format, keep indentation as written.
on("FileType", { "gitcommit", "diff" }, function()
  vim.b.disable_autoformat = true
end, "Disable autoformat for special buffers")

-- Show the cursorline only in the active window.
on({ "WinEnter", "BufEnter" }, "*", function()
  vim.opt_local.cursorline = true
end, "Cursorline on enter")
on({ "WinLeave" }, "*", function()
  vim.opt_local.cursorline = false
end, "Cursorline off leave")

-- Trim trailing whitespace, quietly, without moving the cursor.
vim.api.nvim_create_user_command("NyxTrim", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  vim.fn.winrestview(view)
end, { desc = "Trim trailing whitespace" })

-- Theme commands
vim.api.nvim_create_user_command("NyxTheme", function(args)
  local mode = args.args
  if mode == "" or mode == "toggle" then
    mode = vim.o.background == "light" and "dark" or "light"
  end
  if mode ~= "dark" and mode ~= "light" then
    vim.notify("NyxTheme: use dark, light or toggle", vim.log.levels.WARN)
    return
  end
  vim.o.background = mode
  vim.cmd("colorscheme nyx")
  vim.notify("Nyx theme: " .. mode)
end, { nargs = "?", complete = function() return { "dark", "light", "toggle" } end })

vim.api.nvim_create_user_command("NyxReload", function()
  vim.cmd("colorscheme nyx")
  vim.notify("Nyx theme reloaded from " .. require("nyx.palette").token_path())
end, { desc = "Re-read Nyx tokens" })

-- Reload the palette when the desktop theme file changes.
local token_mtime = nil
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = augroup,
  callback = function()
    local path = require("nyx.palette").token_path()
    local stat = vim.uv.fs_stat(path)
    local mtime = stat and stat.mtime.sec or nil
    if token_mtime == nil then
      token_mtime = mtime
      return
    end
    if mtime and mtime ~= token_mtime then
      token_mtime = mtime
      pcall(vim.cmd, "colorscheme nyx")
    end
  end,
  desc = "Follow Nyx token changes",
})
