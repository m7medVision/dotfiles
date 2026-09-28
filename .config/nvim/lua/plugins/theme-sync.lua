-- Follows GNOME's light/dark preference (org.gnome.desktop.interface color-scheme) so
-- kitty and Neovim always show the same palette: Catppuccin Mocha when dark, Latte
-- otherwise. catppuccin's `auto` flavour picks from 'background', so we only set that.
--
-- Live reload: `gsettings monitor` prints a line on every change; we flip 'background'
-- in already-open sessions and re-apply the colorscheme, so no restart is needed.
local schema, key = 'org.gnome.desktop.interface', 'color-scheme'

local function background_for(scheme) return scheme:find 'dark' and 'dark' or 'light' end

local function apply(scheme)
  local background = background_for(scheme)
  if vim.o.background == background then return end
  vim.o.background = background
  if vim.g.colors_name and vim.g.colors_name:find '^catppuccin' then pcall(vim.cmd.colorscheme, 'catppuccin') end
end

if vim.fn.executable 'gsettings' == 1 then
  local scheme = vim.fn.system { 'gsettings', 'get', schema, key }
  if vim.v.shell_error == 0 then vim.o.background = background_for(scheme) end

  vim.fn.jobstart({ 'gsettings', 'monitor', schema, key }, {
    on_stdout = vim.schedule_wrap(function(_, lines)
      for _, line in ipairs(lines) do
        if line ~= '' then apply(line) end
      end
    end),
  })
end

return {
  { 'catppuccin/nvim', name = 'catppuccin', opts = { flavour = 'auto', background = { dark = 'mocha', light = 'latte' } } },
  { 'LazyVim/LazyVim', opts = { colorscheme = 'catppuccin' } },
}
