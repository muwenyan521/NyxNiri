# NyxNiri design system

## 0. Research log

- Existing project audit: extracted the current Material You, Noctalia palette, Cairo layer-shell and Niri geometry patterns from `configs/niri/`, `configs/noctalia/` and `nyxniri/`
- Local reference audit: compared token/template patterns in Omarchy, LanRhyme-dotfiles, yuzujr-dotfiles, Shorin-ArchLinux-Guide, hyprvibe, glassmorphism themes and Soltros-OS-Reborn
- Direction: keep NyxNiri's quiet celestial identity, but replace scattered purple fallbacks with an ink, cyan, coral and amber ramp that still accepts Noctalia wallpaper colors at runtime

## 1. Visual direction

NyxNiri is a desktop control surface, not a marketing page. Its material is a dark, translucent mineral surface: deep ink backgrounds, a thin cool outline, small cyan focus light, coral error warmth and amber utility accents. Panels should feel calm when idle and tactile when focused.

The memorable gesture is the Orbit ring: one compact radial gesture should reveal the same palette, spacing and motion language as the Wallpaper Picker and terminal theme.

## 2. Tokens

The source of truth is `design/tokens.toml`. The shared token loader feeds layout, motion and typography defaults; runtime palette loading may override color tokens from Noctalia's generated Starship palette, but the semantic names and fallback values remain stable.

- Color roles: `surface`, `surface_dim`, `surface_bright`, `primary`, `secondary`, `tertiary`, `error`, `on_surface`, `on_surface_var`, `outline`
- Shape roles: `corner_sm`, `corner_md`, `corner_lg`, `dialog_radius`
- Spacing roles: `space_1` through `space_6`, `panel_padding`, `grid_gap`
- Motion roles: `spring_omega`, `spring_damping`, `reduced_motion`
- Typography roles: `ui_family`, `mono_family`, `title_size`, `body_size`, `caption_size`

## 3. Typography

- UI: `Noto Sans CJK SC, Inter, sans-serif`
- Mono: `JetBrains Mono, Noto Sans Mono, monospace`
- Titles are medium weight and sentence case; captions are muted rather than tiny or all-caps
- Long names must be ellipsized or wrapped inside a stable card box

## 4. Layout

- Base unit: 4px
- Panel padding and gaps use the token scale, not one-off values
- Wallpaper Picker uses a minimum card width of 248px, a maximum of 360px and 2-4 columns based on available width
- Orbit keeps its radial geometry but scales radius and capsule size with the available layer-shell area
- Dialogs keep a stable minimum size and clamp to the available monitor area

## 5. Primitives and states

- `Surface`: idle, hover, pressed, disabled
- `FocusRing`: keyboard focus, current item, urgent/error
- `SearchField`: empty, active, populated, invalid/no results
- `MediaCard`: loading, ready, current, hovered, keyboard-selected, unavailable
- `CategoryChip`: idle, hover, active, disabled
- `OrbitCapsule`: idle, focused, folder, action, unavailable
- `StatusMessage`: info, success, warning, error

Every interactive state must remain visible without color alone: use outline, position, opacity or text as a second signal.

## 6. Motion and accessibility

- Default motion uses the existing spring language with tokenized omega and damping
- `NYXNIRI_REDUCED_MOTION=1` must settle immediately
- Animated properties are opacity, transform and Cairo alpha/scale; no geometry jumps during hover
- Keyboard focus is always drawn; Escape closes or clears; Enter activates the selected item
- High contrast uses stronger outline and text tokens without removing content

## 7. Surface recipe

Panels use a translucent surface fill, a 1px outline, one soft tinted shadow and a restrained scrim. Blur is optional and must never be required for legibility. Eye Care removes blur and raises surface opacity.

## 8. Accepted debt

- Niri and Kitty are declarative formats with no shared import mechanism; generated/static files are kept synchronized by the token generator and tests
- Cairo remains the renderer for the two panels; a full widget toolkit migration would add weight without improving the core interaction
- Real layer-shell screenshot QA depends on the host's GTK and Wayland runtime and is recorded separately from headless/static checks
