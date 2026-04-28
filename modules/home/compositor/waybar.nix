{
  #pkgs, ... }: {
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

    # The CSS Magic
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
        /* Completely transparent background so only the pills show */
        background: transparent;
        color: #f8f8f2;
        padding-top: 1px;
      }

      /* The "Pill" styling base */
      #workspaces, #window, #clock, #pulseaudio, #network, #battery, #tray {
        background-color: #282a36; /* Dracula bg */
        color: #f8f8f2;
        border-radius: 16px;
        padding: 4px 16px;
        margin-bottom: 0px;
      }

      /* Specific Module Colors */
      #workspaces {
        background-color: #282a36;
      }

      #workspaces button {
        color: #6272a4;
        padding: 0 4px;
        transition: all 0.2s ease-in-out;
      }

      #workspaces button.active {
        color: #ff79c6; /* Dracula Pink */
        text-shadow: 0px 0px 5px rgba(255, 121, 198, 0.5);
      }

      #workspaces button:hover {
        background: transparent;
        color: #bd93f9;
      }

      #clock { color: #8be9fd; }       /* Cyan */
      #pulseaudio { color: #50fa7b; }  /* Green */
      #network { color: #ffb86c; }     /* Orange */
      #battery { color: #f1fa8c; }     /* Yellow */
    '';
  };
}
