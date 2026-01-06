{
  config,
  pkgs,
  ...
}:

let
  unstable = import <unstable> {
    config = config.nixpkgs.config;
  };

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
    }).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

      preFixup = (oldAttrs.preFixup or "") + ''
        gq_path="lib/vscode/resources/app/product.json"

        if [ -f "$out/$gq_path" ]; then
          product_json="$out/$gq_path"
        else
          product_json=$(find $out/lib -path "*/resources/app/product.json" | head -n 1)
        fi

        if [ -z "$product_json" ]; then
           echo "Error: product.json not found!"
           exit 1
        fi

        # Inject Marketplace URLs AND Microsoft Identity Spoofing
        ${pkgs.python3}/bin/python3 <<EOF
import json
with open('$product_json', 'r') as f:
    data = json.load(f)

# 1. Enable Official Marketplace
data['extensionsGallery'] = {
    'serviceUrl': 'https://marketplace.visualstudio.com/_apis/public/gallery',
    'cacheUrl': 'https://vscode.blob.core.windows.net/gallery/index',
    'itemUrl': 'https://marketplace.visualstudio.com/items'
}

# 2. Identity Spoofing for Remote-SSH Support
# This tricks the Microsoft extension into thinking this is the official binary.
data['quality'] = 'stable'
# Pulling the exact version string from the unstable vscode package
data['commit'] = '${unstable.vscode.version}'

with open('$product_json', 'w') as f:
    json.dump(data, f, indent=4)
EOF
      '';

      postInstall = (oldAttrs.postInstall or "") + ''
        find $out -name "microsoft-authentication" -type d -exec rm -rf {} +
        find $out -name "github-authentication" -type d -exec rm -rf {} +
        find $out -name "microsoft-account" -type d -exec rm -rf {} +
      '';

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
