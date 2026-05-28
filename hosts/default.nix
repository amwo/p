{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "github-copilot-cli"
    ];

  home = {
    username = "am";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/am" else "/home/am";
    stateVersion = "24.11";
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
    ../pkgs/gemini-cli
    ../pkgs/gh
    ../pkgs/git
    ../pkgs/htop
    ../pkgs/less
    ../pkgs/neovim
    ../pkgs/nodejs
    ../pkgs/nixfmt
    ../pkgs/prettier
    ../pkgs/rustfmt
    ../pkgs/tmux
    ../pkgs/zsh
  ];

  programs.home-manager.enable = true;
}
