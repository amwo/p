{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
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
    ../pkgs/direnv
    ../pkgs/eslint
    ../pkgs/fzf
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
