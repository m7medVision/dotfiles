# NVIDIA Ampere architecture (RTX 30 series)
{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Ampere-specific optimizations
  # Use the open source kernel module for Ampere and newer
  # hardware.nvidia.open = lib.mkDefault true;
}
