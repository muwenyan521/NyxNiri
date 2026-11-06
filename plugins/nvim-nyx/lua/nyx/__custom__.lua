-- Personal overrides for the Nyx Neovim profile.
-- The dotfile deployer keeps any path containing `__custom__`, so edits here
-- survive `nyxniri install`. Everything else under lua/nyx/ is managed.
--
-- Examples:
--
--   vim.keymap.set("n", "<leader>qc", "<cmd>qa<cr>", { desc = "Quit all" })
--
--   vim.api.nvim_create_autocmd("FileType", {
--     pattern = "markdown",
--     callback = function() vim.wo.spell = true end,
--   })
--
--   require("nyx-theme").refresh()

return {}
