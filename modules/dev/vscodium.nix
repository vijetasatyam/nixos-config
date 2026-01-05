{ config, pkgs, ... }:

let
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };

  # Settings tailored for VSCodium
  vscode-settings = {
    "telemetry.telemetryLevel" = "off";
    "update.mode" = "none";
    "workbench.accounts.showProfiles" = false;
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "workbench.startupEditor" = "none";
    "ai.suggest.enabled" = false;
    "github.copilot.enable" = { "*" = false; };
  };

  settingsFile = pkgs.writeText "vscodium-settings.json" (builtins.toJSON vscode-settings);

in {
  nixpkgs.config.packageOverrides = pkgs: {
    # Override VSCodium to use the MS Marketplace and strip unwanted features
    vscode-private = (unstable.vscodium.override {
      useOfficialExtensions = true;
    }).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

      # Physically remove the authentication and account sync extensions
      postInstall = (oldAttrs.postInstall or "") + ''
        find $out -name "microsoft-authentication" -type d -exec rm -rf {} +
        find $out -name "github-authentication" -type d -exec rm -rf {} +
        find $out -name "microsoft-account" -type d -exec rm -rf {} +
      '';

      # Wrap the binary with privacy flags and isolated data directory
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/codium \
          --add-flags "--disable-telemetry" \
          --add-flags "--disable-crash-reporter" \
          --add-flags "--disable-userdata-auth" \
          --add-flags "--user-data-dir ~/.config/VSCodium-Isolated"
      '';
    });
  };

  environment.systemPackages = [
    pkgs.vscode-private
    # Alias 'code' to 'codium' so your terminal habits don't have to change
    (pkgs.writeShellScriptBin "code" "exec codium \"$@\"")
  ];

  system.activationScripts.vscode-settings = {
    text = ''
      USER_HOME="/home/alice"
      SETTING_DIR="$USER_HOME/.config/VSCodium-Isolated/User"
      mkdir -p "$SETTING_DIR"
      cp -f ${settingsFile} "$SETTING_DIR/settings.json"
      chown -R alice:users "$USER_HOME/.config/VSCodium-Isolated"
    '';
    deps = [];
  };
}




# { config, pkgs, ... }:

# let
#   unstable = import <unstable> {
#     config = config.nixpkgs.config;
#   };

#   # 1. Privacy & UI Settings (Marketplace enabled)
#   vscode-settings = {
#     "telemetry.telemetryLevel" = "off";
#     "update.mode" = "none";
#     "workbench.settings.enableNaturalLanguageSearch" = false;
#     "workbench.accounts.showProfiles" = false;
#     "extensions.autoCheckUpdates" = false;
#     "extensions.autoUpdate" = false;
#     "workbench.startupEditor" = "none";
#     "editor.links" = false;
#     "breadcrumbs.enabled" = false;
#     "ai.suggest.enabled" = false;
#     "github.copilot.enable" = { "*" = false; };
#   };

#   settingsFile = pkgs.writeText "vscodium-settings.json" (builtins.toJSON vscode-settings);

# in {
#   nixpkgs.config.packageOverrides = pkgs: {
#     vscode-private = (unstable.vscodium.override {
#       # This is the "Magic" part: it tells Codium to use the MS Marketplace
#       useOfficialExtensions = true;
#     }).overrideAttrs (oldAttrs: {
#       nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

#       # 2. Hard-strip any leftover Microsoft/GitHub account logic
#       postInstall = (oldAttrs.postInstall or "") + ''
#         find $out -name "microsoft-authentication" -type d -exec rm -rf {} +
#         find $out -name "github-authentication" -type d -exec rm -rf {} +
#         find $out -name "microsoft-account" -type d -exec rm -rf {} +
#       '';

#       postFixup = (oldAttrs.postFixup or "") + ''
#         wrapProgram $out/bin/codium \
#           --add-flags "--disable-telemetry" \
#           --add-flags "--disable-crash-reporter" \
#           --add-flags "--disable-userdata-auth" \
#           --add-flags "--user-data-dir ~/.config/VSCodium-Isolated"
#       '';
#     });
#   };

#   # Create an alias so you can still type 'code' in the terminal
#   environment.systemPackages = [
#     pkgs.vscode-private
#     (pkgs.writeShellScriptBin "code" "exec codium \"$@\"")
#   ];

#   system.activationScripts.vscode-settings = {
#     text = ''
#       USER_HOME="/home/alice"
#       SETTING_DIR="$USER_HOME/.config/VSCodium-Isolated/User"
#       mkdir -p "$SETTING_DIR"
#       cp -f ${settingsFile} "$SETTING_DIR/settings.json"
#       chown -R alice:users "$USER_HOME/.config/VSCodium-Isolated"
#     '';
#     deps = [];
#   };
# }
