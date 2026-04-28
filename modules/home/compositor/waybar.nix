{
  #pkgs,
  theme,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        # Detach the bar from the edges
        margin-top = 5;
        margin-left = 10;
        margin-right = 10;
        margin-bottom = 5;
        height = 40;
        spacing = 8;

        modules-left = ["niri/workspaces" "niri/window"];
        modules-center = ["clock"];
        modules-right = ["pulseaudio" "network" "battery" "tray"];

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            active = "";
            default = "";
          };
        };

        "niri/window" = {
          format = "{}";
          max-length = 40;
        };

        "clock" = {
          format = "  {:%I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "pulseaudio" = {
          format = "{icon}  {volume}%";
          format-muted = "󰝟  Muted";
          format-icons = ["󰕿" "󰖀" "󰕾"];
          on-click = "pavucontrol";
        };

        "network" = {
          format-wifi = "󰖩  {essid}";
          format-ethernet = "󰈀  {ipaddr}";
          format-disconnected = "󰖪  Offline";
        };

        "battery" = {
          format = "{icon}  {capacity}%";
          format-icons = ["" "" "" "" ""];
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "sans-serif";
        font-size: 14px;
        font-weight: 600;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: ${theme.text};
        padding-top: 1px;
      }

      #workspaces, #window, #clock, #pulseaudio, #network, #battery, #tray {
        background-color: ${theme.bg};
        color: ${theme.text};
        border-radius: 16px;
        padding: 4px 16px;
        margin-bottom: 0px;
      }

      #workspaces { background-color: ${theme.bg}; }
      #workspaces button {
        color: ${theme.surface};
        padding: 0 4px;
        transition: all 0.2s ease-in-out;
      }

      #workspaces button.active {
        color: ${theme.accent};
        text-shadow: 0px 0px 5px ${theme.accent};
      }

      #workspaces button:hover {
        background: transparent;
        color: ${theme.border};
      }

      #clock { color: ${theme.active}; }
      #pulseaudio { color: ${theme.success}; }
      #network { color: ${theme.warning}; }
      #battery { color: ${theme.urgent}; }
    '';
  };
}
