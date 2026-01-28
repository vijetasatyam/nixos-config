{ config, pkgs, lib, pkgs-unstable, ... }:

let
  vscodeSettings = {
    "telemetry.telemetryLevel" = "off";
    "datatools.enableTelemetry" = false;
    "browser-preview.enableTelemetry" = false;
    "update.mode" = "none";
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "workbench.enableExperiments" = false;
    "workbench.settings.enableNaturalLanguageSearch" = false;
    "workbench.accounts.showProfiles" = false;
    "files.hotExit" = "off";
    "workbench.cloudChanges.autoSync" = false;
    "workbench.sync.enable" = false;
    "search.searchOnType" = false;
    "typescript.surveys.enabled" = false;
    "telemetry.enableCrashReporter" = false;
    "workbench.startupEditor" = "none";
    "workbench.tips.enabled" = false;
    "editor.links" = false;
    "breadcrumbs.enabled" = false;
    "ai.suggest.enabled" = false;
    "github.copilot.enable" = { "*" = false; };
    "github.copilot.editor.enableAutoCompletions" = false;
    "intellicode.features.python.deepLearning" = "disabled";
    "extensions.ignoreRecommendations" = true;
    "workbench.extension.commandDiscovery" = false;
    "extensions.showRecommendationsOnlyOnDemand" = true;
  };

  vscodePrivate = pkgs-unstable.vscode.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
    postInstall = (oldAttrs.postInstall or "") + ''
      find $out -name "microsoft-authentication" -type d -exec rm -rf {} +
      find $out -name "github-authentication" -type d -exec rm -rf {} +
      find $out -name "microsoft-account" -type d -exec rm -rf {} +
    '';
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
in
{
  config = lib.mkIf config.modules.dev.tools.enable {

    # FIX: Use lib.lowPrio to resolve file conflicts with VSCodium
    home.packages = [ (lib.lowPrio vscodePrivate) ];

    xdg.configFile."Code-Isolated/User/settings.json" = {
      source = pkgs.writeText "vscode-settings.json" (builtins.toJSON vscodeSettings);
      force = true;
    };

    home.sessionVariables = {
      DO_NOT_TRACK = "1";
      ELECTRON_DISABLE_SECURITY_WARNINGS = "true";
    };
  };
}
