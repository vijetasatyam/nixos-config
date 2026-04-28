{pkgs, ...}: {
  home.packages = with pkgs; [
    # Wayland Utilities
    fuzzel # App launcher
    mako # Notification daemon
    swaybg # Wallpaper utility
    grim # Screenshots
    slurp # Screen region selection

    # Clipboard
    wl-clipboard # Core clipboard tools
    cliphist # Clipboard history manager

    # Tweaker & Appearance
    nwg-look # GTK theme tweaker for Wayland

    # Performance Monitoring
    mission-center # Beautiful, Windows-like performance monitor
    htop
  ];

  # Niri writes its config in KDL. We write it declaratively via Home Manager.
  xdg.configFile."niri/config.kdl".text = ''
    // Input settings
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

    // Default Layout
    layout {
        gaps 12
        center-focused-column "never"
        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }
        default-column-width { proportion 0.5; }

        focus-ring {
            width 3
            active-color "#ffb86c"
            inactive-color "#44475a"
        }
    }

    // Startup Applications
    spawn-at-startup "waybar"
    spawn-at-startup "mako"
    // Change this path to your actual wallpaper!
    spawn-at-startup "swaybg" "-i" "/home/alice/Pictures/wallpaper.jpg" "-m" "fill"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

    // Keybindings (Mod = Super/Windows Key)
    binds {
        Mod+Return { spawn "ghostty"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Q { close-window; }

        // Navigation
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }

        // Window Movement
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }

        // System Actions
        Mod+Shift+Q { quit; }
        Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
    }
  '';
}
