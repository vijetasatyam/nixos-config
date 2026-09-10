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

    // Rules for Caelestia surfaces and dialogs
    window-rule { geometry-corner-radius 16; clip-to-geometry true; }
    window-rule { match app-id=r#"^quickshell.*"#; open-floating true; }
    window-rule { match app-id="pavucontrol"; match app-id="mission-center"; open-floating true; }

    layer-rule {
        match namespace="^quickshell.*"
    }

    // --- Autostart ---
    spawn-at-startup "quickshell"
    spawn-at-startup "bash" "/home/alice/nixos-config/scripts/niri-caelestia-bridge.sh"
    spawn-at-startup "swaybg" "-i" "/home/alice/Pictures/catppuccin-wallpaper.jpg" "-m" "fill"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

    // --- Keybindings ---
    binds {
        Mod+Return { spawn "ghostty"; }
        Mod+D      { spawn "fuzzel"; }
        Mod+Q      { close-window; }

        // Caelestia Shell Drawers
        Mod+Space { spawn "quickshell" "ipc" "call" "launcher" "toggle"; }
        Mod+N     { spawn "quickshell" "ipc" "call" "controlCenter" "toggle"; }

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

        // Volume & Media Controls
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "+5%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }

        Mod+Shift+Q { quit; }
        Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
    }
  '';

  # Theme and Style Fuzzel dynamically using Catppuccin / Material 3 Tokens
  xdg.configFile."fuzzel/fuzzel.ini".text = let
    # Helper to convert "#RRGGBB" -> "RRGGBBAA"
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
    # Format: RRGGBBAA
    background=${toRgba theme.bg "f2"}
    text=${toRgba theme.text "ff"}
    prompt=${toRgba theme.accent "ff"}
    placeholder=${toRgba theme.surface "ff"}
    input=${toRgba theme.text "ff"}
    match=${toRgba theme.active "ff"}

    # Selected Item Styling (Floating Pill)
    selection=${toRgba theme.surface "e6"}
    selection-text=${toRgba theme.accent "ff"}
    selection-match=${toRgba theme.urgent "ff"}

    # Border & Counter
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
