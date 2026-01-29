{ config, pkgs, ... }:

{
  home.username = "mohammed";
  home.homeDirectory = "/home/mohammed";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    google-chrome
    lazydocker
    lazygit
    neovim-unwrapped
    bitwarden-desktop
    opencode

    # Utilities
    wl-clipboard
    nvtopPackages.full # GPU monitoring
    htop
    git
    curl
    wget
    unzip
    zsh
    tmux

    gcc # Required for nvim-treesitter to compile parsers
    gnumake # Often required for building plugins
    ripgrep # Required for Telescope/grep searches
    fd # Required for fast file finding
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
  home.file.".tmux.conf".source = ../../../.tmux.conf;
  home.file.".zshrc".source = ../../../.zshrc;

  # Basic Git Config
  programs.git = {
    enable = true;
    settings.user.name = "Mohammed";
    settings.user.email = "88824957+m7medVision@users.noreply.github.com";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
