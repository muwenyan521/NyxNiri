-- Statusline, key hints, cmdline and markdown rendering.
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("nyx.lualine").setup()
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 250,
      win = { border = "rounded", padding = { 0, 1 } },
      icons = { breadcrumb = "", separator = "›", group = "+", mappings = false },
      plugins = {
        marks = true,
        registers = true,
        spelling = { enabled = true, suggestions = 15 },
        presets = {
          operators = false,
          motions = false,
          text_objects = true,
          windows = true,
          nav = true,
          z = true,
          g = true,
        },
      },
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>r", group = "refactor" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>g", group = "git" },
        { "<leader>j", group = "split/join" },
        { "<leader>s", group = "split" },
        { "<leader>t", group = "tab/terminal" },
        { "<leader>u", group = "toggle" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>d", group = "delete" },
        { "<leader>y", group = "yank" },
        { "<leader>p", group = "paste" },
      },
    },
  },
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    event = "VeryLazy",
    opts = {
      auto_close = true,
      focus = true,
      win = { border = "rounded" },
      modes = {
        diagnostics = { win = { position = "bottom", size = 12 } },
        qflist = { win = { position = "bottom", size = 12 } },
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      cmdline = { enabled = true, view = "cmdline_popup" },
      messages = { enabled = false },
      popupmenu = { enabled = false },
      notify = { enabled = false },
      lsp = {
        progress = { enabled = true },
        hover = { enabled = false },
        signature = { enabled = false },
      },
      presets = {
        bottom_search = false,
        command_palette = false,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      routes = {
        { filter = { event = "msg_show", kind = "" }, opts = { skip = true } },
        { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
        { filter = { event = "notify", find = "written" }, opts = { skip = true } },
      },
      views = {
        cmdline_popup = { win_options = { winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder" } },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      file_types = { "markdown", "norg", "rmd", "org" },
      heading = { position = "overlay", sign = false, width = "full" },
      code = { style = "full", left_pad = 1, right_pad = 1, sign = false },
      bullet = { enabled = true },
      quote = { enabled = true },
      pipe_table = { preset = "round" },
      checkbox = { enabled = true, unchecked = "○", checked = "●" },
      link = { enabled = true },
    },
  },
}
