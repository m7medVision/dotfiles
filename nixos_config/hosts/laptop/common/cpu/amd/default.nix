{ config, lib, ... }:

{
  # Enable AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Load AMD kernel modules
  boot.kernelModules = [ "kvm-amd" ];

  # Enable AMD P-State driver for modern AMD CPUs
  boot.kernelParams = lib.mkDefault [ "amd_pstate=active" ];
}
