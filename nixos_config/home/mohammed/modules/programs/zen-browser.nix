{ pkgs, inputs, lib, ... }: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;
    languagePacks = ["en-US"];

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = lib.mkForce true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      SanitizeOnShutdown = {
        Cache = true;
        Cookies = false;
        Downloads = false;
        FormData = true;
        History = false;
        Sessions = false;
      };

      ExtensionSettings = {
        # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # SponsorBlock
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
        # Wappalyzer
        "wappalyzer@crunchlabz.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
          installation_mode = "force_installed";
        };
      };

      Preferences = let
        mkLocked = value: { Value = value; Status = "locked"; };
      in {
        "gfx.webrender.all" = mkLocked true;
        "network.http.http3.enabled" = mkLocked true;
        "media.ffmpeg.vaapi.enabled" = mkLocked true;
        "privacy.resistFingerprinting" = mkLocked true;
        "privacy.firstparty.isolate" = mkLocked true;
        "privacy.trackingprotection.enabled" = mkLocked true;
        "dom.battery.enabled" = mkLocked false;
        "geo.enabled" = mkLocked false;
        "network.cookie.cookieBehavior" = mkLocked 5;
        "browser.aboutConfig.showWarning" = mkLocked false;
        "browser.tabs.warnOnClose" = mkLocked false;
        "browser.tabs.hoverPreview.enabled" = mkLocked true;
        "browser.download.useDownloadDir" = mkLocked false;
        "browser.newtabpage.activity-stream.feeds.topsites" = mkLocked false;
      };
    };

    profiles.default = rec {
      id = 0;
      isDefault = true;

      settings = {
        "zen.workspaces.continue-where-left-off" = true;
        "zen.workspaces.natural-scroll" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.animate-sidebar" = true;
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "float";
        "zen.tabs.vertical.enabled" = true;
      };

      keyboardShortcutsVersion = 14;
      keyboardShortcuts = [
        {
          id = "zen-compact-mode-toggle";
          key = "c";
          modifiers.control = true;
          modifiers.alt = true;
        }
        {
          id = "zen-toggle-sidebar";
          key = "x";
          modifiers.control = true;
          modifiers.alt = true;
        }
        {
          id = "key_savePage";
          key = "s";
          modifiers.control = true;
        }
        {
          id = "key_quitApplication";
          disabled = true;
        }
      ];

      search = {
        force = true;
        default = "ddg";
        engines = let
          nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        in {
          "ddg" = {
            urls = [{ template = "https://duckduckgo.com"; params = [{ name = "q"; value = "{searchTerms}"; }]; }];
            definedAliases = ["ddg"];
          };
          "google" = {
            urls = [{ template = "https://www.google.com/search"; params = [{ name = "q"; value = "{searchTerms}"; }]; }];
            definedAliases = ["g"];
          };
          "GitHub" = {
            urls = [{ template = "https://github.com/search"; params = [{ name = "q"; value = "{searchTerms}"; }]; }];
            definedAliases = ["gh"];
          };
          "Nix Packages" = {
            urls = [{ template = "https://search.nixos.org/packages"; params = [
              { name = "type"; value = "packages"; }
              { name = "channel"; value = "unstable"; }
              { name = "query"; value = "{searchTerms}"; }
            ]; }];
            icon = nixIcon;
            definedAliases = ["np"];
          };
          "Nix Options" = {
            urls = [{ template = "https://search.nixos.org/options"; params = [
              { name = "channel"; value = "unstable"; }
              { name = "query"; value = "{searchTerms}"; }
            ]; }];
            icon = nixIcon;
            definedAliases = ["no"];
          };
          "Home Manager" = {
            urls = [{ template = "https://home-manager-options.extranix.com/"; params = [
              { name = "query"; value = "{searchTerms}"; }
              { name = "release"; value = "master"; }
            ]; }];
            icon = nixIcon;
            definedAliases = ["hm"];
          };
          "youtube" = {
            urls = [{ template = "https://www.youtube.com/results"; params = [{ name = "search_query"; value = "{searchTerms}"; }]; }];
            definedAliases = ["yt"];
          };
          "bing".metaData.hidden = true;
          "amazondotcom-us".metaData.hidden = true;
        };
      };

      spacesForce = true;
      spaces = {
        "Personal" = {
          id = "c6de089c-410d-4206-961d-ab11f988d40a";
          icon = "🏠";
          position = 1000;
          theme = {
            type = "gradient";
            colors = [{
              algorithm = "floating";
              type = "explicit-lightness";
              red = 124;
              green = 58;
              blue = 58;
              lightness = 45;
              position = { x = 150; y = 150; };
            }];
            opacity = 0.7;
          };
        };
        "Work" = {
          id = "cdd10fab-4fc5-494b-9041-325e5759195b";
          icon = "💼";
          position = 2000;
          theme = {
            type = "gradient";
            colors = [{
              algorithm = "floating";
              type = "explicit-lightness";
              red = 84;
              green = 140;
              blue = 171;
              lightness = 45;
              position = { x = 200; y = 100; };
            }];
            opacity = 0.7;
          };
        };
        "Development" = {
          id = "78aabdad-8aae-4fe0-8ff0-2a0c6c4ccc24";
          icon = "👨‍💻";
          position = 3000;
          theme = {
            type = "gradient";
            colors = [{
              algorithm = "floating";
              type = "explicit-lightness";
              red = 85;
              green = 125;
              blue = 85;
              lightness = 45;
              position = { x = 180; y = 120; };
            }];
            opacity = 0.7;
          };
        };
      };

      pinsForce = true;
      pins = {
        "GitHub" = {
          id = "9d8a8f91-7e29-4688-ae2e-da4e49d4a179";
          workspace = spaces."Development".id;
          url = "https://github.com";
          position = 100;
          isEssential = true;
        };
      };

      containersForce = true;
      containers = {
        "Banking" = { color = "green"; icon = "dollar"; id = 1; };
        "Shopping" = { color = "yellow"; icon = "cart"; id = 2; };
        "Social" = { color = "blue"; icon = "circle"; id = 3; };
      };

      bookmarks = {
        force = true;
        settings = [
          {
            name = "NixOS";
            toolbar = true;
            bookmarks = [
              { name = "Nix Packages"; url = "https://search.nixos.org/packages"; }
              { name = "GitHub"; url = "https://github.com"; }
            ];
          }
        ];
      };

      extraConfig = ''
        user_pref("network.http.max-connections", 1800);
        user_pref("network.dnsCacheExpiration", 3600);
        user_pref("general.smoothScroll", true);
        user_pref("mousewheel.default.delta_multiplier_y", 300);
        user_pref("apz.overscroll.enabled", true);
        user_pref("security.cert_pinning.enforcement_level", 2);
        user_pref("toolkit.telemetry.unified", false);
        user_pref("toolkit.telemetry.enabled", false);
        user_pref("webgl.disabled", false);
        user_pref("gfx.webrender.all", true);
      '';
    };
  };

  xdg.mimeApps = let
    browser = inputs.zen-browser.packages.${pkgs.system}.beta.meta.desktopFileName;
    types = [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ];
  in {
    enable = true;
    associations.added = builtins.listToAttrs (map (t: { name = t; value = browser; }) types);
    defaultApplications = builtins.listToAttrs (map (t: { name = t; value = browser; }) types);
  };
}
