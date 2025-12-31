{ config, pkgs, ... }:

let
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };

  vscode-settings = {
    # --- Telemetry & Tracking ---
    "telemetry.telemetryLevel" = "off";
    "datatools.enableTelemetry" = false;
    "browser-preview.enableTelemetry" = false;
    "update.mode" = "none";
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "workbench.enableExperiments" = false;

    # --- Sync & Backup Removal ---
    "workbench.settings.enableNaturalLanguageSearch" = false;
    "workbench.accounts.showProfiles" = false;
    "files.hotExit" = "off";
    "workbench.cloudChanges.autoSync" = false;
    "workbench.sync.enable" = false; # Explicitly turn off the sync engine

    # --- UI Minimalism & Menu Cleaning ---
    "search.searchOnType" = false;
    "typescript.surveys.enabled" = false;
    "telemetry.enableCrashReporter" = false;
    "workbench.startupEditor" = "none";
    "workbench.tips.enabled" = false;
    "editor.links" = false;
    "breadcrumbs.enabled" = false;

    # --- AI & IntelliCode ---
    "ai.suggest.enabled" = false;
    "github.copilot.enable" = { "*" = false; };
    "github.copilot.editor.enableAutoCompletions" = false;
    "intellicode.features.python.deepLearning" = "disabled";

    # --- Marketplace & Discovery ---
    "extensions.ignoreRecommendations" = true;
    "workbench.extension.commandDiscovery" = false;
    "extensions.showRecommendationsOnlyOnDemand" = true;
  };

  settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscode-settings);

  blocked-domains = [
    "telemetry.msedge.net"
    "vortex.data.microsoft.com"
    "settings-win.data.microsoft.com"
    "dc.services.visualstudio.com"
    "copilot-proxy.githubusercontent.com"
    "api.githubcopilot.com"
    "default.exp-external-gpts.ext-invoker.intellij.net"
    "vscode-queries.algolia.net"
    "mobile.events.data.microsoft.com"
    "skypegraph.microsoft.com"
    "vscode-sync.trafficmanager.net"
    "vscode-sync.azurewebsites.net"
  ];

in {
  networking.hosts."127.0.0.1" = blocked-domains;

  nixpkgs.config.packageOverrides = pkgs: {
    vscode-private = unstable.vscode.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/code \
          --add-flags "--disable-telemetry" \
          --add-flags "--disable-crash-reporter" \
          --add-flags "--disable-extension-telemetry" \
          --add-flags "--disable-userdata-auth" \
          --add-flags "--disable-features=Sync" \
          --add-flags "--no-proxy-server" \
          --add-flags "--user-data-dir ~/.config/Code-Isolated"
      '';
    });
  };

  environment.systemPackages = [ pkgs.vscode-private ];

  environment.variables = {
    DO_NOT_TRACK = "1";
    ELECTRON_DISABLE_SECURITY_WARNINGS = "true";
  };

  system.activationScripts.vscode-settings = {
    text = ''
      USER_HOME="/home/alice"
      SETTING_DIR="$USER_HOME/.config/Code-Isolated/User"
      mkdir -p "$SETTING_DIR"
      cp -f ${settingsFile} "$SETTING_DIR/settings.json"
      chmod 700 "$USER_HOME/.config/Code-Isolated"
      chown -R alice:users "$USER_HOME/.config/Code-Isolated"
    '';
    deps = [];
  };
}
