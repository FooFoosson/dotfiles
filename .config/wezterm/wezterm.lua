local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

-- Colors ported 1:1 from the GNOME Terminal profile
-- (dconf: /org/gnome/terminal/legacy/profiles:/:<id>) to keep the same look.
config.colors = {
  foreground = '#D3D7CF',
  background = '#2E3436',
  ansi = {
    '#D14306',
    '#DC322F',
    '#859900',
    '#18C462',
    '#17C462',
    '#D33682',
    '#2AA198',
    '#16C462',
  },
  brights = {
    '#002B36',
    '#BD1818',
    '#586E75',
    '#657B83',
    '#839496',
    '#6C71C4',
    '#93A1A1',
    '#FDF6E3',
  },
}

-- gnome: bold-color-same-as-fg=true, bold-is-bright=false
config.bold_brightens_ansi_colors = false

-- gnome: font='Monospace 13' (fc-match Monospace -> DejaVu Sans Mono)
config.font = wezterm.font 'DejaVu Sans Mono'
config.font_size = 13.0

-- gnome: cursor-blink-mode=off
config.default_cursor_style = 'SteadyBlock'

-- gnome: audible-bell=false
config.audible_bell = 'Disabled'
config.window_close_confirmation = 'NeverPrompt'

-- gnome: default-size-columns/rows=100
-- Applies to windows opened later (Ctrl+Shift+T); the startup window is sized
-- by the gui-startup handler below instead.
config.initial_cols = 100
config.initial_rows = 100

-- Put the startup window on the right half of the active screen. wezterm has no
-- declarative option for this, so place the window from the gui-startup event.
--
-- Vertical space the window cannot use, in pixels: the GNOME top bar (32) plus
-- wezterm's title bar (49). Neither mutter nor wezterm reports this, and mutter
-- happily leaves an oversized window hanging off the bottom of the screen, so it
-- has to be subtracted here. Raise it if the window overhangs after a shell theme
-- or panel change.
local DECORATION_HEIGHT = 81

wezterm.on('gui-startup', function(cmd)
  local screen = wezterm.gui.screens().active
  local half = math.floor(screen.width / 2)

  -- Positioning at spawn rather than afterwards: mutter applies its own placement
  -- when it maps the window, and would put it back on the left half.
  local args = cmd or {}
  args.position = {
    x = screen.x + half,
    y = screen.y,
    origin = 'ScreenCoordinateSystem',
  }

  local _, _, window = wezterm.mux.spawn_window(args)
  local gui = window:gui_window()
  gui:set_inner_size(half, screen.height - DECORATION_HEIGHT)
  gui:set_position(screen.x + half, screen.y)
end)

-- Split the focused pane along its longer axis, so repeated splits grow a grid
-- left-to-right, then top-to-bottom. wezterm gives the new pane focus itself.
local function smart_split(window, pane)
  local active
  for _, p in ipairs(window:mux_window():active_tab():panes_with_info()) do
    if p.is_active then
      active = p
      break
    end
  end

  -- Compare pixels, not cells: a cell is roughly twice as tall as it is wide,
  -- so cell counts would call almost every pane "wide".
  local direction = 'Right'
  if active and active.pixel_height > active.pixel_width then
    direction = 'Down'
  end

  window:perform_action(
    act.SplitPane { direction = direction, size = { Percent = 50 } },
    pane
  )
end

config.keys = {
  -- split focused pane, focus follows to the new one: Ctrl+S
  { key = 's', mods = 'CTRL', action = wezterm.action_callback(smart_split) },

  -- close focused pane: Ctrl+W (closing the last pane closes the tab)
  { key = 'w', mods = 'CTRL', action = act.CloseCurrentPane { confirm = false } },

  -- move between panes: Alt+Arrow
  -- wezterm matches either Alt key here: 'LEFT_ALT' parses but never matches a
  -- real key event, since assignment lookup normalizes both Alt keys to ALT.
  -- Right Alt is AltGr on most layouts and reports a different modifier anyway.
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- new-tab: Ctrl+T (matches wezterm's default binding, set explicitly for clarity)
  { key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },

  -- new-window: Ctrl+Shift+T (wezterm defaults this combo to a new tab, override to match gnome)
  { key = 'T', mods = 'CTRL|SHIFT', action = act.SpawnWindow },

  -- close-tab: unbound on Ctrl+W (that closes the focused pane now).
  -- wezterm's default Ctrl+Shift+W still closes the whole tab.

  -- close-window: Ctrl+\
  -- wezterm has no single action for "close whole window", so close every
  -- tab in it, which closes the window once the last tab goes away.
  {
    key = '\\',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local mux_window = window:mux_window()
      while #mux_window:tabs() > 0 do
        window:perform_action(act.CloseCurrentTab { confirm = false }, window:active_pane())
      end
    end),
  },

  -- switch-to-tab-1..5: Ctrl+1..5
  { key = '1', mods = 'CTRL', action = act.ActivateTab(0) },
  { key = '2', mods = 'CTRL', action = act.ActivateTab(1) },
  { key = '3', mods = 'CTRL', action = act.ActivateTab(2) },
  { key = '4', mods = 'CTRL', action = act.ActivateTab(3) },
  { key = '5', mods = 'CTRL', action = act.ActivateTab(4) },
}

return config
