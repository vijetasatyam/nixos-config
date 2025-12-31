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

    # --- Search Privacy (NEW) ---
    "workbench.settings.enableNaturalLanguageSearch" = false; # Stop sending settings searches to MS
    "search.searchOnType" = false; # Reduces constant pings during global searches
    "typescript.surveys.enabled" = false; # No JS/TS feedback popups
    "telemetry.enableCrashReporter" = false;

    # --- AI & IntelliCode ---
    "ai.suggest.enabled" = false;
    "github.copilot.enable" = { "*" = false; };
    "github.copilot.editor.enableAutoCompletions" = false;
    "intellicode.features.python.deepLearning" = "disabled";

    # --- Marketplace & Discovery (NEW) ---
    "extensions.ignoreRecommendations" = true; # Stop scanning local files for suggestions
    "workbench.extension.commandDiscovery" = false; # Stop "finding commands in marketplace"
    "extensions.showRecommendationsOnlyOnDemand" = true;

    # --- UI Minimalism ---
    "workbench.startupEditor" = "none";
    "workbench.tips.enabled" = false;
    "editor.links" = false;
    "breadcrumbs.enabled" = false;
  };

  settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscode-settings);

  # Expanded blocklist for Experiments and Diagnostic endpoints
  blocked-domains = [
    "telemetry.msedge.net"
    "vortex.data.microsoft.com"
    "settings-win.data.microsoft.com"
    "dc.services.visualstudio.com"
    "copilot-proxy.githubusercontent.com"
    "api.githubcopilot.com"
    "default.exp-external-gpts.ext-invoker.intellij.net"
    "vscode-queries.algolia.net" # Blocks online search pings
    "mobile.events.data.microsoft.com"
    "skypegraph.microsoft.com"
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
          --add-flags "--no-proxy-server" \
          --add-flags "--disable-unvetted-extra-digital-signatures" \
          --add-flags "--user-data-dir ~/.config/Code-Isolated"
      '';
    });
  };

  environment.systemPackages = [ pkgs.vscode-private ];

  environment.variables = {
    DO_NOT_TRACK = "1";
    # Prevent Electron from trying to reach out for certificate CRL checks
    # and other automated metadata updates
    ELECTRON_DISABLE_SECURITY_WARNINGS = "true";
  };

  system.activationScripts.vscode-settings = {
    text = ''
      USER_HOME="/home/alice"
      SETTING_DIR="$USER_HOME/.config/Code-Isolated/User"
      mkdir -p "$SETTING_DIR"
      cp -f ${settingsFile} "$SETTING_DIR/settings.json"
      # Secure the isolated directory permissions
      chmod 700 "$USER_HOME/.config/Code-Isolated"
      chown -R alice:users "$USER_HOME/.config/Code-Isolated"
    '';
    deps = [];
  };
}

# {
#   config,
#   pkgs,
#   ...
# }:

# let
#   # 1. Define unstable overlay
#   unstable = import <unstable> {
#     config = config.nixpkgs.config;
#   };

#   # 2. Privacy, AI-blocking, and UI Minimalism Settings
#   vscode-settings = {
#     # Telemetry & Tracking
#     "telemetry.telemetryLevel" = "off";
#     "datatools.enableTelemetry" = false;
#     "browser-preview.enableTelemetry" = false;
#     "update.mode" = "none";
#     "extensions.autoCheckUpdates" = false;
#     "extensions.autoUpdate" = false;

#     # AI & IntelliCode Features
#     "ai.suggest.enabled" = false;
#     "github.copilot.enable" = { "*" = false; };
#     "github.copilot.editor.enableAutoCompletions" = false;
#     "intellicode.features.python.deepLearning" = "disabled";

#     # UI Minimalism
#     "workbench.startupEditor" = "none";
#     "workbench.tips.enabled" = false;
#     "editor.links" = false;
#     "workbench.enableExperiments" = false;
#     "workbench.settings.enableNaturalLanguageSearch" = false;
#     "breadcrumbs.enabled" = false;
#   };

#   settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscode-settings);

#   # 3. List of Microsoft Telemetry and AI domains to block at DNS level
#   blocked-domains = [
#     "telemetry.msedge.net"
#     "vortex.data.microsoft.com"
#     "settings-win.data.microsoft.com"
#     "dc.services.visualstudio.com"
#     "copilot-proxy.githubusercontent.com"
#     "api.githubcopilot.com"
#     "default.exp-external-gpts.ext-invoker.intellij.net"
#   ];

# in {
#   # 4. OS-level blocking via /etc/hosts
#   networking.hosts."127.0.0.1" = blocked-domains;

#   nixpkgs.config.packageOverrides = pkgs: {
#     # 5. Build VSCode from Unstable with Privacy Wrappers
#     vscode-private = unstable.vscode.overrideAttrs (oldAttrs: {
#       nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

#       postFixup = (oldAttrs.postFixup or "") + ''
#         wrapProgram $out/bin/code \
#           --add-flags "--disable-telemetry" \
#           --add-flags "--disable-crash-reporter" \
#           --add-flags "--disable-extension-telemetry" \
#           --add-flags "--user-data-dir ~/.config/Code-Isolated"
#       '';
#     });
#   };

#   environment.systemPackages = [
#     pkgs.vscode-private
#   ];

#   # 6. Global Privacy Signal
#   environment.variables = {
#     DO_NOT_TRACK = "1";
#   };

