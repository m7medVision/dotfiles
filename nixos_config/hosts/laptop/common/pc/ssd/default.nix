{ lib, ... }:

{
  # SSD optimizations
  services.fstrim.enable = lib.mkDefault true;
}
