-- Editor options. Grouped by intent so it stays readable.
local opt = vim.opt

local state = vim.fn.stdpath("state")
local undo = state .. "/undo"
local swap = state .. "/swap"
vim.fn.mkdir(undo, "p")
vim.fn.mkdir(swap, "p")

-- Files & persistence
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.undodir = undo
opt.backup = false
opt.writebackup = false
opt.updatetime = 250
opt.autoread = true
opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,globals,terminal"
opt.shada = "!,'200,<50,s10,h,/200"

-- Clipboard & mouse (wl-clipboard is installed; falls back silently in TTY)
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.mousemoveevent = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.winborder = "rounded"
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorcolumn = false
opt.colorcolumn = { "100", "120" }
opt.laststatus = 3
opt.showmode = false
opt.ruler = false
opt.showcmd = false
opt.cmdheight = 1
opt.pumheight = 12
opt.pumblend = 10
opt.winblend = 0
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.breakindentopt = "shift:2,min:20"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹", lead = "·" }
opt.fillchars = { eob = " ", vert = "│", fold = " ", diff = "╱", msgsep = "‾" }
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.showtabline = 1
opt.tabline = ""
opt.title = true
opt.conceallevel = 0
opt.concealcursor = "nc"

-- Folds (treesitter driven; see autocmds)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldcolumn = "0"
opt.foldtext = ""

-- Editing
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true
opt.autoindent = true
opt.shiftround = true
opt.copyindent = true
opt.virtualedit = "block"
opt.formatoptions = "jcroqlnt"
opt.textwidth = 0
opt.completeopt = { "menu", "menuone", "noselect" }
opt.complete = ".,w,b,u,t,i"
opt.pumblend = 10
opt.confirm = true
opt.inccommand = "split"
opt.diffopt = "internal,filler,closeoff,linematch:60,algorithm:histogram,indent-heuristic"
opt.jumpoptions = "view"
opt.wildmode = "longest:full,full"
opt.wildignore = { "*.o", "*.obj", "*.pyc", "*.class", "*/node_modules/*", "*/.git/*", "*/target/*" }

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Timing
opt.timeoutlen = 400
opt.ttimeoutlen = 25
opt.redrawtime = 1500
opt.maxmempattern = 5000

-- Grep through ripgrep so :grep, quickfix and `-q` agree with the picker
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --no-heading --smart-case --hidden --glob=!.git/ -S"
  opt.grepformat = "%f:%l:%c:%m"
end

-- Spell check defaults: opt-in per filetype (markdown, gitcommit, text)
opt.spell = false
opt.spelllang = { "en" }
opt.spelloptions = "camel"
opt.spellsuggest = "best,9"

-- Misc
opt.iskeyword:append({ "-", "_" })
opt.joinspaces = false
opt.startofline = false
opt.selection = "inclusive"
opt.report = 2
opt.history = 2000
opt.pumwidth = 30

-- Netrw is replaced by snacks.explorer; keep it quiet if it ever loads
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- Let filetype plugins set indent but keep our 2-space default as the base
vim.g.editorconfig = true
