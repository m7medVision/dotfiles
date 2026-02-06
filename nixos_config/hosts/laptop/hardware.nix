{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./common/cpu/intel
    ./common/gpu/nvidia/prime.nix
    ./common/pc/laptop
    ./common/pc/ssd
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ]; # Handled by common/cpu/intel
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7560b405-4512-4f19-b9e8-5b6f5d41386c";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/9C16-3839";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/1c6c7b3a-c9b0-4878-92e3-de5316ebd2d4"; }
    ];

  # Machine-specific overrides
  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
