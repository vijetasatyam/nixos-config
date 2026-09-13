#/home/alice/nixos-config/modules/home/compositor/niri.nix
{
  pkgs,
  theme,
  ...
}: {
  home.packages = with pkgs; [
    fuzzel
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
    //spawn-at-startup "swaybg" "-i" "/home/alice/Pictures/catppuccin-wallpaper.png" "-m" "fill"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
    // --- Autostart awww daemon ---
        spawn-at-startup "awww-daemon"
        spawn-at-startup "awww" "img" "/home/alice/Downloads/walls-main/animated/city.gif"

    // --- Keybindings ---
    binds {
      // Quick service restart keybinding
      Mod+Shift+R { spawn "systemctl" "--user" "restart" "dms"; }

      Mod+Return { spawn "ghostty"; }
      Mod+D      { spawn "fuzzel"; }
      Mod+Q      { close-window; }

      // Horizontal Column & Window Switching
      Mod+Tab       { focus-column-right; }
      Mod+Shift+Tab { focus-column-left; }
      Mod+Left      { focus-column-left; }
      Mod+Right     { focus-column-right; }
      Mod+Up        { focus-window-up; }
      Mod+Down      { focus-window-down; }

      // Moving Columns & Windows
      Mod+Shift+Left  { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up    { move-window-up; }
      Mod+Shift+Down  { move-window-down; }

      // Workspaces (1 - 9)
      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }

      Mod+Shift+1 { move-column-to-workspace 1; }
      Mod+Shift+2 { move-column-to-workspace 2; }
      Mod+Shift+3 { move-column-to-workspace 3; }
      Mod+Shift+4 { move-column-to-workspace 4; }
      Mod+Shift+5 { move-column-to-workspace 5; }
      Mod+Shift+6 { move-column-to-workspace 6; }
      Mod+Shift+7 { move-column-to-workspace 7; }
      Mod+Shift+8 { move-column-to-workspace 8; }
      Mod+Shift+9 { move-column-to-workspace 9; }

      // Vertical Workspace Step & Dynamic Creation
      Mod+Page_Down { focus-workspace-down; }
      Mod+Page_Up   { focus-workspace-up; }
      Mod+Shift+Page_Down { move-column-to-workspace-down; }
      Mod+Shift+Page_Up   { move-column-to-workspace-up; }

      // Volume & Media Controls
      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }

      Mod+Shift+Q { quit; }
      Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }

      // Instead of fullscreen-window, maximize width & height within the viewport
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
    }
  '';

  # Theme and Style Fuzzel dynamically using Catppuccin / Material 3 Tokens
  xdg.configFile."fuzzel/fuzzel.ini".text = let
    toRgba = hex: alpha: (builtins.substring 1 (builtins.stringLength hex - 1) hex) + alpha;
  in ''
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
