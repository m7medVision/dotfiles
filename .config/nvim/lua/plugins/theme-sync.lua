-- Follows the active hyprshell theme (`theme-set <name>` / `theme-list`) so kitty and
-- Neovim always show the same palette. hyprshell writes each theme's plugin + LazyVim
-- colorscheme choice as a lazy.nvim plugin spec to
-- ~/.local/state/hyprshell/current/theme/neovim.lua; we import that spec directly instead
-- of hand-maintaining a second copy of the theme -> colorscheme mapping.
--
-- Live reload of already-open sessions is handled at the bottom of this file: a
-- libuv fs_event watcher on the theme directory re-applies the colorscheme
-- shortly after `theme-set` rewrites the spec, so no restart is needed.
local state_dir = vim.fn.expand '~/.local/state'
local hyprshell_dir = state_dir .. '/hyprshell'
local theme_dir = hyprshell_dir .. '/current/theme'
local theme_file = theme_dir .. '/neovim.lua'

local fallback_spec = { { 'ellisonleao/gruvbox.nvim' }, { 'LazyVim/LazyVim', opts = { colorscheme = 'gruvbox' } } }

local function read_spec(file)
  if vim.fn.filereadable(file) ~= 1 then return nil end
  local ok, spec = pcall(dofile, file)
  if not ok or type(spec) ~= 'table' or type(spec[1]) ~= 'table' then return nil end
  return spec
end

local current_spec = read_spec(theme_file) or fallback_spec
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

-- ── Live reload: watch the real spec, re-apply colorscheme on change ──
-- First entry carrying `opts.colorscheme` wins (matches every bundled theme:
-- a colorscheme plugin plus the LazyVim entry naming it).
local function spec_colorscheme(spec)
  if type(spec) ~= 'table' then return nil end
  for _, entry in ipairs(spec) do
    if type(entry) == 'table' and type(entry.opts) == 'table' then
      local name = entry.opts.colorscheme
      if type(name) == 'string' and name ~= '' then return name, entry.opts.background end
    end
  end
  return nil
end

local last_applied = spec_colorscheme(current_spec)

local reload_timer = nil
local function schedule_reload()
  if reload_timer then
    pcall(function()
      reload_timer:stop()
      reload_timer:close()
    end)
    reload_timer = nil
  end
  reload_timer = vim.defer_fn(function()
    reload_timer = nil
    local name, background = spec_colorscheme(read_spec(theme_file))
    if not name or name == last_applied then return end
    last_applied = name
    if background then vim.o.background = background end
    vim.schedule(function()
      local ok, err = pcall(vim.cmd, 'colorscheme ' .. name)
      if not ok then vim.notify('theme-sync: cannot apply ' .. name .. ': ' .. tostring(err), vim.log.levels.WARN) end
    end)
  end, 1500)
end

local function start_watcher()
  local uv = vim.uv or vim.loop
  if not (uv and uv.new_fs_event) then return end
  if vim.fn.isdirectory(theme_dir) ~= 1 then return end
  local handle = uv.new_fs_event()
  if not handle then return end
  -- Pinned on _G: an unreferenced uv handle is garbage-collected and the
  -- watch dies with it.
  _G._hyprshell_theme_watch = handle
  local ok = pcall(handle.start, handle, theme_dir, {}, vim.schedule_wrap(function(err, fname)
    if err then return end
    if fname == nil or fname == 'neovim.lua' then schedule_reload() end
  end))
  if not ok then
    pcall(function()
      handle:stop()
      handle:close()
    end)
    _G._hyprshell_theme_watch = nil
  end
end

pcall(start_watcher)

return plugins
