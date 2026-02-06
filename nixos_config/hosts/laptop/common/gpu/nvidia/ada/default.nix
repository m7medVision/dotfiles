# NVIDIA Ada Lovelace architecture (RTX 40 series)
{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Ada-specific optimizations
  # Use the open source kernel module for Ada and newer
  # hardware.nvidia.open = lib.mkDefault true;
}
