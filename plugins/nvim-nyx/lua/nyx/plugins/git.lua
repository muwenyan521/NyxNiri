-- Git integration: per-line signs, hunk actions, blame.
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "-" },
        changedelete = { text = "~" },
        untracked = { text = "+" },
      },
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      watch_gitdir = { follow_files = true },
      attach_to_untracked = true,
      current_line_blame = false,
      current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 500 },
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = { border = "rounded", style = "minimal", relative = "cursor", row = 0, col = 1 },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function m(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end
        m("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        m("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Previous hunk")
        m("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        m("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
        m("n", "<leader>gh", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage")
        m("n", "<leader>gt", gs.toggle_current_line_blame, "Toggle blame")
        m("n", "<leader>gw", gs.toggle_word_diff, "Toggle word diff")
      end,
    },
  },
}
