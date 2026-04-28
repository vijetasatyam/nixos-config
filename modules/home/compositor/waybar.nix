{
  # pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;

        # Modules layout
        modules-left = [ "niri/workspaces" "niri/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "niri/workspaces" = {
          format = "{icon}";
        };

        "clock" = {
          format = "{:%a, %d. %b  %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-muted = "🔇 Muted";
          format-icons = ["🔈" "🔉" "🔊"];
        };

        "network" = {
          format-wifi = "  {essid}";
          format-ethernet = "🖧  {ipaddr}/{cidr}";
          format-disconnected = "Disconnected";
        };
      };
    };

    # Basic Dracula-inspired styling matching your existing theme choices
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 14px;
      }
      window#waybar {
        background-color: #282a36;
        color: #f8f8f2;
      }
      #workspaces button {
        padding: 0 10px;
        color: #6272a4;
        background: transparent;
      }
      #workspaces button.active {
        color: #ff79c6;
        font-weight: bold;
      }
      #clock, #pulseaudio, #network, #battery, #tray {
        padding: 0 12px;
      }
    '';
  };
}
