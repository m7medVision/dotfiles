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
    description = "Mohammed Al Jahwari";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Sound
  services.pulseaudio.enable = false;
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
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Docker
  virtualisation.docker.enable = true;

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

   # Fix for GNOME/NVIDIA suspend freezing:
   systemd.services.systemd-suspend.environment = {
     SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
   };

   # GNOME suspend/resume hooks (optional, uncomment if you see gnome-shell issues)
   /*
   systemd.services.gnome-suspend = {
     description = "Suspend gnome shell before sleep";
     before = [
       "systemd-suspend.service"
       "systemd-hibernate.service"
       "nvidia-suspend.service"
       "nvidia-hibernate.service"
     ];
     wantedBy = [
       "systemd-suspend.service"
       "systemd-hibernate.service"
     ];
     serviceConfig = {
       Type = "oneshot";
       ExecStart = "${pkgs.procps}/bin/pkill -f -STOP gnome-shell";
     };
   };

   systemd.services.gnome-resume = {
     description = "Resume gnome shell after sleep";
     after = [
       "systemd-suspend.service"
       "systemd-hibernate.service"
       "nvidia-resume.service"
     ];
     wantedBy = [
       "systemd-suspend.service"
       "systemd-hibernate.service"
     ];
     serviceConfig = {
       Type = "oneshot";
       ExecStart = "${pkgs.procps}/bin/pkill -f -CONT gnome-shell";
     };
   };
   */

   system.stateVersion = "25.11";
}
