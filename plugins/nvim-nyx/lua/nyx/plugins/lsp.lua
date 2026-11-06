-- Language servers, completion and diagnostics.
-- Servers come from the system package manager (no mason); a server is only
-- enabled when its binary actually exists, so a partial install degrades quietly.
return {
  {
    "saghen/blink.cmp",
    lazy = false,
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" },
      fuzzy = { implementation = "lua" },
      snippets = { preset = "default" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true, window = { border = "rounded" } },
      completion = {
        ghost_text = { enabled = true },
        list = { selection = { preselect = false, auto_insert = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          window = { border = "rounded", max_width = 80, max_height = 20 },
        },
        menu = {
          border = "rounded",
          draw = { treesitter = { "lsp" }, gap = 1, columns = { { "kind_icon" }, { "label", gap = 1 }, { "source_name" } } },
        },
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "Lazy" } },
      },
      integrations = { lspconfig = true, cmp = true },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile", "BufEnter" },
    dependencies = { "saghen/blink.cmp", "folke/lazydev.nvim" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.lsp.config("*", {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT", pathStrict = true },
            diagnostics = { globals = { "vim", "Snacks", "Lazy" }, unusedLocal = false },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
            format = { enable = false },
            hint = { enable = true, arrayIndex = "Disable" },
          },
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              inlayHints = { variableTypes = true, functionReturnTypes = true },
            },
          },
        },
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            usePlaceholders = true,
            completeUnimported = true,
            analyses = { unusedparams = true, shadow = false },
            staticcheck = true,
            hints = { assignVariableTypes = true, parameterNames = true },
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            inlayHints = { bindingModeHints = { enable = true }, closureReturnTypeHints = { enable = "always" } },
            checkOnSave = false,
            cargo = { allFeatures = true },
          },
        },
      })

      vim.lsp.config("clangd", {
        cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu", "--completion-style=detailed" },
      })

      vim.lsp.config("bashls", {
        settings = { bashIde = { shellcheckPath = vim.fn.executable("shellcheck") == 1 and "shellcheck" or "" } },
      })

      -- typescript-language-server is installed through npm, while tsserver comes
      -- from the system package. v6 dropped --tsserver-path, so pass it through
      -- initializationOptions instead.
      local tsserver = vim.fn.exepath("tsserver")
      if tsserver ~= "" then
        vim.lsp.config("ts_ls", {
          init_options = { tsserver = { path = tsserver } },
        })
      end

      local wanted = {
        lua_ls = "lua-language-server",
        lazydev = "lua-language-server",
        pyright = "pyright-langserver",
        gopls = "gopls",
        rust_analyzer = "rust-analyzer",
        clangd = "clangd",
        bashls = "bash-language-server",
        jsonls = "vscode-json-language-server",
        yamlls = "yaml-language-server",
        cssls = "vscode-css-language-server",
        html = "vscode-html-language-server",
        ts_ls = "typescript-language-server",
        marksman = "marksman",
        taplo = "taplo",
      }

      local enabled = {}
      for server, binary in pairs(wanted) do
        if vim.fn.executable(binary) == 1 then
          enabled[#enabled + 1] = server
        end
      end
      table.sort(enabled)
      vim.lsp.enable(enabled)

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { silent = true, desc = "Definition" })
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { silent = true, desc = "Declaration" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { silent = true, desc = "References" })
      vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { silent = true, desc = "Type definition" })
      vim.keymap.set("n", "gI", vim.lsp.buf.implementation, { silent = true, desc = "Implementation" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { silent = true, desc = "Hover" })
      vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { silent = true, desc = "Signature help" })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buf = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          if client:supports_method("textDocument/inlayHint", buf) then
            vim.lsp.inlay_hint.enable(false, { bufnr = buf })
          end

          if client.name == "lua_ls" then
            vim.opt_local.foldmethod = "expr"
          end

          -- Diagnostics live in the gutter and float on demand, not inline.
          vim.opt_local.signcolumn = "yes"
          vim.diagnostic.config({
            virtual_text = { spacing = 2, source = "if_many", prefix = "" },
            signs = { text = { [vim.diagnostic.severity.ERROR] = "●", [vim.diagnostic.severity.WARN] = "●", [vim.diagnostic.severity.INFO] = "●", [vim.diagnostic.severity.HINT] = "●" } },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = { border = "rounded", source = true, max_width = 80 },
          }, buf)
        end,
      })

      local toggle_hints = function()
        local enabled_hints = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
        vim.lsp.inlay_hint.enable(not enabled_hints, { bufnr = 0 })
        vim.notify("Inlay hints " .. (enabled_hints and "off" or "on"))
      end
      vim.keymap.set("n", "<leader>ci", toggle_hints, { silent = true, desc = "Toggle inlay hints" })
    end,
  },
}
