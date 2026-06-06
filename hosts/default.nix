{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "antigravity-cli"
      "claude-code"
      "github-copilot-cli"
    ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  home = {
    username = "am";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/am" else "/home/am";
    stateVersion = "24.11";
    # User-writable npm global prefix (~/.local) and the iii engine binary live here.
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables.VIEWER_ALLOWED_HOSTS = "athena.tailbbaea.ts.net,athena.tailbbaea.ts.net:3113,100.74.242.44,100.74.242.44:3113";
  };

  imports = [
    ../modules/ai
    ../pkgs/clippy
    ../pkgs/claude-code
    ../pkgs/codex
    ../pkgs/copilot-cli
    ../pkgs/direnv
    ../pkgs/eslint
    ../pkgs/fzf
    ../pkgs/antigravity-cli
    ../pkgs/gh
    ../pkgs/git
    ../pkgs/htop
    ../pkgs/jq
    ../pkgs/less
    ../pkgs/neovim
    ../pkgs/nodejs
    ../pkgs/nixfmt
    ../pkgs/prettier
    ../pkgs/ripgrep
    ../pkgs/rustfmt
    ../pkgs/tmux
    ../pkgs/zsh
  ];

  programs.home-manager.enable = true;
}
