{ pkgs, inputs, ... }:
{
  home.packages = [
    # Latest opencode from the dev flake
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
