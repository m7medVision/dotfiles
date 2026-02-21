# NVIDIA Turing architecture (GTX 16 series, RTX 20 series)
{ lib, ... }:

{
  imports = [
    ./default.nix
  ];

  # Turing-specific optimizations can be added here
  # Currently inherits default NVIDIA settings
}
