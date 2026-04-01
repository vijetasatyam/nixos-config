{ ... }: {
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      margin = "8 15 0 15";
      height = 36;

      modules-left = [ "custom/os_icon" "wlr/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "network" "pulseaudio" "battery" ];

      "custom/os_icon" = { format = " ❄️ "; };
      "clock" = { format = "{:%I:%M %p    %b %d}"; };
    };

    style = ''
      * {
        font-family = "JetBrainsMono Nerd Font";
        font-size = 14px;
        border-radius = 12px;
      }
      window#waybar {
        background-color = rgba(40, 42, 54, 0.85);
        color = #f8f8f2;
      }
      #workspaces button.active {
        background-color = #bd93f9;
        color = #282a36;
      }
      #workspaces, #clock, #network, #pulseaudio, #battery {
        padding: 0 12px;
        margin: 4px;
        background-color = rgba(68, 71, 90, 0.5);
      }
    '';
  };
}
