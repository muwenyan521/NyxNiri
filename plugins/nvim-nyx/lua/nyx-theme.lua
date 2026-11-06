-- Stable entry point for the Nyx colourscheme.
-- The repo contract and init.lua both reference this file, so keep the name.
-- Palette reading: lua/nyx/palette.lua. Highlight groups: lua/nyx/highlights.lua.
local highlights = require("nyx.highlights")

return {
  apply = highlights.apply,
  refresh = highlights.refresh,
  paint = highlights.paint,
  palette = highlights.palette,
}
