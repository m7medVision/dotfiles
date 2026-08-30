-- Follows the active hyprshell theme (`theme-set <name>` / `theme-list`) so kitty and
-- Neovim always show the same palette. hyprshell writes each theme's Neovim plugin +
-- colorscheme as a LazyVim spec at this path; we read that spec directly (via vim.pack)
-- instead of hand-maintaining a second copy of the theme -> colorscheme mapping.
local spec_file = vim.fn.expand '~/.local/state/hyprshell/current/theme/neovim.lua'

local fallback_plugin = { 'ellisonleao/gruvbox.nvim' }
local fallback_colorscheme = 'gruvbox'

local function read_spec()
  if vim.fn.filereadable(spec_file) == 0 then return nil end
  local ok, spec = pcall(dofile, spec_file)
  if not ok or type(spec) ~= 'table' or type(spec[1]) ~= 'table' then return nil end
  return spec
end

local spec = read_spec()
local plugin = spec and spec[1] or fallback_plugin
local colorscheme = spec and spec[2] and spec[2].opts and spec[2].opts.colorscheme or fallback_colorscheme

local src = plugin.src or plugin[1]
if not src:match '^https?://' then src = 'https://github.com/' .. src end

local install = { { src = src, name = plugin.name } }
for _, dep in ipairs(plugin.dependencies or {}) do
  local dep_src = dep.src or dep[1] or dep
  if not dep_src:match '^https?://' then dep_src = 'https://github.com/' .. dep_src end
  table.insert(install, { src = dep_src, name = dep.name })
end
vim.pack.add(install)

if plugin.opts then
  local mod_name = (plugin.name or src:match '([^/]+)$' or ''):gsub('%.nvim$', ''):gsub('%-nvim$', '')
  local ok_mod, mod = pcall(require, mod_name)
  if ok_mod and mod.setup then mod.setup(plugin.opts) end
end

-- hyprshell's shipped colorscheme name is occasionally stale (e.g. catppuccin's is
-- "catppuccin-nvim", not the plugin's real "catppuccin"), so try a couple of fallbacks
-- before giving up on the theme entirely.
local candidates = {
  colorscheme,
  colorscheme and (colorscheme:gsub('%-nvim$', '')),
  plugin.name,
  fallback_colorscheme,
}

for _, name in ipairs(candidates) do
  if name and pcall(vim.cmd.colorscheme, name) then return end
end
