{ config, pkgs, ... }:

let
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };

  # Settings for the Isolated VSCodium
  vscodium-settings = {
    "telemetry.telemetryLevel" = "off";
    "update.mode" = "none";
    "workbench.settings.enableNaturalLanguageSearch" = false;
    "workbench.accounts.showProfiles" = false;
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "workbench.startupEditor" = "none";
    "editor.links" = false;
    "breadcrumbs.enabled" = false;
    "ai.suggest.enabled" = false;
    "github.copilot.enable" = { "*" = false; };
  };

  settingsFile = pkgs.writeText "vscodium-settings.json" (builtins.toJSON vscodium-settings);

in {
  nixpkgs.config.packageOverrides = pkgs: {
    vscodium-isolated = (unstable.vscodium.override {
      # This version is base-telemetry free but patched for official marketplace
    }).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

      # Refined patch logic for product.json
      preFixup = (oldAttrs.preFixup or "") + ''
        # Standard path for VSCodium's product.json
        gq_path="lib/vscode/resources/app/product.json"

        if [ -f "$out/$gq_path" ]; then
          product_json="$out/$gq_path"
        else
          # Fallback to finding it specifically within the lib/vscode structure
          product_json=$(find $out/lib -path "*/resources/app/product.json" | head -n 1)
        fi

        if [ -z "$product_json" ]; then
           echo "Error: product.json not found!"
           exit 1
        fi

        # Inject Marketplace URLs using python
        ${pkgs.python3}/bin/python3 <<EOF
import json
with open('$product_json', 'r') as f:
    data = json.load(f)
data['extensionsGallery'] = {
    'serviceUrl': 'https://marketplace.visualstudio.com/_apis/public/gallery',
    'cacheUrl': 'https://vscode.blob.core.windows.net/gallery/index',
    'itemUrl': 'https://marketplace.visualstudio.com/items'
}
with open('$product_json', 'w') as f:
    json.dump(data, f, indent=4)
EOF
      '';

      # Physically remove the authentication and account sync extensions [cite: 112]
      postInstall = (oldAttrs.postInstall or "") + ''
        find $out -name "microsoft-authentication" -type d -exec rm -rf {} +
        find $out -name "github-authentication" -type d -exec rm -rf {} +
        find $out -name "microsoft-account" -type d -exec rm -rf {} +
      '';

      # Wrap binary with privacy flags and isolated directory [cite: 113]
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
    pkgs.vscodium-isolated
    (pkgs.writeShellScriptBin "vscodium" "exec ${pkgs.vscodium-isolated}/bin/codium \"$@\"")
    (pkgs.writeShellScriptBin "codium-private" "exec ${pkgs.vscodium-isolated}/bin/codium \"$@\"")
  ];

  system.activationScripts.vscodium-settings = {
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
