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
    just
    ripgrep
    fd
    nodejs_22
    fzf
    jq
    ast-grep
    act # github runner
    gitlab-ci-local # gitlab runner
    codex
    typst
    # I will move this later on to other module
    nuclei
    bun

    age
    tree
    uv
    ollama
  ];
  services.ollama.enable = true;
}
