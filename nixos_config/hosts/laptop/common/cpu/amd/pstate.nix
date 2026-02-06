{ config, lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # AMD P-State configuration for modern AMD CPUs
  # This module enables the amd-pstate driver for better power management
  boot.kernelParams = [ "amd_pstate=active" ];
}
