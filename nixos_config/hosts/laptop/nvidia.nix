{ config, pkgs, ... }:

{
  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # More stable for hybrid/suspend
    # powerManagement.finegrained = false; # Keep off for max suspend stability (uncomment only if truly needed)
    open = false; # Use proprietary drivers for better laptop support
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable; # Most compatible/stable package choice

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

   boot.kernelParams = [
     "nvidia.NVreg_TemporaryFilePath=/var/tmp"
     "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
   ];
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