#   # 7. Activation Script to force the settings into the isolated directory
#   system.activationScripts.vscode-settings = {
#     text = ''
#       USER_HOME="/home/alice"
#       SETTING_DIR="$USER_HOME/.config/Code-Isolated/User"

#       mkdir -p "$SETTING_DIR"
#       cp -f ${settingsFile} "$SETTING_DIR/settings.json"
#       chown -R alice:users "$USER_HOME/.config/Code-Isolated"
#     '';
#     deps = [];
#   };
# }


# {
#   config,
#   pkgs,
#   ...
# }:

# let
#   # 1. Define unstable overlay
#   # This assumes you have 'nixos-unstable' in your nix-channels or flakes
#   unstable = import <unstable> {
#     config = config.nixpkgs.config;
#   };

#   # 2. Privacy & UI Settings
#   vscode-settings = {
#     "telemetry.telemetryLevel" = "off";
#     "datatools.enableTelemetry" = false;
#     "browser-preview.enableTelemetry" = false;
#     "extensions.autoCheckUpdates" = false;
#     "extensions.autoUpdate" = false;
#     "update.mode" = "none";
#     "ai.suggest.enabled" = false;
#     "github.copilot.enable" = { "*" = false; };
#     "github.copilot.editor.enableAutoCompletions" = false;
#     "intellicode.features.python.deepLearning" = "disabled";
#     "workbench.startupEditor" = "none";
#     "workbench.tips.enabled" = false;
#     "editor.links" = false;
#     "workbench.enableExperiments" = false;
#     "workbench.settings.enableNaturalLanguageSearch" = false;
#     "breadcrumbs.enabled" = false;
#   };

#   settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscode-settings);

# in {
#   nixpkgs.config.packageOverrides = pkgs: {
#     # 3. Use unstable.vscode here instead of pkgs.vscode
#     vscode-private = unstable.vscode.overrideAttrs (oldAttrs: {
#       nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

#       postFixup = (oldAttrs.postFixup or "") + ''
#         wrapProgram $out/bin/code \
#           --add-flags "--disable-telemetry" \
#           --add-flags "--disable-crash-reporter" \
#           --add-flags "--disable-extension-telemetry" \
#           --add-flags "--user-data-dir ~/.config/Code-Isolated"
#       '';
#     });
#   };

#   environment.systemPackages = [
#     pkgs.vscode-private
#   ];

#   environment.variables = {
#     DO_NOT_TRACK = "1";
#   };

#   system.activationScripts.vscode-settings = {
#     text = ''
#       USER_HOME="/home/alice"
#       SETTING_DIR="$USER_HOME/.config/Code-Isolated/User"

#       mkdir -p "$SETTING_DIR"
#       cp -f ${settingsFile} "$SETTING_DIR/settings.json"
#       chown -R alice:users "$USER_HOME/.config/Code-Isolated"
#     '';
#     deps = [];
#   };
# }


# { pkgs, ... }:

# let
#   # 1. Combined Privacy and Minimalist Settings
#   vscode-settings = {
#     # Telemetry & Tracking
#     "telemetry.telemetryLevel" = "off";
#     "datatools.enableTelemetry" = false;
#     "browser-preview.enableTelemetry" = false;
#     "extensions.autoCheckUpdates" = false;
#     "extensions.autoUpdate" = false;
#     "update.mode" = "none";

#     # AI & IntelliCode Features
#     "ai.suggest.enabled" = false;
#     "github.copilot.enable" = { "*" = false; };
#     "github.copilot.editor.enableAutoCompletions" = false;
#     "intellicode.features.python.deepLearning" = "disabled";

#     # UI Minimalism (No Distractions)
#     "workbench.startupEditor" = "none";             # No Welcome Page
#     "workbench.tips.enabled" = false;               # No "did you know" tips
#     "editor.links" = false;                         # Don't track link clicks
#     "workbench.enableExperiments" = false;          # No A/B testing
#     "workbench.settings.enableNaturalLanguageSearch" = false;
#     "breadcrumbs.enabled" = false;                  # Cleaner UI
#   };

#   # Convert the nix set to a JSON file
#   settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscode-settings);

# in {
#   nixpkgs.config.packageOverrides = pkgs: {
#     # 2. Binary Wrapper to kill Telemetry at the source
#     vscode-private = pkgs.vscode.overrideAttrs (oldAttrs: {
#       nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

#       postFixup = (oldAttrs.postFixup or "") + ''
#         wrapProgram $out/bin/code \
#           --add-flags "--disable-telemetry" \
#           --add-flags "--disable-crash-reporter" \
#           --add-flags "--disable-extension-telemetry" \
#           --add-flags "--user-data-dir ~/.config/Code-Isolated"
#       '';
#     });
#   };

#   environment.systemPackages = [
#     pkgs.vscode-private
#   ];

#   # 3. System-level privacy signals
#   environment.variables = {
#     DO_NOT_TRACK = "1";
#   };

#   # 4. Activation Script to force the settings into place
#   # This ensures your home folder is configured without Home Manager
#   system.activationScripts.vscode-settings = {
#     text = ''
#       USER_HOME="/home/alice"
#       SETTING_DIR="$USER_HOME/.config/Code-Isolated/User"

#       mkdir -p "$SETTING_DIR"
#       cp -f ${settingsFile} "$SETTING_DIR/settings.json"
#       chown -R alice:users "$USER_HOME/.config/Code-Isolated"
#     '';
#     deps = [];
#   };
# }
