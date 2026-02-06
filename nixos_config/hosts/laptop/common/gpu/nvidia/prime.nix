# NVIDIA PRIME Offload configuration for hybrid Intel+NVIDIA laptops
# Usage: Import this module when you have both Intel iGPU and NVIDIA dGPU

{ config, lib, pkgs, ... }:

{
  imports = [
    ./default.nix
  ];

  # Enable NVIDIA drivers (overrides modesetting from Intel)
  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    powerManagement.enable = lib.mkDefault false;
    open = lib.mkDefault false;
    nvidiaSettings = lib.mkDefault true;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = lib.mkDefault true;
        enableOffloadCmd = lib.mkDefault true;
      };
      # Bus IDs must be configured per-machine
      # Use `lspci | grep -i vga` to find these values
      # intelBusId = lib.mkDefault "PCI:0:2:0";
      # nvidiaBusId = lib.mkDefault "PCI:1:0:0";
    };
  };

  # Enable GPU acceleration with 32-bit support
  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };

  # Kernel parameters for better NVIDIA stability
  boot.kernelParams = [
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # Helper script to run apps on NVIDIA GPU
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
