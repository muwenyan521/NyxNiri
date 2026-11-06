-- Nyx palette bridge.
-- Single source of truth: ~/.config/niri/nyx-tokens.toml (overridable via NYXNIRI_TOKEN_FILE).
-- Every part of the editor (core UI, treesitter, LSP, plugins, statusline) derives
-- its colours from here, so Neovim stays in step with the Niri desktop theme.
local M = {}

local fallback = {
  dark = {
    surface = "#111820",
    surface_dim = "#0a0f14",
    surface_bright = "#24313b",
    primary = "#62d8e7",
    secondary = "#ff9f8e",
    tertiary = "#f2c66d",
    error = "#ffb4ab",
    on_surface = "#e6f1f4",
    on_surface_var = "#a9bdc4",
    outline = "#78929b",
    shadow = "#05080b",
  },
  light = {
    surface = "#f4f8f9",
    surface_dim = "#dce7e9",
    surface_bright = "#ffffff",
    primary = "#006875",
    secondary = "#9b3f33",
    tertiary = "#765a00",
    error = "#ba1a1a",
    on_surface = "#172023",
    on_surface_var = "#3f4a4d",
    outline = "#6f7d80",
    shadow = "#496067",
  },
}

function M.token_path()
  local home = vim.env.HOME or vim.fn.expand("~")
  return vim.env.NYXNIRI_TOKEN_FILE or (home .. "/.config/niri/nyx-tokens.toml")
end

local function read_tokens()
  local out = {}
  local file = io.open(M.token_path(), "r")
  if not file then
    return out
  end
  local section
  for line in file:lines() do
    local sec = line:match("^%[color%.([%w_]+)%]")
    if sec then
      section = sec
    else
      local key, value = line:match("^([%w_]+)%s*=%s*\"(#%x+)\"")
      if key and section then
        out[section] = out[section] or {}
        out[section][key] = value
      end
    end
  end
  file:close()
  return out
end

local function to_rgb(hex)
  local h = hex:gsub("#", "")
  return tonumber(h:sub(1, 2), 16) or 0, tonumber(h:sub(3, 4), 16) or 0, tonumber(h:sub(5, 6), 16) or 0
end

local function to_hex(r, g, b)
  return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

--- Linear blend: t = 0 returns `a`, t = 1 returns `b`.
---@param a string hex
---@param b string hex
---@param t number
---@return string
function M.mix(a, b, t)
  local ar, ag, ab = to_rgb(a)
  local br, bg, bb = to_rgb(b)
  return to_hex(ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
end

--- Composite `color` at `alpha` over `bg`.
function M.blend(color, bg, alpha)
  return M.mix(bg, color, alpha)
end

function M.mode()
  return vim.o.background == "light" and "light" or "dark"
end

--- Full palette: tokens plus derived shades used across the config.
function M.get()
  local tokens = read_tokens()
  local mode = M.mode()
  local p = vim.tbl_extend("force", fallback[mode], tokens[mode] or {})
  p.mode = mode

  -- Derived tones. Kept as named roles so plugin configs never hardcode hex.
  p.overlay = M.blend(p.on_surface, p.surface, 0.06)
  p.subtle = M.blend(p.on_surface, p.surface, 0.12)
  p.raised = M.blend(p.on_surface, p.surface, 0.04)
  p.border = M.blend(p.outline, p.surface, 0.40)
  p.comment = M.blend(p.on_surface_var, p.surface, 0.30)
  p.selection = M.blend(p.primary, p.surface, 0.22)
  p.search = M.blend(p.tertiary, p.surface, 0.28)
  p.inc = M.blend(p.secondary, p.surface, 0.32)
  p.diff_add = M.blend(p.primary, p.surface, 0.10)
  p.diff_change = M.blend(p.tertiary, p.surface, 0.10)
  p.diff_delete = M.blend(p.secondary, p.surface, 0.12)
  p.shadow = p.shadow or M.blend(p.surface_dim, "#000000", 0.5)
  p.shadow_soft = M.blend(p.shadow, p.surface_dim, 0.45)
  p.cursor = p.primary
  p.muted = M.blend(p.on_surface_var, p.surface, 0.20)
  p.faint = M.blend(p.outline, p.surface, 0.65)
  return p
end

return M
