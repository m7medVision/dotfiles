{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./nvidia.nix
  ];

  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Allow Unfree packages (needed for Nvidia)
  nixpkgs.config.allowUnfree = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking & Locale
  networking.hostName = "laptop";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Muscat"; # Change this to your timezone!

  # Desktop Environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.desktopManager.gnome.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_US.UTF-8";  # Uses 12-hour format
  };
  # User Setup
  users.users.mohammed = {
    isNormalUser = true;
    description = "Mohammed";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # Password can be set via 'passwd mohammed' after install
  };

  # Sound
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Optimization for Laptop
  services.thermald.enable = true;

  # Power Management (GNOME default)
  services.power-profiles-daemon.enable = true;

  # Docker
  virtualisation.docker.enable = true;

  system.stateVersion = "25.11";
}
