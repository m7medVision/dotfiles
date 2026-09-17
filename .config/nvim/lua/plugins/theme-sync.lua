-- Follows the active hyprshell theme (`theme-set <name>` / `theme-list`) so kitty and
-- Neovim always show the same palette. hyprshell writes each theme's plugin + LazyVim
-- colorscheme choice as a lazy.nvim plugin spec to
-- ~/.local/state/hyprshell/current/theme/neovim.lua; we import that spec directly instead
-- of hand-maintaining a second copy of the theme -> colorscheme mapping.
--
-- Live reload of already-open sessions is handled by aether.nvim's own hotreload watcher
-- (aether.nvim is already the plugin some hyprshell themes render directly), which
-- fs_event-watches ~/.local/state/omarchy/current/theme/neovim.lua for exactly this and
-- asks lazy.nvim to load whichever plugin now owns the named colorscheme. hyprshell has no
-- `omarchy` namespace, so a one-time symlink makes its real state visible at the path
-- aether already watches.
local state_dir = vim.fn.expand '~/.local/state'
local hyprshell_dir = state_dir .. '/hyprshell'
local omarchy_link = state_dir .. '/omarchy'
if vim.fn.isdirectory(hyprshell_dir) == 1 and vim.fn.getftype(omarchy_link) == '' then vim.uv.fs_symlink(hyprshell_dir, omarchy_link) end

local fallback_spec = { { 'ellisonleao/gruvbox.nvim' }, { 'LazyVim/LazyVim', opts = { colorscheme = 'gruvbox' } } }

local function read_spec(file)
  if vim.fn.filereadable(file) ~= 1 then return nil end
  local ok, spec = pcall(dofile, file)
  if not ok or type(spec) ~= 'table' or type(spec[1]) ~= 'table' then return nil end
  return spec
end

local current_spec = read_spec(hyprshell_dir .. '/current/theme/neovim.lua') or fallback_spec
local plugins = { current_spec[1], current_spec[2], { 'bjarneo/aether.nvim', opts = {} } }

-- aether's live reload only asks lazy.nvim to *load* the plugin behind a colorscheme
-- name - it never installs one. So every bundled theme's plugin needs to already be a
-- known (if lazy and uninstalled-until-now) spec, or switching to a theme never opened
-- in this session fails until Neovim restarts. Registering them all here, lazy-loaded,
-- means lazy.nvim installs them once up front and can load any of them on demand.
local seen = { [current_spec[1].src or current_spec[1][1]] = true }
for _, glob in ipairs { '~/.local/share/hyprshell/themes/*/neovim.lua', '~/.config/hyprshell/themes/*/neovim.lua' } do
  for _, file in ipairs(vim.fn.expand(glob, false, true)) do
    local spec = read_spec(file)
    local plugin = spec and spec[1]
    local key = plugin and (plugin.src or plugin[1])
    if plugin and key and not seen[key] then
      seen[key] = true
      plugin.lazy = true
      table.insert(plugins, plugin)
    end
  end
end

return plugins
