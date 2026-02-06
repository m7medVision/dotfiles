{ lib, ... }:

{
  # Common laptop settings
  services.thermald.enable = lib.mkDefault true;

  # Power profiles daemon is modern standard for laptop power management
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # Logind settings for lid handling
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkDefault "suspend-then-hibernate";
    HandleLidSwitchExternalPower = lib.mkDefault "suspend";
    HandleLidSwitchDocked = lib.mkDefault "ignore";
  };
}
