{pkgs, ...}: {
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
        keyboard { xkb { layout "us"; } }
        touchpad { tap; natural-scroll; }
    }

    layout {
        gaps 16 // Generous gaps for the floating look
        center-focused-column "never"

        default-column-width { proportion 0.5; }

        // The Dracula "Rice" Focus Ring
        focus-ring {
            width 4
            active-color "#bd93f9"   // Dracula Purple
            inactive-color "#44475a" // Dracula Selection/Invisible
        }
    }

    // --- The Aesthetics Engine ---
    animations {
        // Snappy, bouncy spring animations
        workspace-switch {
            spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001
        }
        window-open {
            duration-ms 200
            curve "ease-out-quad"
        }
        window-close {
            duration-ms 200
            curve "ease-in-quad"
        }
    }

    // Apply rounded corners to all windows
    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    // Make utility windows float
    window-rule {
        match app-id="pavucontrol"
        match app-id="mission-center"
        open-floating true
    }

    // --- Autostart ---
    spawn-at-startup "waybar"
    spawn-at-startup "mako"
    // PRO TIP: Put a cool Dracula-themed wallpaper here!
    spawn-at-startup "swaybg" "-i" "/home/alice/Pictures/dracula-wallpaper.jpg" "-m" "fill"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"

    // --- Keybindings ---
    binds {
        Mod+Return { spawn "ghostty"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Q { close-window; }

        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }

        Mod+Shift+Q { quit; }
        Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
    }
  '';

  # Let's also rice your App Launcher (Fuzzel) to match!
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
    background=282a36ff
    text=f8f8f2ff
    match=8be9fdff
    selection=44475aff
    selection-text=bd93f9ff
    border=bd93f9ff

    [border]
    width=3
    radius=12
  '';
}
