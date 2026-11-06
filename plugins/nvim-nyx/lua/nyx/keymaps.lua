-- Keymaps. Leader is <Space>. Everything is grouped so which-key can label it.
local map = vim.keymap.set
local M = {}

local function cmd(c) return function() vim.cmd(c) end end
local function nmap(lhs, rhs, desc) map("n", lhs, rhs, { silent = true, desc = desc }) end
local function vmap(lhs, rhs, desc) map("x", lhs, rhs, { silent = true, desc = desc }) end
local function tmap(lhs, rhs, desc) map("t", lhs, rhs, { silent = true, desc = desc }) end

--- Resolve a snacks picker lazily so a broken plugin never bricks a keymap.
local function picker(source, opts)
  return function()
    local ok, snacks = pcall(require, "snacks")
    if not ok or not snacks.picker then
      vim.notify("snacks.picker is unavailable", vim.log.levels.WARN)
      return
    end
    snacks.picker[source](opts)
  end
end

local function action(path, opts)
  return function()
    local ok, snacks = pcall(require, "snacks")
    if not ok then
      vim.notify("snacks is unavailable", vim.log.levels.WARN)
      return
    end
    local fn = snacks
    for part in path:gmatch("[^%.]+") do fn = fn and fn[part] end
    if type(fn) ~= "function" then
      vim.notify("snacks." .. path .. " is unavailable", vim.log.levels.WARN)
      return
    end
    fn(opts)
  end
end

M.picker = picker
M.action = action

-- Core
nmap("<leader>w", cmd("write"), "Save buffer")
nmap("<leader>q", cmd("quit"), "Quit window")
nmap("<leader>Q", cmd("qa"), "Quit all")
nmap("<leader>x", cmd("x"), "Save and quit")
map("n", "<C-s>", cmd("write"), { silent = true, desc = "Save buffer" })
nmap("<Esc>", cmd("nohlsearch"), "Clear search highlight")
nmap("<leader>L", cmd("Lazy"), "Plugin manager")

-- Files & search
nmap("<leader>ff", picker("files"), "Find files")
nmap("<leader>fF", picker("files", { hidden = true, ignored = true }), "Find files (all)")
nmap("<leader>fg", picker("grep"), "Grep project")
nmap("<leader>fG", picker("grep_word"), "Grep word under cursor")
nmap("<leader>fw", picker("grep_word"), "Grep word under cursor")
nmap("<leader>fb", picker("buffers"), "Buffers")
nmap("<leader>fr", picker("recent"), "Recent files")
nmap("<leader>fc", picker("command_history"), "Command history")
nmap("<leader>fs", picker("smart"), "Smart find")
nmap("<leader>fn", picker("notifications"), "Notifications")
nmap("<leader>fp", picker("projects"), "Projects")
nmap("<leader>fh", picker("help"), "Help tags")
nmap("<leader>fk", picker("keymaps"), "Keymaps")
nmap("<leader>fm", picker("marks"), "Marks")
nmap("<leader>f/", picker("lines"), "Search lines")
nmap("<leader>:", picker("commands"), "Commands")
nmap("<leader>e", action("explorer"), "File explorer")
nmap("<leader>E", action("explorer", { reveal = true }), "Explorer at file")

-- Buffers
nmap("<leader>bd", action("bufdelete"), "Delete buffer")
nmap("<leader>bD", action("bufdelete", { force = true }), "Delete buffer (force)")
nmap("<S-l>", cmd("bnext"), "Next buffer")
nmap("<S-h>", cmd("bprevious"), "Previous buffer")
nmap("<leader>`", cmd("e #"), "Last buffer")
nmap("<leader>bp", picker("buffers", { focus = "buf_name" }), "Pick buffer")

-- Windows & splits
nmap("<C-h>", "<C-w>h", "Window left")
nmap("<C-j>", "<C-w>j", "Window down")
nmap("<C-k>", "<C-w>k", "Window up")
nmap("<C-l>", "<C-w>l", "Window right")
nmap("<leader>sv", cmd("vsplit"), "Split vertical")
nmap("<leader>sh", cmd("split"), "Split horizontal")
nmap("<leader>sx", cmd("close"), "Close split")
nmap("<leader>so", cmd("only"), "Only this window")
nmap("<C-Up>", cmd("resize +2"), "Resize taller")
nmap("<C-Down>", cmd("resize -2"), "Resize shorter")
nmap("<C-Left>", cmd("vertical resize -2"), "Resize narrower")
nmap("<C-Right>", cmd("vertical resize +2"), "Resize wider")

