-- lualine configuration derived from the Nyx palette.
local palette = require("nyx.palette")
local M = {}

local function segments(p)
  local themes = {
    normal = {
      a = { fg = p.surface_dim, bg = p.primary, gui = "bold" },
      b = { fg = p.on_surface, bg = p.surface },
      c = { fg = p.on_surface_var, bg = p.raised },
      z = { fg = p.surface_dim, bg = p.primary },
    },
    insert = {
      a = { fg = p.surface_dim, bg = p.tertiary, gui = "bold" },
      b = { fg = p.on_surface, bg = p.surface },
      c = { fg = p.on_surface_var, bg = p.raised },
    },
    visual = {
      a = { fg = p.surface_dim, bg = p.secondary, gui = "bold" },
      b = { fg = p.on_surface, bg = p.surface },
      c = { fg = p.on_surface_var, bg = p.raised },
    },
    replace = {
      a = { fg = p.surface_dim, bg = p.error, gui = "bold" },
      b = { fg = p.on_surface, bg = p.surface },
      c = { fg = p.on_surface_var, bg = p.raised },
    },
    command = {
      a = { fg = p.surface_dim, bg = p.tertiary, gui = "bold" },
      b = { fg = p.on_surface, bg = p.surface },
      c = { fg = p.on_surface_var, bg = p.raised },
    },
    terminal = {
      a = { fg = p.surface_dim, bg = p.outline, gui = "bold" },
      b = { fg = p.on_surface, bg = p.surface },
      c = { fg = p.on_surface_var, bg = p.raised },
    },
    inactive = {
      a = { fg = p.comment, bg = p.surface_dim },
      b = { fg = p.comment, bg = p.surface_dim },
      c = { fg = p.comment, bg = p.surface_dim },
    },
  }

  -- lualine only needs a/b/c; mirror them onto x/y so the right-hand
  -- sections keep the same background instead of falling back to none.
  for _, mode in pairs(themes) do
    mode.x = mode.x or mode.c
    mode.y = mode.y or mode.c
  end
  return themes
end

local function lsp_name()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, client in ipairs(clients) do
    local name = client.name
    if name == "lua_ls" then
      name = "lua"
    end
    names[#names + 1] = name
  end
  return " " .. table.concat(names, ",")
end

function M.opts()
  local p = palette.get()
  local theme = segments(p)

  return {
    options = {
      theme = theme,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = { "snacks_dashboard", "dashboard", "alpha", "lazy", "noice", "help", "qf", "Trouble", "snacks_terminal" },
      },
      globalstatus = true,
      refresh = { statusline = 200, tabline = 200, winbar = 200 },
    },
    sections = {
      lualine_a = {
        {
          "mode",
          fmt = function(str)
            return ({ NORMAL = "N", INSERT = "I", VISUAL = "V", ["V-LINE"] = "VL", ["V-BLOCK"] = "VB", REPLACE = "R", COMMAND = "C", TERMINAL = "T" })[str] or str
          end,
        },
      },
      lualine_b = {
        { "branch", fmt = function(s) return s == "" and "" or ("git:" .. s) end },
        { "diff", symbols = { added = "+", modified = "~", removed = "-" }, colored = true },
        { "diagnostics", symbols = { error = "E", warn = "W", info = "I", hint = "H" }, update_in_insert = false },
      },
      lualine_c = {
        { "filename", path = 1, symbols = { modified = " ●", readonly = "", unnamed = "[No Name]" } },
        { lsp_name },
      },
      lualine_x = {
        {
          function()
            local ok, conform = pcall(require, "conform")
            if not ok then
              return ""
            end
            local names = conform.list_formatters_for_buffer(0)
            return names and #names > 0 and ("fmt:" .. table.concat(names, ",")) or ""
          end,
          color = { fg = p.comment },
        },
        { "filetype", colored = false, icon_only = false },
      },
      lualine_y = { { "progress", padding = { left = 1, right = 1 } } },
      lualine_z = { { "location", padding = { left = 0, right = 1 } } },
    },
    inactive_sections = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "location" },
    },
    tabline = {},
    extensions = { "lazy", "trouble", "quickfix" },
  }
end

function M.setup()
  require("lualine").setup(M.opts())
end

--- Re-render after a palette change (theme toggle / token reload).
function M.reload()
  if package.loaded["lualine"] then
    pcall(require("lualine").setup, M.opts())
  end
end

return M
