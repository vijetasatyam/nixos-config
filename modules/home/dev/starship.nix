{ lib, ... }:
{
  programs.starship = {
    enable = true;

    # Auto-integrate with Zsh
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      # The layout of the prompt
      format = lib.concatStrings [
        "$os"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$nodejs"
        "$python"
        "$line_break"
        "$character"
      ];

      # --- Modules Configuration ---

      os = {
        disabled = false;
        format = "[$symbol]($style) ";
        symbols = {
          NixOS = "❄️";
        };
      };

      directory = {
        style = "bold blue";
        read_only = " 🔒";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = "🌱 ";
        style = "bold purple";
      };

      git_status = {
        style = "bold red";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };

      # Crucial for NixOS: Tells you when you are in a dev shell
      nix_shell = {
        disabled = false;
        impure_msg = "[impure](bold red)";
        pure_msg = "[pure](bold green)";
        format = "via [☃️ $state( \($name\))](bold blue) ";
      };

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };

      cmd_duration = {
        min_time = 2000; # Only show if command took more than 2 seconds
        format = "took [$duration]($style) ";
      };
    };
  };
}
