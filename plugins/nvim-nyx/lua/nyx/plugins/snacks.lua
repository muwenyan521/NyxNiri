-- snacks.nvim: the single UI layer (picker, dashboard, explorer, notifier, terminal,
-- indent, scope, statuscolumn, zen, lazygit, gitbrowse). Deliberately replaces
-- telescope / nvim-tree / nvim-notify / alpha / indent-blankline / toggleterm.
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000, style = "compact", top_down = false },
      scope = { enabled = true },
      scroll = { enabled = true },
      words = { enabled = true },
      git = { enabled = true },
      gitbrowse = { enabled = true },
      lazygit = { enabled = true },
      terminal = { enabled = true },
      image = { enabled = true },
      statuscolumn = {
        enabled = true,
        left = { "sign" },
        right = { "fold", "git" },
        folds = { open = "▾", closed = "▸" },
      },
      indent = {
        enabled = true,
        char = "│",
        scope = { char = "│", underline = false },
        animate = { enabled = false },
      },
      zen = {
        enabled = true,
        toggles = {
          dim = false,
          git_signs = false,
          diagnostics = false,
          inlay_hints = false,
          foldcolumn = false,
          line_numbers = false,
        },
        win = { width = 100 },
      },
      scratch = { enabled = true },
      explorer = { enabled = true, replace_netrw = true },
      picker = {
        enabled = true,
        sources = {
          files = { hidden = true, ignored = false },
          grep = { hidden = true },
          explore = { hidden = true, ignored = true },
        },
        win = {
          input = {
            keys = {
              ["<a-/>"] = { "toggle_focus", mode = { "i", "n" } },
              ["<C-s>"] = { "edit_split", mode = { "i", "n" } },
              ["<C-v>"] = { "edit_vsplit", mode = { "i", "n" } },
              ["<C-t>"] = { "edit_tab", mode = { "i", "n" } },
            },
          },
        },
      },
      dashboard = {
        enabled = true,
        width = 64,
        pane_gap = 4,
        preset = {
          header = [[
    _   ____  __   _  __
   / | / /\ \/ /  | |/ /
  /  |/ /  \  /   |   /
 / /|  /   / /   /   |
/_/ |_/   /_/   /_/|_|]],
          keys = {
            { icon = "", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
            { icon = "", key = "g", desc = "Grep Text", action = ":lua Snacks.picker.grep()" },
            { icon = "", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
            { icon = "", key = "b", desc = "Buffers", action = ":lua Snacks.picker.buffers()" },
            { icon = "", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
            { icon = "", key = "e", desc = "Explorer", action = ":lua Snacks.explorer()" },
            { icon = "", key = "s", desc = "Restore Session", action = ":lua require('persistence').select()" },
            { icon = "", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = "", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          {
            section = "startup",
            padding = 1,
          },
        },
      },
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      -- The dashboard is the only buffer where a statusline is pure noise.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "snacks_dashboard",
        callback = function()
          vim.opt_local.statusline = " "
          vim.opt_local.winbar = ""
          vim.opt_local.colorcolumn = ""
        end,
      })

      vim.api.nvim_create_user_command("NyxDashboard", function()
        Snacks.dashboard.open()
      end, { desc = "Open the Nyx dashboard" })
    end,
  },
}
