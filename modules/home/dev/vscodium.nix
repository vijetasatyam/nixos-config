{ config, pkgs, lib, pkgs-unstable, ... }:

let
  # 1. Hardened Settings (Preserved Exactly)
  vscodiumSettings = {
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

  # 2. Custom Package: Marketplace Injection + Identity Spoofing
  vscodiumIsolated = pkgs-unstable.vscodium.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];

    # The Logic: Inject Marketplace URLs & Spoof Identity
    preFixup = (oldAttrs.preFixup or "") + ''
      product_json=$(find $out/lib -path "*/resources/app/product.json" | head -n 1)
      if [ -z "$product_json" ]; then echo "Error: product.json missing"; exit 1; fi

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
# This tricks extensions into thinking this is the official VSCode binary
data['quality'] = 'stable'
# We pull the version string from the unstable VSCode package
data['commit'] = '${pkgs-unstable.vscode.version}'

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
in
{
  # 3. Modular Activation
  config = lib.mkIf config.modules.dev.tools.enable {

    home.packages = [
      vscodiumIsolated
      # Aliases to run it easily (Preserved from old config)
      (pkgs.writeShellScriptBin "vscodium" "exec ${vscodiumIsolated}/bin/codium \"$@\"")
      (pkgs.writeShellScriptBin "codium-private" "exec ${vscodiumIsolated}/bin/codium \"$@\"")
    ];

    # Write settings.json declaratively
    xdg.configFile."VSCodium-Isolated/User/settings.json" = {
      source = pkgs.writeText "vscodium-settings.json" (builtins.toJSON vscodiumSettings);
      force = true;
    };
  };
}
