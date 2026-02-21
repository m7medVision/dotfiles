{ lib, ... }:

{
  # Intel-specific GPU support
  boot.initrd.kernelModules = [ "i915" ];

  # Video drivers
  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

  # Hardware acceleration
  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };
}