-- Tabs
nmap("<leader>tn", cmd("tabnew"), "New tab")
nmap("<leader>tx", cmd("tabclose"), "Close tab")
nmap("]t", cmd("tabnext"), "Next tab")
nmap("[t", cmd("tabprevious"), "Previous tab")

-- Movement / editing
nmap("<A-j>", "<cmd>m .+1<cr>==", "Move line down")
nmap("<A-k>", "<cmd>m .-2<cr>==", "Move line up")
vmap("<A-j>", ":m '>+1<cr>gv=gv", "Move selection down")
vmap("<A-k>", ":m '<-2<cr>gv=gv", "Move selection up")
vmap("<", "<gv", "Outdent and reselect")
vmap(">", ">gv", "Indent and reselect")
map("n", "<C-d>", "<C-d>zz", { silent = true, desc = "Half page down (centred)" })
map("n", "<C-u>", "<C-u>zz", { silent = true, desc = "Half page up (centred)" })
nmap("n", "nzzzv", "Next match (centred)")
nmap("N", "Nzzzv", "Previous match (centred)")
nmap("<leader>y", '"+y', "Yank to clipboard")
vmap("<leader>y", '"+y', "Yank to clipboard")
nmap("<leader>P", '"+p', "Paste from clipboard")
nmap("<leader>p", '"_dP', "Paste without clobbering register")
nmap("<leader>d", '"_d', "Delete to black hole")
vmap("<leader>d", '"_d', "Delete to black hole")
vmap("p", '"_dP', "Paste without clobbering register")
nmap("<leader>rw", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", "Replace word in file")
nmap("<leader>ij", picker("git_files"), "Git files")

-- Diagnostics / quickfix
local function trouble(opts)
  return function()
    local ok, mod = pcall(require, "trouble")
    if not ok then
      vim.notify("trouble.nvim is unavailable", vim.log.levels.WARN)
      return
    end
    mod.toggle(opts)
  end
end
nmap("<leader>xx", trouble({ mode = "diagnostics" }), "Trouble: diagnostics")
nmap("<leader>xX", trouble({ mode = "diagnostics", filter = { buf = 0 } }), "Trouble: buffer")
nmap("<leader>xL", trouble({ mode = "loclist" }), "Trouble: location list")
nmap("<leader>xQ", trouble({ mode = "qflist" }), "Trouble: quickfix")
nmap("<leader>xd", vim.diagnostic.open_float, "Diagnostic float")
nmap("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
nmap("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
nmap("[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end, "Previous error")
nmap("]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true }) end, "Next error")
nmap("<leader>dl", vim.diagnostic.setloclist, "Diagnostics to loclist")
nmap("<leader>dq", vim.diagnostic.setqflist, "Diagnostics to quickfix")
nmap("<leader>co", cmd("copen"), "Open quickfix")
nmap("<leader>cc", cmd("cclose"), "Close quickfix")
nmap("<leader>cn", cmd("cnext"), "Quickfix next")
nmap("<leader>cp", cmd("cprev"), "Quickfix previous")

-- Git
nmap("<leader>gg", action("lazygit"), "Lazygit")
nmap("<leader>gl", action("lazygit", { current_file = true }), "Lazygit (this file)")
nmap("<leader>gs", action("picker", { source = "git_status" }), "Git status")
nmap("<leader>gb", action("picker", { source = "git_branches" }), "Git branches")
nmap("<leader>gc", action("picker", { source = "git_commits" }), "Git commits")
nmap("<leader>gS", action("picker", { source = "git_stash" }), "Git stash")
nmap("<leader>gp", action("gitbrowse"), "Open in browser")
nmap("<leader>gd", function() require("gitsigns").diffthis() end, "Diff this")
nmap("<leader>gB", function() require("gitsigns").blame_line({ full = true }) end, "Blame line")
nmap("<leader>gr", function() require("gitsigns").reset_hunk() end, "Reset hunk")
nmap("<leader>gR", function() require("gitsigns").reset_buffer() end, "Reset buffer")
nmap("<leader>gP", function() require("gitsigns").preview_hunk() end, "Preview hunk")

-- Terminals, scratch, writing modes
nmap("<leader>tt", action("terminal"), "Terminal (float)")
nmap("<leader>th", action("terminal", { win = { position = "bottom", height = 0.3 } }), "Terminal (bottom)")
nmap("<leader>tb", action("terminal", { win = { position = "right", width = 0.35 } }), "Terminal (right)")
nmap("<leader>tz", action("zen"), "Zen mode")
nmap("<leader>.", action("scratch"), "Scratch buffer")
nmap("<leader>S", function() require("persistence").select() end, "Restore session")
nmap("<leader>qS", function() require("persistence").save() end, "Save session")

-- File operations
nmap("<leader>rn", action("rename"), "Rename file")
nmap("<leader>yf", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
end, "Copy file path")
nmap("<leader>cd", function()
  local dir = vim.fn.expand("%:p:h")
  vim.fn.setreg("+", dir)
  vim.notify("Copied " .. dir, vim.log.levels.INFO)
end, "Copy file directory")
nmap("<leader>cr", function() vim.cmd("cd " .. vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")) end, "cd to file dir")
nmap("<leader>eC", function()
  vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.stdpath("config") .. "/lua/nyx/__custom__.lua"))
end, "Edit personal overrides")

-- Toggles
local function toggle(option)
  return function()
    vim.opt_local[option] = not vim.opt_local[option]:get()
    vim.notify(option .. " = " .. tostring(vim.opt_local[option]:get()))
  end
end
nmap("<leader>uw", toggle("wrap"), "Toggle wrap")
nmap("<leader>us", toggle("spell"), "Toggle spell")
nmap("<leader>un", toggle("relativenumber"), "Toggle relative numbers")
nmap("<leader>ul", toggle("list"), "Toggle invisible chars")
nmap("<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, "Toggle diagnostics")
nmap("<leader>uT", function()
  local ok, snacks = pcall(require, "snacks")
  if ok then
    snacks.terminal.toggle()
  end
end, "Toggle terminal")

-- Theme
nmap("<leader>uD", function() vim.cmd("NyxTheme dark") end, "Theme: dark")
nmap("<leader>uL", function() vim.cmd("NyxTheme light") end, "Theme: light")
nmap("<leader>ut", function() vim.cmd("NyxTheme toggle") end, "Theme: toggle")

-- Formatting & code
nmap("<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, "Format buffer")
nmap("<leader>cF", function() require("conform").format({ async = true, lsp_format = "fallback", formatters = {} }) end, "Format range")
nmap("<leader>cy", function() vim.fn.setreg("+", vim.fn.expand("<cword>")) end, "Copy word")
nmap("<leader>ck", function() vim.lsp.buf.hover() end, "Hover")
nmap("<leader>ca", function() vim.lsp.buf.code_action() end, "Code action")
nmap("<leader>crn", function() vim.lsp.buf.rename() end, "Rename symbol")
nmap("<leader>cs", function() vim.lsp.buf.signature_help() end, "Signature help")

-- Treesj
nmap("<leader>js", function() require("treesj").split() end, "Split node")
nmap("<leader>jj", function() require("treesj").join() end, "Join node")
nmap("<leader>jt", function() require("treesj").toggle() end, "Toggle node")

-- Terminal mode
tmap("<Esc><Esc>", "<C-\\><C-n>", "Leave terminal mode")
tmap("<C-h>", "<C-\\><C-n><C-w>h", "Window left")
tmap("<C-j>", "<C-\\><C-n><C-w>j", "Window down")
tmap("<C-k>", "<C-\\><C-n><C-w>k", "Window up")
tmap("<C-l>", "<C-\\><C-n><C-w>l", "Window right")

-- Insert mode niceties
map("i", "<C-h>", "<Left>", { silent = true })
map("i", "<C-j>", "<Down>", { silent = true })
map("i", "<C-k>", "<Up>", { silent = true })
map("i", "<C-l>", "<Right>", { silent = true })
map("i", "jk", "<Esc>", { silent = true, desc = "Leave insert mode" })

return M
