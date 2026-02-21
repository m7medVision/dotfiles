{ config, lib, ... }:

{
  # Enable Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Load Intel kernel modules
  boot.kernelModules = [ "kvm-intel" ];

  # Enable Intel P-State driver for power management
  boot.kernelParams = lib.mkDefault [ "intel_pstate=active" ];
}
