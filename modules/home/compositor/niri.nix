{
  pkgs,
  theme,
  ...
}: {
  home.packages = with pkgs; [
    fuzzel
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
            width 4
            active-color "${theme.accent}"   // Dynamic Theme Accent
            inactive-color "${theme.surface}" // Dynamic Theme Inactive
        }
    }

    animations {
        workspace-switch { spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001; }
        window-open {
            duration-ms 200
            curve "ease-out-quad"
        }
        window-close {
            duration-ms 200
            curve "ease-out-quad"
        }
    }

    window-rule { geometry-corner-radius 12; clip-to-geometry true; }
    window-rule { match app-id="pavucontrol"; match app-id="mission-center"; open-floating true; }

    // 5. Autostart SwayNC instead of Mako
    spawn-at-startup "quickshell"
    spawn-at-startup "swaync"
    spawn-at-startup "swaybg" "-i" "/home/alice/Pictures/catppuccin-wallpaper.jpg" "-m" "fill"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

    binds {
        Mod+Return { spawn "ghostty"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Q { close-window; }
        //  ... (Keep your other binds identical) ...
        Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
    }
  '';

  # Theme Fuzzel dynamically
  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=12
    prompt="> "
    terminal=ghostty
    lines=10
    width=40
    horizontal-pad=20
    vertical-pad=15
    inner-pad=10

    [colors]
    background=${builtins.substring 1 6 theme.bg}ff
    text=${builtins.substring 1 6 theme.text}ff
    match=${builtins.substring 1 6 theme.active}ff
    selection=${builtins.substring 1 6 theme.surface}ff
    selection-text=${builtins.substring 1 6 theme.accent}ff
    border=${builtins.substring 1 6 theme.accent}ff

    [border]
    width=3
    radius=12
  '';
}
