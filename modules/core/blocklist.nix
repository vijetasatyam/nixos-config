{
  # config,
  # pkgs,
  ...
}: let
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
  # Map 127.0.0.1 to all blocked domains in /etc/hosts
  networking.hosts."127.0.0.1" = blocked-domains;
}
