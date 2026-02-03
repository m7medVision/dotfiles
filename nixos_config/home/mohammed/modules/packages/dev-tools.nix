{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Development Tools
    neovim-unwrapped
    lazydocker
    lazygit
    git
    cargo
    gcc
    gnumake
    ripgrep
    fd
    nodejs_22
    fzf
    jq


    # I will move this later on to other module
    nuclei
  ];
}
