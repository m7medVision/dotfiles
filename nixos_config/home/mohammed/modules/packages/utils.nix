{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Utilities
    wl-clipboard
    nvtopPackages.full
    htop
    curl
    wget
    unzip
    tmux
    zoxide
    lsof
    kitty
    fontconfig
    gnome-calculator
    pavucontrol
    networkmanagerapplet
    brightnessctl
    pamixer
    playerctl
    glib
  ];
}
