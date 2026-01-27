{ config, pkgs, ... }:

{
  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Needed for suspend/resume
    powerManagement.finegrained = true; # Turn off GPU when not in use
    open = false; # Use proprietary drivers for better laptop support
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # IDs identified via sysfs
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Optimization: Use NVidia for hardware acceleration in some apps
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Helper script to run apps on Nvidia
  # Usage: nvidia-offload <program>
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];
}
