{ pkgs, inputs, lib, config, ... }: {
  imports = [
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  programs.openclaw = {
    documents = ./openclaw-documents;
    
    config = {
      gateway = {
        mode = "local";
        auth = {
          # Use OPENCLAW_GATEWAY_TOKEN env via a service script, or hardcode it
          token = "8688894604:AAFoA6twq-g2qfHVr3mkTD-chQXJzs5P_mw";
        };
      };

      channels.telegram = {
        tokenFile = "/home/mohammed/.secrets/telegram_token";
        allowFrom = [ 2067183279 ];
        groups = {
          "*" = {
            requireMention = true;
          };
        };
      };
    };

    bundledPlugins = {
      summarize.enable = true;
    };

    instances.default = {
      enable = true;
      plugins = [];
    };
  };

  # Load the ZAI environment variables into the openclaw-gateway systemd user service
  systemd.user.services.openclaw-gateway.Service.EnvironmentFile = [
    "/home/mohammed/.secrets/openclaw.env"
  ];
}
