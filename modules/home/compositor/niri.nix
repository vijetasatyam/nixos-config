#/home/alice/nixos-config/modules/home/compositor/niri.nix
{
  pkgs,
  theme,
  ...
}: let
  toRgba = hex: alpha: (builtins.substring 1 (builtins.stringLength hex - 1) hex) + alpha;

  fuzzelKeybinds = pkgs.writeShellScriptBin "fuzzel-keybinds" ''
    # Format: "Keybind | Description | Command"
    MENU="󰞷  Mod + Return       Launch Ghostty Terminal      ::: ghostty
󰍉  Mod + F            Application Launcher (Fuzzel) ::: fuzzel
󰅖  Mod + Q            Close Active Window          ::: niri msg action close-window
󰍉  Mod + D            Maximize Column              ::: niri msg action maximize-column
󰊓  Mod + Shift + D    Fullscreen Window            ::: niri msg action fullscreen-window
󰄄  Print              Snip Screenshot to Clipboard ::: grim -g \"\$(slurp)\" - | wl-copy
󰑓  Mod + Shift + R    Restart DMS Shell            ::: systemctl --user restart dms
󰗼  Mod + Shift + Q    Exit Niri Session            ::: niri msg action quit --skip-confirmation
󰕾  Volume Up          Increase Volume 5%           ::: wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
󰝟  Volume Down        Decrease Volume 5%           ::: wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
󰝟  Volume Mute        Toggle Mute Audio            ::: wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
󰃠  Brightness Up      Increase Display +5%         ::: brightnessctl set +5%
󰃟  Brightness Down    Decrease Display -5%         ::: brightnessctl set 5%-"

    CHOICE=$(echo "$MENU" | awk -F' ::: ' '{print $1}' | fuzzel --dmenu --prompt="  󰌌  Keybinds: " --lines=13 --width=50)

    if [ -n "$CHOICE" ]; then
      CMD=$(echo "$MENU" | grep -F "$CHOICE" | awk -F' ::: ' '{print $2}')
      if [ -n "$CMD" ]; then
        eval "$CMD"
      fi
    fi
  '';
