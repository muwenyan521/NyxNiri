vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.statusline = " %f  %m%=%{&filetype}  %l:%c "
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.scrolloff = 6
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.completeopt = { "menu", "menuone", "noselect" }

local function find_files()
  local root = vim.fn.getcwd()
  local files = {}
  if vim.fn.executable("fd") == 1 then
    local result = vim.system({ "fd", "--type", "f", "--hidden", "--exclude", ".git", "--print0", "." }, {
      cwd = root,
      text = true,
    }):wait()
    if result.code == 0 then
      for item in (result.stdout or ""):gmatch("([^%z]+)") do
        files[#files + 1] = vim.fs.joinpath(root, item:gsub("^%./", ""))
      end
    end
  end
  if #files == 0 then
    files = vim.fs.find(function(_, path)
      return not path:find("/.git/", 1, true)
    end, {
      path = root,
      type = "file",
      limit = math.huge,
    })
  end
  table.sort(files)
  vim.ui.select(files, {
    prompt = "Nyx files",
    format_item = function(item)
      return vim.fs.relpath(root, item) or item
    end,
  }, function(choice)
    if choice then
      vim.cmd("edit " .. vim.fn.fnameescape(choice))
    end
  end)
end

local palette = dofile(vim.fn.stdpath("config") .. "/lua/nyx-theme.lua")
palette.apply()

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ higroup = "NyxYank", timeout = 160 }) end,
})
vim.api.nvim_create_autocmd("ColorScheme", { callback = palette.apply })

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
vim.keymap.set("n", "<leader>ff", find_files, { desc = "Find file" })
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "File explorer" })
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New tab" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "  NYXNIRI / EDITOR",
        "",
        "  <Space>ff  find file        <Space>e   explorer",
        "  <Space>w   write            <Space>q   quit",
        "",
      })
      vim.bo.modified = false
      vim.bo.buftype = "nofile"
      vim.bo.bufhidden = "wipe"
      vim.bo.filetype = "nyx-dashboard"
    end
  end,
})
