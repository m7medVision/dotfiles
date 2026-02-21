{ config, ... }:
{
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/nvim";
  home.file.".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/kitty";
  home.file.".config/opencode".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/opencode/";
  home.file.".config/lazygit".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/lazygit";
  home.file.".config/niri".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/niri";
  home.file.".themes/DankMaterialShell".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/DankMaterialShell";
  home.file.".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.tmux.conf";
  home.file.".zshrc".source = config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.zshrc";
}