in {
  home.packages = with pkgs; [
    fuzzel
    fuzzelKeybinds
    papirus-icon-theme
    swaybg
    grim
    slurp
    wl-clipboard
    cliphist
    nwg-look
    mission-center
    htop
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  xdg.configFile."gtk-4.0/gtk.css".text = ''
    /* Style Niri's Hotkey Dialog */
    window.dialog, dialog {
      background-color: ${theme.bg};
      color: ${theme.text};
      border: 2px solid ${theme.border};
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
    }

    list, row {
      background-color: transparent;
      color: ${theme.text};
      border-radius: 8px;
      padding: 4px 8px;
    }

    row:hover {
      background-color: ${theme.surface};
    }
  '';

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    layout {
        gaps 16
        center-focused-column "never"
        default-column-width { proportion 0.5; }

        focus-ring {
            width 3
            active-color "${theme.accent}"
            inactive-color "${theme.surface}"
        }
    }

    animations {
        horizontal-view-movement {
            spring damping-ratio=0.85 stiffness=800 epsilon=0.0001
        }
        workspace-switch {
            spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001
        }
        window-open {
            duration-ms 200
            curve "ease-out-quad"
        }
        window-close {
            duration-ms 180
            curve "ease-out-quad"
        }
    }

    // --- Autostart ---
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
    spawn-at-startup "awww-daemon"

    // --- Keybindings ---
    binds {
      // Interactive searchable hotkey menu
      Mod+Slash { spawn "fuzzel-keybinds"; }

      // System Controls & DMS
      Mod+Shift+R hotkey-overlay-title="<span color='${theme.warning}' font_weight='bold'>󰑓 Restart DMS Shell</span>" {
        spawn "systemctl" "--user" "restart" "dms";
      }

      // App Launchers & Terminal
      Mod+Return hotkey-overlay-title="<span color='${theme.accent}' font_weight='bold'>󰞷 Launch Terminal</span> (Ghostty)" {
        spawn "ghostty";
      }
      Mod+F hotkey-overlay-title="<span color='${theme.accent}' font_weight='bold'>󰍉 App Launcher</span> (Fuzzel)" {
        spawn "fuzzel";
      }
      Mod+Q hotkey-overlay-title="<span color='${theme.urgent}' font_weight='bold'>󰅖 Close Active Window</span>" {
        close-window;
      }

      // Window Layout & Maximization
      Mod+D hotkey-overlay-title="<span color='${theme.active}'>󰍉 Maximize Column</span>" {
        maximize-column;
      }
      Mod+Shift+D hotkey-overlay-title="<span color='${theme.active}'>󰊓 Fullscreen Window</span>" {
        fullscreen-window;
      }

      // Navigation & Column Movement
      Mod+Tab       hotkey-overlay-title=null { focus-column-right; }
      Mod+Shift+Tab hotkey-overlay-title=null { focus-column-left; }
      Mod+Left      hotkey-overlay-title="<span> Focus Left / Right</span>" { focus-column-left; }
      Mod+Right     hotkey-overlay-title=null { focus-column-right; }
      Mod+Up        hotkey-overlay-title=null { focus-window-up; }
      Mod+Down      hotkey-overlay-title=null { focus-window-down; }

      Mod+Shift+Left  hotkey-overlay-title="<span>󰪹 Move Column Left / Right</span>" { move-column-left; }
      Mod+Shift+Right hotkey-overlay-title=null { move-column-right; }
      Mod+Shift+Up    hotkey-overlay-title=null { move-window-up; }
      Mod+Shift+Down  hotkey-overlay-title=null { move-window-down; }

      // Workspaces (1 - 9)
      Mod+1 hotkey-overlay-title="<span color='${theme.text}'>󰲡 Focus Workspace 1-9</span>" { focus-workspace 1; }
      Mod+2 hotkey-overlay-title=null { focus-workspace 2; }
      Mod+3 hotkey-overlay-title=null { focus-workspace 3; }
      Mod+4 hotkey-overlay-title=null { focus-workspace 4; }
      Mod+5 hotkey-overlay-title=null { focus-workspace 5; }
      Mod+6 hotkey-overlay-title=null { focus-workspace 6; }
      Mod+7 hotkey-overlay-title=null { focus-workspace 7; }
      Mod+8 hotkey-overlay-title=null { focus-workspace 8; }
      Mod+9 hotkey-overlay-title=null { focus-workspace 9; }

      Mod+Shift+1 hotkey-overlay-title=null { move-column-to-workspace 1; }
      Mod+Shift+2 hotkey-overlay-title=null { move-column-to-workspace 2; }
      Mod+Shift+3 hotkey-overlay-title=null { move-column-to-workspace 3; }
      Mod+Shift+4 hotkey-overlay-title=null { move-column-to-workspace 4; }
      Mod+Shift+5 hotkey-overlay-title=null { move-column-to-workspace 5; }
      Mod+Shift+6 hotkey-overlay-title=null { move-column-to-workspace 6; }
      Mod+Shift+7 hotkey-overlay-title=null { move-column-to-workspace 7; }
      Mod+Shift+8 hotkey-overlay-title=null { move-column-to-workspace 8; }
      Mod+Shift+9 hotkey-overlay-title=null { move-column-to-workspace 9; }

      // Vertical Workspace Scrolling
      Mod+Page_Down hotkey-overlay-title=null { focus-workspace-down; }
      Mod+Page_Up   hotkey-overlay-title=null { focus-workspace-up; }
      Mod+Shift+Page_Down hotkey-overlay-title=null { move-column-to-workspace-down; }
      Mod+Shift+Page_Up   hotkey-overlay-title=null { move-column-to-workspace-up; }

      // Media & Audio
      XF86AudioRaiseVolume allow-when-locked=true hotkey-overlay-title=null { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      XF86AudioLowerVolume allow-when-locked=true hotkey-overlay-title=null { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      XF86AudioMute        allow-when-locked=true hotkey-overlay-title=null { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86MonBrightnessUp   allow-when-locked=true hotkey-overlay-title=null { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown allow-when-locked=true hotkey-overlay-title=null { spawn "brightnessctl" "set" "5%-"; }

      // Screenshots
      Print hotkey-overlay-title="<span color='${theme.success}'>󰄄 Snip to Clipboard</span>" {
        spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy";
      }

      // Exit
      Mod+Shift+Q hotkey-overlay-title="<span color='${theme.urgent}'>󰗼 Exit Niri Session</span>" {
        quit;
      }
    }
  '';

  # Theme and Style Fuzzel dynamically using Catppuccin / Material 3 Tokens
  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:weight=medium:size=11
    prompt="  󰍉  "
    terminal=ghostty
    layer=overlay
    match-mode=fzf
    show-actions=yes

    # Layout & Geometry
    lines=8
    width=38
    horizontal-pad=24
    vertical-pad=18
    inner-pad=12
    line-height=24

    # Application Icons
    icons-enabled=yes
    icon-theme=Papirus-Dark

    [colors]
    background=${toRgba theme.bg "f2"}
    text=${toRgba theme.text "ff"}
    prompt=${toRgba theme.accent "ff"}
    placeholder=${toRgba theme.surface "ff"}
    input=${toRgba theme.text "ff"}
    match=${toRgba theme.active "ff"}

    selection=${toRgba theme.surface "e6"}
    selection-text=${toRgba theme.accent "ff"}
    selection-match=${toRgba theme.urgent "ff"}

    border=${toRgba theme.border "ff"}
    counter=${toRgba theme.surface "ff"}

    [border]
    width=2
    radius=18
    selection-radius=12

    [key-bindings]
    cancel=Escape Control+c Control+g
    execute=Return KP_Enter
    prev=Up Control+p Control+k
    next=Down Control+n Control+j
  '';
}
