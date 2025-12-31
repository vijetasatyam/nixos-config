{
  config,
  pkgs,
  ...
}:

let
  # 1. Define unstable overlay
  # This assumes you have 'nixos-unstable' in your nix-channels or flakes
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };

  # 2. Privacy & UI Settings
  vscode-settings = {
    "telemetry.telemetryLevel" = "off";
    "datatools.enableTelemetry" = false;
    "browser-preview.enableTelemetry" = false;
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "update.mode" = "none";
    "ai.suggest.enabled" = false;
    "github.copilot.enable" = { "*" = false; };
    "github.copilot.editor.enableAutoCompletions" = false;
    "intellicode.features.python.deepLearning" = "disabled";
    "workbench.startupEditor" = "none";
    "workbench.tips.enabled" = false;
    "editor.links" = false;
    "workbench.enableExperiments" = false;
    "workbench.settings.enableNaturalLanguageSearch" = false;
    "breadcrumbs.enabled" = false;
  };

  settingsFile = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscode-settings);

in {
  nixpkgs.config.packageOverrides = pkgs: {
    # 3. Use unstable.vscode here instead of pkgs.vscode
    vscode-private = unstable.vscode.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/code \
          --add-flags "--disable-telemetry" \
          --add-flags "--disable-crash-reporter" \
          --add-flags "--disable-extension-telemetry" \
          --add-flags "--user-data-dir ~/.config/Code-Isolated"
      '';
    });
  };

  environment.systemPackages = [
    pkgs.vscode-private
  ];

  environment.variables = {
    DO_NOT_TRACK = "1";
  };

  system.activationScripts.vscode-settings = {
    text = ''
      USER_HOME="/home/alice"
      SETTING_DIR="$USER_HOME/.config/Code-Isolated/User"

      mkdir -p "$SETTING_DIR"
      cp -f ${settingsFile} "$SETTING_DIR/settings.json"
      chown -R alice:users "$USER_HOME/.config/Code-Isolated"
    '';
    deps = [];
  };
}


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
