let
  zen-browser = builtins.getFlake "github:0xc000022070/zen-browser-flake";
in
{
  imports = [
    zen-browser.homeModules.beta
    # or zen-browser.homeModules.twilight
    # or zen-browser.homeModules.twilight-official
  ];

  programs.zen-browser.enable = true;
}
