#/home/alice/nixos-config/modules/home/compositor/fuzzel.nix
{
  pkgs,
  theme,
  ...
}: let
  # Convert a '#RRGGBB' hex color to 'RRGGBBAA' required by Fuzzel
  toRgba = hex: alpha: (builtins.substring 1 (builtins.stringLength hex - 1) hex) + alpha;
in {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:style=Regular:size=11";
        prompt = "'  󰍉  '";
        placeholder = "'Search applications or keybinds...'";
        terminal = "${pkgs.ghostty}/bin/ghostty";
        layer = "overlay";
        match-mode = "fzf";
        show-actions = "yes";
        anchor = "center";

        # Geometry & Layout
        lines = 10;
        width = 44;
        horizontal-pad = 28;
        vertical-pad = 20;
        inner-pad = 12;
        line-height = 28;
        letter-spacing = 0;

        # Icons
        icons-enabled = "yes";
        icon-theme = "Papirus-Dark";
        image-size-ratio = "0.5";
      };

      colors = {
        # Background: Semi-translucent deep mocha surface
        background = "${toRgba theme.bg "f0"}";
        text = "${toRgba theme.text "ff"}";
        prompt = "${toRgba theme.accent "ff"}";
        placeholder = "${toRgba theme.surface "bb"}";
        input = "${toRgba theme.text "ff"}";
        match = "${toRgba theme.active "ff"}";

        # Selection bar: Accent background with dark contrast text
        selection = "${toRgba theme.accent "e6"}";
        selection-text = "${toRgba theme.bg "ff"}";
        selection-match = "${toRgba theme.urgent "ff"}";

        # Border & Accents
        border = "${toRgba theme.border "ff"}";
        counter = "${toRgba theme.text "88"}";
      };

      border = {
        width = 2;
        radius = 20;
        selection-radius = 12;
      };

      key-bindings = {
        cancel = "Escape Control+c Control+g";
        execute = "Return KP_Enter";
        execute-or-next = "Tab";
        prev = "Up Control+p Control+k";
        next = "Down Control+n Control+j";
        prev-page = "Page_Up Control+u";
        next-page = "Page_Down Control+d";
        delete-line = "Control+u";
        delete-prev-word = "Control+w Control+BackSpace";
      };
    };
  };
}
