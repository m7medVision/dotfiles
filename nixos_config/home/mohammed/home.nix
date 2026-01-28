{ config, pkgs, ... }:

{
  home.username = "mohammed";
  home.homeDirectory = "/home/mohammed";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    google-chrome
    lazydocker
    lazygit
    neovim     # Basic install for your Lua config
    bitwarden-desktop
    opencode

    # Utilities
    nvtopPackages.full # GPU monitoring
    htop
    git
    curl
    wget
    unzip
    zsh
    tmux
    tree-sitter
    # Dependencies for scripts and tools
    kitty
    fontconfig
    gnome-calculator
    pavucontrol
    networkmanagerapplet
    brightnessctl
    pamixer
    playerctl
    nodejs_22
    # Theme management
    glib # for gsettings
  ];

  home.file.".config/nvim" = {
    source = ../../../.config/nvim;
    recursive = true;  # Copies instead of symlinks, but keeps your config intact
  };
  home.file.".config/lazygit".source = ../../../.config/lazygit;
  home.file.".config/opencode".source = ../../../.config/opencode;
  home.file.".tmux.conf".source = ../../../.tmux.conf;
  home.file.".zshrc".source = ../../../.zshrc;

  # Basic Git Config
  programs.git = {
    enable = true;
    userName = "Mohammed";
    userEmail = "88824957+m7medVision@users.noreply.github.com";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
