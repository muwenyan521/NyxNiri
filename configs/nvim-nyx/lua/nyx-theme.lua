local M = {}

local fallback = {
  surface = "#111820", surface_dim = "#0a0f14", surface_bright = "#24313b",
  primary = "#62d8e7", secondary = "#ff9f8e", tertiary = "#f2c66d",
  error = "#ffb4ab", on_surface = "#e6f1f4", on_surface_var = "#a9bdc4",
  outline = "#78929b",
}

local function read_tokens()
  local home = vim.env.HOME or vim.fn.expand("~")
  local path = vim.env.NYXNIRI_TOKEN_FILE or (home .. "/.config/niri/nyx-tokens.toml")
  local file = io.open(path, "r")
  if not file then return fallback end
  local values = vim.deepcopy(fallback)
  local section = ""
  local selected = vim.o.background == "light" and "light" or "dark"
  for line in file:lines() do
    local current = line:match("^%[color%.([%w_]+)%]")
    if current then section = current end
    local key, value = line:match("^([%w_]+)%s*=%s*\"(#[0-9a-fA-F]+)\"")
    if key and values[key] ~= nil and (section == selected or section == "") then values[key] = value end
  end
  file:close()
  return values
end

function M.apply()
  local p = read_tokens()
  vim.cmd("highlight clear")
  vim.cmd("syntax reset")
  vim.g.colors_name = "nyx"
  local groups = {
    Normal = { fg = p.on_surface, bg = p.surface_dim },
    NormalFloat = { fg = p.on_surface, bg = p.surface },
    FloatBorder = { fg = p.outline, bg = p.surface },
    FloatTitle = { fg = p.primary, bg = p.surface, bold = true },
    WinBar = { fg = p.on_surface_var, bg = p.surface_dim },
    WinBarNC = { fg = p.outline, bg = p.surface_dim },
    PmenuSbar = { bg = p.surface_bright },
    PmenuThumb = { bg = p.primary },
    CursorLine = { bg = p.surface },
    LineNr = { fg = p.outline, bg = p.surface_dim },
    CursorLineNr = { fg = p.primary, bold = true },
    Visual = { fg = p.surface_dim, bg = p.primary },
    Search = { fg = p.surface_dim, bg = p.tertiary },
    IncSearch = { fg = p.surface_dim, bg = p.secondary },
    Pmenu = { fg = p.on_surface, bg = p.surface },
    PmenuSel = { fg = p.surface_dim, bg = p.primary, bold = true },
    StatusLine = { fg = p.surface_dim, bg = p.primary, bold = true },
    StatusLineNC = { fg = p.on_surface_var, bg = p.surface },
    WinSeparator = { fg = p.outline },
    Comment = { fg = p.on_surface_var, italic = true },
    String = { fg = p.tertiary },
    Function = { fg = p.primary },
    Keyword = { fg = p.secondary },
    Type = { fg = p.primary },
    Constant = { fg = p.tertiary },
    DiagnosticError = { fg = p.error },
    DiagnosticWarn = { fg = p.tertiary },
    DiagnosticInfo = { fg = p.primary },
    DiagnosticHint = { fg = p.on_surface_var },
    DiagnosticVirtualTextError = { fg = p.error, bg = p.surface },
    DiagnosticVirtualTextWarn = { fg = p.tertiary, bg = p.surface },
    DiagnosticVirtualTextInfo = { fg = p.primary, bg = p.surface },
    DiagnosticVirtualTextHint = { fg = p.on_surface_var, bg = p.surface },
    DiffAdd = { fg = p.primary, bg = p.surface },
    DiffChange = { fg = p.tertiary, bg = p.surface },
    DiffDelete = { fg = p.secondary, bg = p.surface },
    NonText = { fg = p.surface_bright },
    NyxYank = { fg = p.surface_dim, bg = p.secondary },
    NyxDashboardTitle = { fg = p.primary, bold = true },
  }
  for name, opts in pairs(groups) do vim.api.nvim_set_hl(0, name, opts) end
end

return M
