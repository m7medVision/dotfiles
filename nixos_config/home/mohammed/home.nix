{
  imports = [
    ./modules/core.nix
    ./modules/packages/apps.nix
    ./modules/packages/dev-tools.nix
    ./modules/packages/utils.nix
    ./modules/symlinks.nix
    ./modules/programs/git.nix
    ./modules/programs/gh.nix
    ./modules/programs/zen-browser.nix
  ];

  programs.home-manager.enable = true;
}
