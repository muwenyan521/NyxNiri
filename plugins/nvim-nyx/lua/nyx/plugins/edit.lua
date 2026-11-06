-- Editing helpers: formatting, text objects, small quality-of-life plugins.
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        fish = { "fish_indent" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        vue = { "prettier" },
        svelte = { "prettier" },
        go = { "gofmt" },
        rust = { "rustfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
      },
      formatters = {
        ruff_fix = { prepend_args = { "--fix-only" } },
        clang_format = { prepend_args = { "-style=file", "-fallback-style=LLVM" } },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].disable_autoformat then
          return nil
        end
        return { timeout_ms = 1200, lsp_format = "fallback" }
      end,
      default_format_opts = { lsp_format = "fallback" },
      notify_on_error = true,
    },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
  },
  {
    "nvim-mini/mini.nvim",
    version = false,
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup({ n_lines = 500, search_method = "cover_or_next" })
      require("mini.surround").setup({ mappings = { add = "sa", delete = "sd", find = "sf", find_left = "sF", highlight = "sh", replace = "sr" } })
      require("mini.pairs").setup()
      require("mini.bufremove").setup()
      require("mini.comment").setup()
      require("mini.move").setup({ mappings = { left = "<M-h>", right = "<M-l>", down = "<M-j>", up = "<M-k>" } })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    init = function()
      vim.g.nyx_treesitter_parsers = {
        "bash",
        "c",
        "cpp",
        "css",
        "diff",
        "dockerfile",
        "fish",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "html",
        "javascript",
        "json",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "ssh_config",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      }
    end,
    config = function()
      require("nvim-treesitter").setup({})
      require("nvim-treesitter").install(vim.g.nyx_treesitter_parsers)
    end,
  },
  {
    "Wansmer/treesj",
    keys = {
      { "<leader>js", function() require("treesj").split() end, desc = "Split node" },
      { "<leader>jj", function() require("treesj").join() end, desc = "Join node" },
      { "<leader>jt", function() require("treesj").toggle() end, desc = "Toggle node" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = { use_default_keymaps = false, max_join_length = 400 },
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = false,
      keywords = {
        FIX = { alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { alt = { "HACK", "XXX" } },
        WARN = { alt = { "WARNING" } },
        PERF = { alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { alt = { "INFO" } },
        TEST = { alt = { "TESTING", "PASSED", "FAILED" } },
      },
      highlight = { multiline = true, keyword = "wide", before = "", after = "fg" },
      search = { pattern = [[\b(KEYWORDS)\b]] },
    },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo" },
      { "<leader>ft", "<cmd>TodoQuickFix<cr>", desc = "Todos (quickfix)" },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = { enabled = true, jump_labels = true, multi_line = true },
        search = { enabled = true },
      },
      label = { uppercase = false },
    },
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
      { "R", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "Flash treesitter search" },
      { "<C-s>", function() require("flash").toggle() end, mode = { "c" }, desc = "Toggle flash search" },
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { dir = vim.fn.stdpath("state") .. "/sessions" },
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Stop recording session" },
    },
  },
  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = { "*" },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        names = false,
        AARRGGBB = false,
        css = true,
        mode = "virtualtext",
        virtualtext = "■",
        always_update = false,
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = { opts = { enable_close = true, enable_rename = true, enable_close_on_slash = true } },
  },
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
}
