{
  config,
  pkgs,
  lib,
  pkgs-unstable,
  ...
}: {
  # Only enable if the master dev-tools switch is on
  config = lib.mkIf config.modules.dev.tools.enable {
    # 1. Neovim Package & Dependencies
    programs.neovim = {
      enable = true;
      package = pkgs-unstable.neovim-unwrapped; # Use Unstable for latest features

      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # We install external tools needed by plugins here
      extraPackages = with pkgs; [
        # Building Treesitter parsers requires a compiler
        gcc
        gnumake

        # Tools for Telescope / Grepping
        tree-sitter # tree-sitter-cli
        lazygit # lazygit integration
        fzf # fzf (v0.25+)
        ripgrep # live grep
        fd # find files
        curl # completion engine download

        # Language Servers (Optional - you can also use Mason inside Neovim)
        pkgs-unstable.nixd
        pkgs-unstable.lua-language-server
        pkgs-unstable.nil

        # Clipboard support
        wl-clipboard # Wayland
        # xclip      # X11 (Uncomment if needed)
      ];
    };

    # # 2. Bootstrap Lazy.nvim
    # # This Lua block checks if lazy is installed, clones it if not, and loads your config.
    # xdg.configFile."nvim/init.lua".text = ''
    #   -- Bootstrap lazy.nvim
    #   local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    #   if not vim.loop.fs_stat(lazypath) then
    #     vim.fn.system({
    #       "git",
    #       "clone",
    #       "--filter=blob:none",
    #       "https://github.com/folke/lazy.nvim.git",
    #       "--branch=stable", -- latest stable release
    #       lazypath,
    #     })
    #   end
    #   vim.opt.rtp:prepend(lazypath)

    #   -- Basic Settings before loading plugins
    #   vim.g.mapleader = " " -- Make sure to set this before lazy setup
    #   vim.g.maplocalleader = " "

    #   vim.opt.number = true
    #   vim.opt.relativenumber = true
    #   vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard

    #   -- Setup Lazy and load plugins
    #   require("lazy").setup({

    #     -- Example 1: Theme
    #     {
    #       "dracula/vim",
    #       name = "dracula",
    #       config = function()
    #         vim.cmd("colorscheme dracula")
    #       end
    #     },

    #     -- Example 2: Treesitter (Syntax Highlighting)
    #     {
    #       "nvim-treesitter/nvim-treesitter",
    #       build = ":TSUpdate",
    #       config = function()
    #         require("nvim-treesitter.configs").setup({
    #           ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "nix" },
    #           auto_install = false, -- rely on Nix for compilers, but lazy for downloading parsers
    #           highlight = { enable = true },
    #         })
    #       end
    #     },

    #     -- Example 3: Telescope (Fuzzy Finder)
    #     {
    #       "nvim-telescope/telescope.nvim",
    #       tag = "0.1.5",
    #       dependencies = { "nvim-lua/plenary.nvim" },
    #       keys = {
    #         { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    #         { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grepp" },
    #       }
    #     },

    #     -- Example 4: LSP Support
    #     {
    #       "neovim/nvim-lspconfig",
    #       config = function()
    #         local lspconfig = require("lspconfig")
    #         -- Nixd is installed via Home Manager (extraPackages above)
    #         lspconfig.nixd.setup({})
    #       end
    #     }

    #   })
    # '';
  };
}
