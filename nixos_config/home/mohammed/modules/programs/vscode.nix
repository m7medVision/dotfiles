{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  # Force Wayland for VS Code desktop entry
  xdg.desktopEntries.code = {
    name = "Visual Studio Code";
    genericName = "Text Editor";
    exec = "code --enable-features=UseOzonePlatform --ozone-platform=wayland %F";
    icon = "vscode";
    terminal = false;
    categories = [ "Utility" "TextEditor" "Development" "IDE" ];
    mimeType = [ "text/plain" "inode/directory" ];
  };
}
