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
  ];

  # Basic Git Config
  programs.git = {
    enable = true;
    userName = "Mohammed";
    userEmail = ""; # Update this
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
