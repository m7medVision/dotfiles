{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Applications
    google-chrome
    bitwarden-desktop
    opencode
  ];
}
