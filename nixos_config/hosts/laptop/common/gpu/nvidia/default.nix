{ config, lib, ... }:

{
  imports = [
    ../../../nvidia.nix
  ];

  # Enable NVIDIA drivers
  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for most modern NVIDIA setups
    modesetting.enable = lib.mkDefault true;

    # Enable power management (can help with suspend/resume on laptops)
    powerManagement.enable = lib.mkDefault false;

    # Use proprietary drivers for better laptop support
    open = lib.mkDefault false;

    # Enable nvidia-settings tool
    nvidiaSettings = lib.mkDefault true;

    # Default to stable driver package
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable GPU acceleration
  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };
}
